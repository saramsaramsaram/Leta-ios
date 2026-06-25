import SwiftUI

struct ChatRoomView: View {
    let character: LetaCharacterResponse
    @State private var textMessage: String = ""
    @StateObject private var viewModel: ChatViewModel
    @State private var showPersonaSettings: Bool = false
    @Environment(\.dismiss) private var dismiss
    
    init(character: LetaCharacterResponse, existingRoomId: Int? = nil, preselectedPersonaId: Int? = nil) {
        self.character = character
        self._viewModel = StateObject(wrappedValue: ChatViewModel(
            character: character,
            existingRoomId: existingRoomId,
            preselectedPersonaId: preselectedPersonaId
        ))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                VStack(spacing: 2) {
                    Text(character.name)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                    Text(viewModel.isResponding ? "기억을 더듬으며 입력 중..." : "온라인")
                        .font(.system(size: 11))
                        .foregroundColor(viewModel.isResponding ? Color(hex: "#A78BFA") : .green)
                }
                
                Spacer()
                
                Button(action: { showPersonaSettings = true }) {
                    Image(systemName: "person.text.rectangle")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(Color(red: 0.05, green: 0.05, blue: 0.08))
            
            ScrollViewReader { proxy in
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.messages) { rawMessage in
                            ForEach(rawMessage.parsedDisplayMessages) { displayItem in
                                MessageBubbleCell(
                                    item: displayItem,
                                    mainCharacterName: character.name,
                                    fallbackHex: character.hexColor ?? "#7C3AED"
                                )
                            }
                        }
                    }
                    .padding(.vertical, 16)
                }
                .background(Color(red: 0.03, green: 0.03, blue: 0.05))
                .onChange(of: viewModel.messages.count) { _ in
                    if let lastId = viewModel.messages.last?.parsedDisplayMessages.last?.id {
                        withAnimation { proxy.scrollTo(lastId, anchor: .bottom) }
                    }
                }
            }
            
            HStack(spacing: 12) {
                TextField("대화를 이어 나가세요...", text: $textMessage)
                    .padding(.horizontal, 16)
                    .frame(height: 44)
                    .background(Color(red: 0.12, green: 0.12, blue: 0.16))
                    .foregroundColor(.white)
                    .cornerRadius(22)
                
                Button(action: {
                    viewModel.sendMessage(content: textMessage)
                    textMessage = ""
                }) {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(LinearGradient(
                            colors: [Color(hex: "#7C3AED"), Color(hex: "#4F46E5")],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        ))
                        .cornerRadius(22)
                }
                .disabled(!canSend)
                .opacity(canSend ? 1.0 : 0.4)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(red: 0.05, green: 0.05, blue: 0.08))
        }
        .preferredColorScheme(.dark)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .sheet(isPresented: $showPersonaSettings) {
            PersonaSelectionView(viewModel: viewModel)
        }
        .alert(
            "알림",
            isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )
        ) {
            Button("확인", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    private var canSend: Bool {
        !viewModel.isResponding &&
        viewModel.selectedPersona?.id != nil &&
        !textMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

struct MessageBubbleCell: View {
    let item: DisplayMessage
    let mainCharacterName: String
    let fallbackHex: String
    
    var body: some View {
        Group {
            if item.isNarrative {
                Text(item.content)
                    .font(.system(size: 14, weight: .medium))
                    .italic()
                    .foregroundColor(.gray.opacity(0.85))
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 8)
                    
            } else if item.senderName == "USER" {
                HStack {
                    Spacer()
                    Text(item.content)
                        .font(.system(size: 15))
                        .padding(12)
                        .background(Color(hex: "#4F46E5"))
                        .foregroundColor(.white)
                        .cornerRadius(16, corners: [.topLeft, .bottomLeft, .bottomRight])
                }
                .padding(.trailing, 16)
                .padding(.leading, 64)
                
            } else if item.senderName == mainCharacterName {
                HStack(alignment: .top, spacing: 10) {
                    Circle()
                        .fill(Color(hex: fallbackHex))
                        .frame(width: 36, height: 36)
                        .overlay(Text(String(mainCharacterName.prefix(1))).foregroundColor(.white).font(.system(size: 13, weight: .bold)))
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.senderName)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.gray)
                        Text(item.content)
                            .font(.system(size: 15))
                            .padding(12)
                            .background(Color(red: 0.12, green: 0.12, blue: 0.16))
                            .foregroundColor(.white)
                            .cornerRadius(16, corners: [.topRight, .bottomLeft, .bottomRight])
                    }
                    Spacer()
                }
                .padding(.leading, 16)
                .padding(.trailing, 64)
                
            } else {
                HStack(alignment: .top, spacing: 10) {
                    Circle()
                        .fill(LinearGradient(colors: [Color(hex: "#7C3AED"), Color(hex: "#EC4899")], startPoint: .top, endPoint: .bottom))
                        .frame(width: 36, height: 36)
                        .overlay(Text(String(item.senderName.prefix(1))).foregroundColor(.white).font(.system(size: 13, weight: .bold)))
                    
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 4) {
                            Text(item.senderName)
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(Color(hex: "#F472B6"))
                            Text("[조연]")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.gray.opacity(0.6))
                        }
                        
                        Text(item.content)
                            .font(.system(size: 15))
                            .padding(12)
                            .background(Color(hex: "#311042").opacity(0.4))
                            .foregroundColor(Color(hex: "#E9D5FF"))
                            .cornerRadius(16, corners: [.topRight, .bottomLeft, .bottomRight])
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color(hex: "#7C3AED").opacity(0.25), lineWidth: 1)
                            )
                    }
                    Spacer()
                }
                .padding(.leading, 16)
                .padding(.trailing, 64)
            }
        }
    }
}

