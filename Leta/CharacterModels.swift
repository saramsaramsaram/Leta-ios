import Foundation

struct ChatLineResponse: Decodable, Hashable {
    let speaker: String
    let message: String
}

struct SubCharacterResponse: Decodable, Identifiable {
    let id: Int
    let name: String
    let profileImageUrl: String?
    let quote: String?
    let age: String?
    let gender: String?
    let height: String?
    let tags: [String]?
    let appearance: String?
    let features: String?
}

struct LorebookResponse: Decodable, Identifiable {
    let id: Int
    let title: String
    let description: String
}

struct LetaCharacterResponse: Decodable, Identifiable {
    let id: Int
    let name: String
    let characterType: String // "PERSON" 또는 "WORLD"
    let title: String
    let intro: String
    let profileImageUrl: String?
    let bannerImageUrl: String?
    let tags: [String]
    let views: String?
    let hexColor: String?
    let prologue: [ChatLineResponse]?
    let creatorName: String?
    let creatorHandle: String?
    let creatorComment: String?
    let subCharacters: [SubCharacterResponse]?
    let lorebooks: [LorebookResponse]?
}
