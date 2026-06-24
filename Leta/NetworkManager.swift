import Foundation

enum NetworkError: Error {
    case badURL
    case noData
    case decodingError
    case serverError(String)
}

class NetworkManager {
    static let shared = NetworkManager()
    private init() {}
    
    let baseURL = "http://localhost:8080"
    func createRequest(urlPath: String, method: String, body: Data? = nil, requireAuth: Bool = true) -> URLRequest? {
        guard let url = URL(string: "\(baseURL)\(urlPath)") else { return nil }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        if requireAuth {
            if let token = KeychainManager.shared.read(account: "accessToken") {
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            }
        }
        
        request.httpBody = body
        return request
    }
}
