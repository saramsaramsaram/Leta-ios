import Foundation
import Combine

class HomeViewModel: ObservableObject {
    @Published var characters: [LetaCharacterResponse] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    
    func fetchCharacters() {
        guard let request = NetworkManager.shared.createRequest(
            urlPath: "/api/characters",
            method: "GET",
            requireAuth: true
        ) else {
            loadMockData()
            return
        }
        
        DispatchQueue.main.async { self.isLoading = true }
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            
            DispatchQueue.main.async { self.isLoading = false }
            
            if let _ = error {
                DispatchQueue.main.async {
                    print("⚠️ 서버 연결 끊김: 프리뷰 가짜 데이터를 로드합니다.")
                    self.loadMockData()
                }
                return
            }
            
            guard let data = data else {
                DispatchQueue.main.async { self.loadMockData() }
                return
            }
            
            do {
                let decodedData = try JSONDecoder().decode([LetaCharacterResponse].self, from: data)
                DispatchQueue.main.async {
                    if decodedData.isEmpty {
                        self.loadMockData()
                    } else {
                        self.characters = decodedData
                        self.errorMessage = nil
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    print("Decoding Error: \(error) -> 가짜 데이터 전환")
                    self.loadMockData()
                }
            }
        }.resume()
    }
    
    private func loadMockData() {
        self.characters = [
            LetaCharacterResponse(
                id: 1,
                name: "한서윤",
                characterType: "PERSON",
                title: "비밀을 품은 천재 천체물리학자",
                intro: "밤하늘의 별을 보며 세상을 분석하지만, 정작 자신의 마음은 읽지 못하는 그녀.",
                profileImageUrl: nil,
                bannerImageUrl: nil,
                tags: ["천재", "냉소적", "소꿉친구", "고양이파"],
                views: "15.2K",
                hexColor: "#6366F1",
                prologue: [
                    ChatLineResponse(speaker: "한서윤", message: "...또 늦었네. 별 관측하기 딱 좋은 시간인데 말이야.")
                ],
                creatorName: "ZETA_Master",
                creatorHandle: "@zeta_dev",
                creatorComment: "츤데레 과학자 캐릭터입니다. 친해지면 말을 부드럽게 해요.",
                subCharacters: [],
                lorebooks: []
            ),
            LetaCharacterResponse(
                id: 2,
                name: "크로노스 학원",
                characterType: "WORLD",
                title: "마법과 증기기관이 공존하는 공중도시",
                intro: "거대한 시계탑을 중심으로 시간이 왜곡된 마법사들의 은신처.",
                profileImageUrl: nil,
                bannerImageUrl: nil,
                tags: ["스팀펑크", "판타지", "아카데미", "미스터리"],
                views: "8.9K",
                hexColor: "#EC4899",
                prologue: [],
                creatorName: "WorldBuilder",
                creatorHandle: "@world_make",
                creatorComment: "자유도 높은 세계관 루프물입니다.",
                subCharacters: [],
                lorebooks: []
            ),
            LetaCharacterResponse(
                id: 3,
                name: "강우진",
                characterType: "PERSON",
                title: "골목길에서 마주친 수상한 검사",
                intro: "낮에는 무기력한 백수처럼 보이지만, 밤이 되면 도시의 그림자를 쫓는 사냥꾼.",
                profileImageUrl: nil,
                bannerImageUrl: nil,
                tags: ["세계관최강자", "능글남", "현대판타지"],
                views: "23.1K",
                hexColor: "#10B981",
                prologue: [],
                creatorName: "Saram_Dev",
                creatorHandle: "@saram",
                creatorComment: "서사형 대화에 최적화되어 있습니다.",
                subCharacters: [],
                lorebooks: []
            )
        ]
        self.errorMessage = nil
    }
    
    
}

