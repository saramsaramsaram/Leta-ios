import Foundation

struct AppleLoginRequest: Encodable {
    let identityToken: String
    let nickname: String?
}

struct PersonaResponse: Codable, Identifiable {
    let id: Int
    let name: String
    let description: String?
    let profileImageUrl: String?
}

struct UserResponse: Codable {
    let id: Int
    let googleSub: String
    let email: String?
    let nickname: String
    let personas: [PersonaResponse]?
}

struct AuthResponse: Codable {
    let accessToken: String
    let user: UserResponse
}