struct CornerRadiusShape: Shape {
    var radius: CGFloat
    var corners: UIRectCorner
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(CornerRadiusShape(radius: radius, corners: corners))
    }
}

struct PersonaSelectionView: View {
    @ObservedObject var viewModel: ChatViewModel
    @Environment(\.dismiss) var dismiss
    @State private var personaName: String = ""
    @State private var personaDescription: String = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(red: 0.03, green: 0.03, blue: 0.05)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    VStack(alignment: .leading, spacing: 12) {
                        TextField("페르소나 이름", text: $personaName)
                            .textInputAutocapitalization(.never)
                            .padding(.horizontal, 14)
                            .frame(height: 44)
                            .background(Color(red: 0.12, green: 0.12, blue: 0.16))
                            .foregroundColor(.white)
                            .cornerRadius(12)

                        TextField("설명", text: $personaDescription)
                            .textInputAutocapitalization(.never)
                            .padding(.horizontal, 14)
                            .frame(height: 44)
                            .background(Color(red: 0.12, green: 0.12, blue: 0.16))
                            .foregroundColor(.white)
                            .cornerRadius(12)

                        Button {
                            viewModel.isCreatingPersona(name: personaName, description: personaDescription)
                            personaName = ""
                            personaDescription = ""
                        } label: {
                            HStack(spacing: 8) {
                                if viewModel.isCreatingPersona {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Image(systemName: "plus.circle.fill")
                                }
                                Text("페르소나 만들기")
                                    .font(.system(size: 15, weight: .bold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 46)
                            .background(Color(hex: "#7C3AED"))
                            .cornerRadius(12)
                        }
                        .disabled(viewModel.isCreatingPersona)
                    }
                    .padding(16)

                    if viewModel.isPersonaLoading {
                        Spacer()
                        ProgressView()
                            .tint(.white)
                        Spacer()
                    } else if viewModel.personaList.isEmpty {
                        Spacer()
                        VStack(spacing: 12) {
                            Image(systemName: "person.crop.circle.badge.plus")
                                .font(.system(size: 34))
                                .foregroundColor(.gray)
                            Text("불러온 페르소나가 없습니다.")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.white)
                            Button("다시 불러오기") {
                                viewModel.fetchServerPersonas()
                            }
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(Color(hex: "#A78BFA"))
                        }
                        Spacer()
                    } else {
                        List(viewModel.personaList) { persona in
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(persona.name)
                                        .font(.headline)
                                        .foregroundColor(.white)
                                    Text(persona.description ?? "설명 없음")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                                Spacer()
                                if viewModel.selectedPersona?.id == persona.id {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(Color(hex: "#7C3AED"))
                                }
                            }
                            .listRowBackground(Color(red: 0.05, green: 0.05, blue: 0.08))
                            .contentShape(Rectangle())
                            .onTapGesture {
                                viewModel.selectedPersona = persona
                                dismiss()
                            }
                        }
                        .scrollContentBackground(.hidden)
                    }
                }
            }
            .navigationTitle("채팅 페르소나 선택")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("닫기") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewModel.fetchServerPersonas()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(.white)
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}
