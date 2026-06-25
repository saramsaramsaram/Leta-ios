import SwiftUI
import Combine

struct ChatRoomResponse: Decodable, Identifiable {
    let id: Int
    let characterId: Int
    let characterName: String
    let characterImageUrl: String?
    let personaId: Int
    let personaName: String?
    let lastMessage: String?
    let lastChatTime: String?
}

class ChatRoomsViewModel: ObservableObject {
    @Published var rooms: [ChatRoomResponse] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil

    func fetchRooms() {
        guard let request = NetworkManager.shared.createRequest(
            urlPath: "/api/chat/rooms",
            method: "GET",
            requireAuth: true
        ) else { return }

        isLoading = true
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            defer { DispatchQueue.main.async { self.isLoading = false } }

            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 401 {
                DispatchQueue.main.async { self.errorMessage = "로그인이 만료되었습니다." }
                NotificationCenter.default.post(name: .authTokenDidExpire, object: nil)
                return
            }

            guard let data = data, error == nil else {
                DispatchQueue.main.async { self.errorMessage = "서버 연결에 실패했습니다." }
                return
            }

            do {
                let decoded = try JSONDecoder().decode([ChatRoomResponse].self, from: data)
                DispatchQueue.main.async { self.rooms = decoded }
            } catch {
                DispatchQueue.main.async { self.errorMessage = "데이터를 불러오지 못했습니다." }
                print("⚠️ ChatRooms 디코딩 에러: \(error)")
            }
        }.resume()
    }

    func deleteRoom(roomId: Int, completion: @escaping (Bool) -> Void) {
        guard let request = NetworkManager.shared.createRequest(
            urlPath: "/api/chat/room/\(roomId)",
            method: "DELETE",
            requireAuth: true
        ) else {
            completion(false)
            return
        }

        URLSession.shared.dataTask(with: request) { [weak self] _, response, error in
            guard let self = self else { return }

            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 401 {
                NotificationCenter.default.post(name: .authTokenDidExpire, object: nil)
                DispatchQueue.main.async { completion(false) }
                return
            }

            let success = error == nil
            DispatchQueue.main.async {
                if success {
                    self.rooms.removeAll { $0.id == roomId }
                }
                completion(success)
            }
        }.resume()
    }
}


struct ChatRoomsView: View {
    @StateObject private var viewModel = ChatRoomsViewModel()
    @State private var roomToDelete: ChatRoomResponse? = nil
    @State private var showDeleteAlert: Bool = false

    var body: some View {
        NavigationView {
            ZStack {
                Color(red: 0.03, green: 0.03, blue: 0.05).ignoresSafeArea()

                if viewModel.isLoading {
                    ProgressView()
                        .tint(.white)
                } else if viewModel.rooms.isEmpty {
                    EmptyRoomsView()
                } else {
                    roomList
                }
            }
            .navigationBarHidden(true)
            .overlay(alignment: .top) { navBar }
        }
        .onAppear { viewModel.fetchRooms() }
        .alert("대화방 삭제", isPresented: $showDeleteAlert, presenting: roomToDelete) { room in
            Button("삭제", role: .destructive) {
                viewModel.deleteRoom(roomId: room.id) { _ in }
            }
            Button("취소", role: .cancel) {}
        } message: { room in
            Text("\(room.characterName)과의 대화를 삭제할까요?\n이 작업은 되돌릴 수 없습니다.")
        }
    }


    private var navBar: some View {
        HStack {
            Text("대화")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
            Spacer()
            Button {
                viewModel.fetchRooms()
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 17))
                    .foregroundColor(.white)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 10)
        .background(Color(red: 0.03, green: 0.03, blue: 0.05))
    }

    private var roomList: some View {
        List {
            ForEach(viewModel.rooms) { room in
                NavigationLink(destination: chatDestination(for: room)) {
                    ChatRoomCell(room: room)
                }
                .listRowBackground(Color(red: 0.05, green: 0.05, blue: 0.08))
                .listRowSeparatorTint(Color.white.opacity(0.06))
                .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        roomToDelete = room
                        showDeleteAlert = true
                    } label: {
                        Label("삭제", systemImage: "trash")
                    }
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .padding(.top, 56)
    }

    @ViewBuilder
    private func chatDestination(for room: ChatRoomResponse) -> some View {
        // character 정보를 최소 구성으로 넘겨서 ChatRoomView 재활용
        let character = LetaCharacterResponse(
            id: room.characterId,
            name: room.characterName,
            characterType: "PERSON",
            title: "",
            intro: "",
            profileImageUrl: room.characterImageUrl,
            bannerImageUrl: nil,
            tags: [],
            views: nil,
            hexColor: nil,
            prologue: nil,
            creatorName: nil,
            creatorHandle: nil,
            creatorComment: nil,
            subCharacters: nil,
            lorebooks: nil
        )
        ChatRoomView(character: character, existingRoomId: room.id, preselectedPersonaId: room.personaId)
    }
}

struct ChatRoomCell: View {
    let room: ChatRoomResponse

    var body: some View {
        HStack(spacing: 14) {
            Group {
                if let urlStr = room.characterImageUrl, let url = URL(string: urlStr) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let img):
                            img.resizable().scaledToFill()
                        default:
                            avatarPlaceholder
                        }
                    }
                } else {
                    avatarPlaceholder
                }
            }
            .frame(width: 52, height: 52)
            .cornerRadius(26)
            .clipped()

            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text(room.characterName)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                    Spacer()
                    if let timeStr = room.lastChatTime {
                        Text(formatTime(timeStr))
                            .font(.system(size: 11))
                            .foregroundColor(.gray)
                    }
                }

                HStack(spacing: 6) {
                    if let persona = room.personaName, !persona.isEmpty {
                        Text(persona)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(Color(hex: "#A78BFA"))
                            .padding(.horizontal, 7)
                            .padding(.vertical, 2)
                            .background(Color(hex: "#7C3AED").opacity(0.18))
                            .cornerRadius(8)
                    }
                    Text(room.lastMessage ?? "대화를 시작해보세요")
                        .font(.system(size: 13))
                        .foregroundColor(.gray)
                        .lineLimit(1)
                }
            }
        }
        .padding(.vertical, 12)
    }

    private var avatarPlaceholder: some View {
        ZStack {
            Color(hex: "#2D2A4A")
            Text(String(room.characterName.prefix(1)))
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white.opacity(0.7))
        }
    }

    private func formatTime(_ isoString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: isoString) {
            return relativeString(from: date)
        }
        formatter.formatOptions = [.withInternetDateTime]
        if let date = formatter.date(from: isoString) {
            return relativeString(from: date)
        }
        return ""
    }

    private func relativeString(from date: Date) -> String {
        let diff = Date().timeIntervalSince(date)
        if diff < 60 { return "방금" }
        if diff < 3600 { return "\(Int(diff / 60))분 전" }
        if diff < 86400 { return "\(Int(diff / 3600))시간 전" }
        let days = Int(diff / 86400)
        if days < 7 { return "\(days)일 전" }
        let cal = Calendar.current
        let comps = cal.dateComponents([.year, .month, .day], from: date)
        return "\(comps.month ?? 0)/\(comps.day ?? 0)"
    }
}

struct EmptyRoomsView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 48))
                .foregroundColor(.gray.opacity(0.4))
            Text("아직 대화가 없어요")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
            Text("홈에서 캐릭터를 선택해 대화를 시작해보세요")
                .font(.system(size: 14))
                .foregroundColor(.gray)
        }
    }
}
