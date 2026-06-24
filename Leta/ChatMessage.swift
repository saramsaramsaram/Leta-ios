import Foundation

struct ChatMessage: Identifiable, Codable {
    var id = UUID()
    let speaker: String
    let message: String
    let timestamp: Date
    
    var parsedDisplayMessages: [DisplayMessage] {
        if speaker == "USER" {
            return [DisplayMessage(senderName: "USER", content: message, isNarrative: false)]
        }
        
        var list: [DisplayMessage] = []
        
        let rawBlocks = message.components(separatedBy: "@")
        
        for block in rawBlocks {
            let trimmedBlock = block.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmedBlock.isEmpty { continue }
            
            let parts = trimmedBlock.components(separatedBy: ":")
            if parts.count >= 2 {
                let rawName = parts[0].trimmingCharacters(in: .whitespacesAndNewlines)
                var remainingContent = parts[1...].joined(separator: ":").trimmingCharacters(in: .whitespacesAndNewlines)
                
                if remainingContent.hasPrefix("\"") { remainingContent.removeFirst() }
                if remainingContent.hasSuffix("\"") { remainingContent.removeLast() }
                
                let isNarrative = (rawName == "지문" || rawName == "system" || rawName == "내레이션")
                list.append(DisplayMessage(senderName: rawName, content: remainingContent, isNarrative: isNarrative))
            } else {
                list.append(DisplayMessage(senderName: "지문", content: trimmedBlock, isNarrative: true))
            }
        }
        return list
    }
}

struct DisplayMessage: Identifiable {
    let id = UUID()
    let senderName: String
    let content: String
    let isNarrative: Bool
}
