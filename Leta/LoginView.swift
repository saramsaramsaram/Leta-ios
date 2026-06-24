import SwiftUI
import GoogleSignIn

struct LoginView: View {
    @State private var isLoggingIn: Bool = false
    @EnvironmentObject var appState: AppState
    
    private let googleClientID = "51742725925-v5dpfcfir8v20v753r7e8ffgib0r6qdb.apps.googleusercontent.com"
    
    var body: some View {
        ZStack {
            Color(red: 0.03, green: 0.03, blue: 0.05)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                
                VStack(spacing: 16) {
                    Text("LETA")
                        .font(.system(size: 48, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                        .tracking(2)
                    
                    Text("무한한 세계관, 당신만의 페르소나")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.gray.opacity(0.8))
                }
                
                Spacer()
                
                VStack(spacing: 12) {
                    Button(action: {
                        startGoogleLogin()
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "g.circle.fill")
                                .foregroundColor(.red)
                            Text("Google로 계속하기")
                                .font(.system(size: 16, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(Color(red: 0.15, green: 0.15, blue: 0.18))
                        .cornerRadius(26)
                    }
                    
                    Button(action: {
                        appState.triggerAppleLogin()
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "applelogo")
                                .foregroundColor(.white)
                            Text("Apple로 계속하기")
                                .font(.system(size: 16, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(Color.black)
                        .cornerRadius(26)
                        .overlay(
                            RoundedRectangle(cornerRadius: 26)
                                .stroke(Color.white.opacity(0.15), lineWidth: 1)
                        )
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
            
            if isLoggingIn {
                Color.black.opacity(0.5)
                    .ignoresSafeArea()
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
            }
        }
    }
    
    private func startGoogleLogin() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first(where: { $0.isKeyWindow })?.rootViewController else {
            return
        }
        
        isLoggingIn = true
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: googleClientID)
        GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController) { signInResult, error in
            if let error = error {
                print("⚠️ 구글 로그인 실패: \(error.localizedDescription)")
                isLoggingIn = false
                return
            }
            
            guard let result = signInResult,
                  let idToken = result.user.idToken?.tokenString else {
                isLoggingIn = false
                return
            }
            
            sendGoogleTokenToBackend(idToken: idToken)
        }
    }
    
    private func sendGoogleTokenToBackend(idToken: String) {
        guard let url = URL(string: "\(NetworkManager.shared.baseURL)/api/auth/google") else {
            isLoggingIn = false
            return
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: String] = ["idToken": idToken]
        urlRequest.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: urlRequest) { data, response, error in
            DispatchQueue.main.async {
                isLoggingIn = false
                
                if let data = data, error == nil {
                    if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let token = json["accessToken"] as? String {
                        
                        let saveSuccess = KeychainManager.shared.save(account: "accessToken", token: token)
                        
                        if saveSuccess {
                            appState.isAuthenticated = true
                            print("🎉 구글 로그인 최종 성공 및 키체인 동기화 완료!")
                        } else {
                            print("⚠️ 토큰 키체인 저장 실패")
                        }
                    }
                } else {
                    print("⚠️ 스프링 부트 통신 에러: \(String(describing: error))")
                }
            }
        }.resume()
    }
}
