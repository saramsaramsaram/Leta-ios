import Foundation
import Combine

class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var isResponding: Bool = false
    @Published var errorMessage: String?
    @Published var isPersonaLoading: Bool = false
    @Published var isCreatingPersona: Bool = false

    @Published var personaList: [ServerPersona] = []
    @Published var selectedPersona: ServerPersona?

    let character: LetaCharacterResponse
    private var currentRoomId: Int? = nil
    private var task: Task<Void, Never>? = nil

    private let userPersonasPath = "/api/users/me/personas"
    private let chatRoomPath = "/api/chat/room"

    private struct ChatRoomRequest: Encodable {
        let characterId: Int
        let personaId: Int
    }

    private struct ChatRoomResponse: Decodable {
        let id: Int
    }

    private struct ChatSendRequest: Encodable {
        let content: String
    }

    private func handleUnauthorized(context: String, statusCode: Int) {
        print("❌ [\(context)] 인증 실패 HTTP \(statusCode).")
        _ = KeychainManager.shared.delete(account: "accessToken")
        DispatchQueue.main.async { self.errorMessage = "로그인이 만료되었습니다. 다시 로그인해 주세요." }
        NotificationCenter.default.post(name: .authTokenDidExpire, object: nil)
    }

    init(character: LetaCharacterResponse, existingRoomId: Int? = nil, preselectedPersonaId: Int? = nil) {
        self.character = character
        self.currentRoomId = existingRoomId

        if let roomId = existingRoomId {
            fetchServerPersonas(preselect: preselectedPersonaId)
            fetchChatHistory(roomId: roomId)
        } else {
            loadInitialPrologue()
            fetchServerPersonas(preselect: nil)
        }
    }

    func loadInitialPrologue() {
        if let prologue = character.prologue {
            self.messages = prologue.map { line in
                ChatMessage(speaker: line.speaker == "USER" ? "USER" : "BOT_STREAM", message: line.message, timestamp: Date())
            }
        }
    }

    func fetchServerPersonas(preselect personaId: Int? = nil) {
        guard let request = NetworkManager.shared.createRequest(urlPath: userPersonasPath, method: "GET", requireAuth: true) else { return }

        isPersonaLoading = true
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            defer { DispatchQueue.main.async { self.isPersonaLoading = false } }

            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 401 {
                self.handleUnauthorized(context: "페르소나 조회", statusCode: 401)
                return
            }

            guard let data = data, error == nil else { return }

            do {
                let personas = try JSONDecoder().decode([ServerPersona].self, from: data)
                DispatchQueue.main.async {
                    self.personaList = personas
                    if let targetId = personaId,
                       let matched = personas.first(where: { $0.id == targetId }) {
                        self.selectedPersona = matched
                    } else if self.selectedPersona == nil {
                        self.selectedPersona = personas.first
                    }
                }
            } catch {
                print("⚠️ 페르소나 디코딩 에러: \(error)")
            }
        }.resume()
    }

    func fetchChatHistory(roomId: Int) {
        guard let request = NetworkManager.shared.createRequest(
            urlPath: "/api/chat/room/\(roomId)/history",
            method: "GET",
            requireAuth: true
        ) else { return }

        struct HistoryMessage: Decodable {
            let role: String
            let content: String
        }

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }

            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 401 {
                self.handleUnauthorized(context: "히스토리 조회", statusCode: 401)
                return
            }

            guard let data = data, error == nil else { return }

            do {
                let history = try JSONDecoder().decode([HistoryMessage].self, from: data)
                let converted: [ChatMessage] = history.compactMap { msg in
                    switch msg.role {
                    case "user":
                        if msg.content.hasPrefix("[") { return nil }
                        return ChatMessage(speaker: "USER", message: msg.content, timestamp: Date())

                    case "assistant":
                        if msg.content.hasPrefix("[") {
                            let converted = Self.prologueToAtFormat(msg.content)
                            return ChatMessage(speaker: "BOT_STREAM", message: converted, timestamp: Date())
                        }
                        return ChatMessage(speaker: "BOT_STREAM", message: msg.content, timestamp: Date())

                    default:
                        return nil
                    }
                }
                DispatchQueue.main.async { self.messages = converted }
            } catch {
                print("⚠️ 히스토리 디코딩 에러: \(error)")
            }
        }.resume()
    }

    private static func prologueToAtFormat(_ content: String) -> String {
        guard content.hasPrefix("["),
              let closeBracket = content.firstIndex(of: "]") else {
            return content
        }
        let speaker = String(content[content.index(after: content.startIndex)..<closeBracket])
        let message = String(content[content.index(after: closeBracket)...]).trimmingCharacters(in: .whitespaces)
        let atSpeaker = (speaker == "시스템" || speaker == "나레이션") ? "지문" : speaker
        return "@\(atSpeaker): \"\(message)\""
    }
    
    private var typewriterTimer: Timer?
    private var typewriterFullText: String = ""
    private var typewriterIndex: Int = 0
    private var typewriterMsgIndex: Int = 0

    private func startTypewriter(fullText: String, at msgIndex: Int) {
        typewriterTimer?.invalidate()
        typewriterFullText = fullText
        typewriterIndex = 0
        typewriterMsgIndex = msgIndex

        typewriterTimer = Timer.scheduledTimer(withTimeInterval: 0, repeats: true) { [weak self] timer in
            guard let self = self else { timer.invalidate(); return }

            let chars = Array(self.typewriterFullText)
            guard self.typewriterIndex < chars.count else {
                timer.invalidate()
                DispatchQueue.main.async { self.isResponding = false }
                return
            }

            let displayed = String(chars[0...self.typewriterIndex])
            self.typewriterIndex += 1

            DispatchQueue.main.async {
                self.messages[self.typewriterMsgIndex] = ChatMessage(
                    id: self.messages[self.typewriterMsgIndex].id,
                    speaker: "BOT_STREAM",
                    message: displayed,
                    timestamp: self.messages[self.typewriterMsgIndex].timestamp
                )
            }
        }
    }

    func sendMessage(content: String) {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let userMsg = ChatMessage(speaker: "USER", message: trimmed, timestamp: Date())
        self.messages.append(userMsg)

        let botMsgIndex = self.messages.count
        let emptyBotMsg = ChatMessage(speaker: "BOT_STREAM", message: "", timestamp: Date())
        self.messages.append(emptyBotMsg)

        self.isResponding = true

        task = Task {
            do {
                guard let personaId = selectedPersona?.id else {
                    await MainActor.run { self.isResponding = false }
                    return
                }

                let roomId: Int
                if let existing = currentRoomId {
                    roomId = existing
                } else {
                    let roomReq = ChatRoomRequest(characterId: character.id, personaId: personaId)
                    guard let roomBody = try? JSONEncoder().encode(roomReq),
                          let roomRequest = NetworkManager.shared.createRequest(urlPath: chatRoomPath, method: "POST", body: roomBody, requireAuth: true) else {
                        await MainActor.run { self.isResponding = false }
                        return
                    }

                    let (roomData, roomResponse) = try await URLSession.shared.data(for: roomRequest)
                    if let httpResponse = roomResponse as? HTTPURLResponse, httpResponse.statusCode == 401 {
                        self.handleUnauthorized(context: "채팅방 연동", statusCode: 401)
                        return
                    }

                    let roomRes = try JSONDecoder().decode(ChatRoomResponse.self, from: roomData)
                    roomId = roomRes.id
                    await MainActor.run { self.currentRoomId = roomId }
                }

                let sendReq = ChatSendRequest(content: trimmed)
                guard let sendBody = try? JSONEncoder().encode(sendReq),
                      let sendRequest = NetworkManager.shared.createRequest(
                        urlPath: "/api/chat/room/\(roomId)/send",
                        method: "POST",
                        body: sendBody,
                        requireAuth: true
                      ) else {
                    await MainActor.run { self.isResponding = false }
                    return
                }

                let (data, response) = try await URLSession.shared.data(for: sendRequest)

                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 401 {
                    self.handleUnauthorized(context: "채팅 전송", statusCode: 401)
                    return
                }

                struct ChatResponse: Decodable { let content: String }
                let chatResponse = try JSONDecoder().decode(ChatResponse.self, from: data)
                let fullText = chatResponse.content

                await MainActor.run {
                    self.startTypewriter(fullText: fullText, at: botMsgIndex)
                }

            } catch {
                print("⚠️ [채팅] 메시지 전송 중 에러: \(error)")
                await MainActor.run { self.isResponding = false }
            }
        }
    }

    func isCreatingPersona(name: String, description: String) {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }

        let body: [String: String] = [
            "name": trimmedName,
            "description": description.trimmingCharacters(in: .whitespacesAndNewlines),
            "profileImageUrl": ""
        ]

        guard let httpBody = try? JSONSerialization.data(withJSONObject: body),
              let request = NetworkManager.shared.createRequest(urlPath: userPersonasPath, method: "POST", body: httpBody, requireAuth: true) else {
            return
        }

        DispatchQueue.main.async { self.isCreatingPersona = true }

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            defer { DispatchQueue.main.async { self.isCreatingPersona = false } }

            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 401 {
                self.handleUnauthorized(context: "페르소나 생성", statusCode: 401)
                return
            }

            guard let data = data, error == nil else { return }

            do {
                let newPersona = try JSONDecoder().decode(ServerPersona.self, from: data)
                DispatchQueue.main.async {
                    self.personaList.append(newPersona)
                    self.selectedPersona = newPersona
                }
            } catch {
                print("⚠️ 페르소나 생성 후 디코딩 에러: \(error)")
            }
        }.resume()
    }
}
