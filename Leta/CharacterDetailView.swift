import SwiftUI

struct CharacterDetailView: View {
    let character: LetaCharacterResponse
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ZStack(alignment: .bottom) {
            Color(red: 0.03, green: 0.03, blue: 0.05)
                .ignoresSafeArea()
            
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    
                    ZStack(alignment: .bottomLeading) {
                        if let urlStr = character.profileImageUrl, let url = URL(string: urlStr) {
                            AsyncImage(url: url) { image in
                                image.resizable()
                                     .scaledToFill()
                            } placeholder: {
                                Color(hex: character.hexColor ?? "#1E1E24")
                            }
                            .frame(width: UIScreen.main.bounds.width, height: 460)
                            .clipped()
                        } else {
                            LinearGradient(
                                colors: [Color(hex: character.hexColor ?? "#5B21B6"), Color(red: 0.03, green: 0.03, blue: 0.05)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                            .frame(height: 460)
                        }
                        
                        LinearGradient(
                            colors: [.clear, Color(red: 0.03, green: 0.03, blue: 0.05).opacity(0.8), Color(red: 0.03, green: 0.03, blue: 0.05)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(height: 200)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 5) {
                                Image(systemName: "bubble.left.fill")
                                    .font(.system(size: 10))
                                Text("\(character.views ?? "0만") 배정")
                            }
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.black.opacity(0.4))
                            .cornerRadius(12)
                            
                            Text(character.name)
                                .font(.system(size: 34, weight: .black))
                                .foregroundColor(.white)
                            
                            Text(character.title)
                                .font(.system(size: 15, weight: .regular))
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                    }
                    
                    VStack(alignment: .leading, spacing: 24) {
                        
                        Text(character.intro)
                            .font(.system(size: 15))
                            .foregroundColor(Color(red: 0.7, green: 0.7, blue: 0.7))
                            .lineSpacing(6)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(character.tags, id: \.self) { tag in
                                    Text("# \(tag)")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(.white.opacity(0.8))
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 7)
                                        .background(Color(white: 0.12))
                                        .cornerRadius(16)
                                }
                            }
                        }
                        
                        Divider()
                            .background(Color.white.opacity(0.08))
                            .padding(.vertical, 8)
                        
                        if let prologueLines = character.prologue, !prologueLines.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("첫 대화 지문")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.purple)
                                
                                ForEach(prologueLines, id: \.self) { line in
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text(line.speaker)
                                            .font(.system(size: 13, weight: .bold))
                                            .foregroundColor(.purple.opacity(0.8))
                                        Text(line.message)
                                            .font(.system(size: 15))
                                            .foregroundColor(.white)
                                            .lineSpacing(5)
                                    }
                                    .padding(16)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color(white: 0.06))
                                    .cornerRadius(12)
                                }
                            }
                        }
                        
                        if let subs = character.subCharacters, !subs.isEmpty {
                            VStack(alignment: .leading, spacing: 14) {
                                Text("주변 인물")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white)
                                
                                ForEach(subs) { sub in
                                    HStack(spacing: 12) {
                                        Circle()
                                            .fill(LinearGradient(colors: [.purple, .indigo], startPoint: .top, endPoint: .bottom).opacity(0.3))
                                            .frame(width: 42, height: 42)
                                            .overlay(Text(String(sub.name.first ?? "?")).foregroundColor(.white).font(.system(size: 14, weight: .bold)))
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(sub.name)
                                                .font(.system(size: 14, weight: .bold))
                                                .foregroundColor(.white)
                                            Text(sub.quote ?? "설정된 지문이 없습니다.")
                                                .font(.system(size: 12))
                                                .foregroundColor(.gray)
                                        }
                                        Spacer()
                                    }
                                    .padding(.vertical, 4)
                                }
                            }
                        }
                        
                        if let lores = character.lorebooks, !lores.isEmpty {
                            VStack(alignment: .leading, spacing: 14) {
                                Text("세계관 설정")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white)
                                
                                ForEach(lores) { lore in
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text(lore.title)
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundColor(.indigo)
                                        Text(lore.description)
                                            .font(.system(size: 13))
                                            .foregroundColor(.gray)
                                            .lineSpacing(4)
                                    }
                                    .padding(14)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color(white: 0.05))
                                    .cornerRadius(10)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    
                    Color.clear.frame(height: 120)
                }
            }
            .ignoresSafeArea(edges: .top)
            
            VStack {
                HStack {
                    Button(action: { presentationMode.wrappedValue.dismiss() }) {
                        Image(systemName: "arrow.left")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .padding(10)
                            .background(Color.black.opacity(0.4))
                            .clipShape(Circle())
                    }
                    Spacer()
                }
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 56)
            VStack {
                NavigationLink(destination: ChatRoomView(character: character)) {
                Text("대화 시작하기")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 52)
                                    .background(LinearGradient(
                                        colors: [Color(hex: "#7C3AED"), Color(hex: "#4F46E5")],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    ))
                                    .cornerRadius(26)
                                    .shadow(color: Color(hex: "#7C3AED").opacity(0.3), radius: 10, x: 0, y: 5)
                            }
                            .padding(.horizontal, 20)
                            .padding(.bottom, 28)
                        }
                        .frame(maxWidth: .infinity)
                        .background(
                            LinearGradient(
                                colors: [.clear, Color(red: 0.03, green: 0.03, blue: 0.05).opacity(0.9), Color(red: 0.03, green: 0.03, blue: 0.05)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                            .frame(height: 100)
                        )
        }
        .navigationBarHidden(true)
    }
}
