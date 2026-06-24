import Foundation
import AuthenticationServices
import Combine

class AppState: NSObject, ObservableObject {
    @Published var isAuthenticated: Bool = false
    @Published var currentUser: UserResponse? = nil
    @Published var errorMessage: String? = nil
    
    override init() {
        super.init()
        if KeychainManager.shared.read(account: "accessToken") != nil {
            self.isAuthenticated = true
        }

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAuthTokenExpired),
            name: .authTokenDidExpire,
            object: nil
        )
    }
    
    @objc private func handleAuthTokenExpired() {
        DispatchQueue.main.async {
            self.isAuthenticated = false
            self.currentUser = nil
            self.errorMessage = "로그인이 만료되었습니다."
        }
    }
    
    func triggerAppleLogin() {
        let provider = ASAuthorizationAppleIDProvider()
        let request = provider.createRequest()
        request.requestedScopes = [.fullName, .email]
        
        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self
        controller.performRequests()
    }
    
    private func sendTokenToBackend(identityToken: String, nickname: String?) {
        let loginRequest = AppleLoginRequest(identityToken: identityToken, nickname: nickname)
        guard let body = try? JSONEncoder().encode(loginRequest),
              let request = NetworkManager.shared.createRequest(
                urlPath: "/api/auth/apple",
                method: "POST",
                body: body,
                requireAuth: false
              ) else { return }
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            
            if let error = error {
                DispatchQueue.main.async {
                    self.errorMessage = "서버 통신 에러: \(error.localizedDescription)"
                }
                return
            }
            
            guard let data = data else { return }
            
            do {
                let authResponse = try JSONDecoder().decode(AuthResponse.self, from: data)
                let saveSuccess = KeychainManager.shared.save(account: "accessToken", token: authResponse.accessToken)
                
                DispatchQueue.main.async {
                    if saveSuccess {
                        self.currentUser = authResponse.user
                        self.isAuthenticated = true
                        print("🎉 애플 로그인 최종 성공 및 키체인 동기화 완료!")
                    } else {
                        self.errorMessage = "토큰 키체인 저장 실패"
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "애플 로그인 인증 처리 실패"
                }
                print("⚠️ Apple 로그인 백엔드 응답 디코딩 실패: \(error)")
            }
        }.resume()
    }
}

extension AppState: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, authorizationDidCompleteWithAuthorization authorization: ASAuthorization) {
        if let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
           let tokenData = credential.identityToken,
           let tokenString = String(data: tokenData, encoding: .utf8) {
            
            // 이름 수집 (최초 가입 때만 들어옴)
            var collectedNickname: String? = nil
            if let fullName = credential.fullName {
                let fName = fullName.familyName ?? ""
                let gName = fullName.givenName ?? ""
                collectedNickname = "\(fName)\(gName)".trimmingCharacters(in: .whitespacesAndNewlines)
            }
            
            // 서버 전송 레이어로 위임
            sendTokenToBackend(identityToken: tokenString, nickname: collectedNickname)
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        DispatchQueue.main.async {
            self.errorMessage = "Apple 로그인 취소 또는 에러"
        }
    }
}

extension AppState: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let mainWindow = windowScene.windows.first(where: { $0.isKeyWindow }) {
            return mainWindow
        }
        return UIWindow()
    }
}

extension NSNotification.Name {
    static let authTokenDidExpire = NSNotification.Name("authTokenDidExpire")
}
