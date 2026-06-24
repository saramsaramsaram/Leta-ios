struct ServerPersona: Identifiable, Codable, Hashable {
    let id: Int?
    var name: String
    var description: String?
    var profileImageUrl: String?
}
