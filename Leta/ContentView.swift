import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedTab: Int = 0 // 0: 홈, 1: 대화, 2: 제작, 3: 마이페이지
    
    init() {
        let appearance = UITabBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterialDark)
        
        UITabBar.appearance().scrollEdgeAppearance = appearance
        UITabBar.appearance().standardAppearance = appearance
    }
    
    var body: some View {
        ZStack {
            if appState.isAuthenticated {
                TabView(selection: $selectedTab) {
                    ZetaHomeView()
                        .tabItem {
                            Image(systemName: "house.fill")
                            Text("홈")
                        }
                        .tag(0)
                    
                    Text("대화방 목록")
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color(red: 0.05, green: 0.05, blue: 0.07))
                        .tabItem {
                            Image(systemName: "bubble.left.and.bubble.right.fill")
                            Text("대화")
                        }
                        .tag(1)
                    
                    Text("캐릭터 제작소")
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color(red: 0.05, green: 0.05, blue: 0.07))
                        .tabItem {
                            Image(systemName: "plus.circle.fill")
                            Text("제작")
                        }
                        .tag(2)
                    
                    Text("마이페이지")
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color(red: 0.05, green: 0.05, blue: 0.07))
                        .tabItem {
                            Image(systemName: "person.fill")
                            Text("마이페이지")
                        }
                        .tag(3)
                }
                .accentColor(.white)
            } else {
                LoginView()
            }
        }
    }
}

struct ZetaHomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    
    let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(red: 0.05, green: 0.05, blue: 0.07)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 16) {
                        HStack(spacing: 20) {
                            HStack(spacing: 12) {
                                Text("홈")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.white)
                                Text("랭킹")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(.gray)
                            }
                            Spacer()
                            
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 20))
                                .foregroundColor(.white)
                            
                            Text("로그인")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.purple)
                                .cornerRadius(6)
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)
                        
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("하이브 소속 아티스트 무단 도용\n캐릭터 삭제 및 제작 금지 안내")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.white)
                                    .lineSpacing(4)
                                Spacer()
                            }
                            
                            HStack {
                                Spacer()
                                Text("4/5")
                                    .font(.system(size: 11))
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding()
                        .background(Color(white: 0.12))
                        .cornerRadius(12)
                        .padding(.horizontal)
                        
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(viewModel.characters) { character in
                                NavigationLink(destination: CharacterDetailView(character: character)) {
                                    ZetaCharacterCard(character: character)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 90)
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .onAppear {
            viewModel.fetchCharacters()
        }
    }
}

struct ZetaCharacterCard: View {
    let character: LetaCharacterResponse
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .topLeading) {
                if let urlStr = character.profileImageUrl, let url = URL(string: urlStr) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image.resizable()
                                 .scaledToFill()
                        default:
                            Color(hex: character.hexColor ?? "#374151")
                        }
                    }
                    .frame(height: 220)
                    .cornerRadius(12)
                    .clipped()
                } else {
                    Color(hex: character.hexColor ?? "#374151")
                        .frame(height: 220)
                        .cornerRadius(12)
                        .overlay(
                            Text(String(character.name.first ?? "?"))
                                .font(.system(size: 40, weight: .black))
                                .foregroundColor(.white.opacity(0.15))
                        )
                }
                
                HStack(spacing: 4) {
                    Image(systemName: "bubble.left.fill")
                        .font(.system(size: 9))
                    Text(character.views ?? "0만")
                }
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.white.opacity(0.8))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.black.opacity(0.4))
                .cornerRadius(10)
                .padding(10)
            }
            

            VStack(alignment: .leading, spacing: 4) {
                Text(character.name)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white)
                
                Text(character.title)
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
                    .lineLimit(1)
                
                Text(character.tags.map { "#\($0)" }.joined(separator: " "))
                    .font(.system(size: 11))
                    .foregroundColor(.gray.opacity(0.7))
                    .lineLimit(1)
            }
            .padding(.horizontal, 4)
        }
    }
}

#Preview {
    let mockState = AppState()
    mockState.isAuthenticated = true
    
    return ContentView()
        .environmentObject(mockState)
        .preferredColorScheme(.dark)
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 7:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: Double(a) / 255)
    }
}
