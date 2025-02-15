import Foundation
import MessageKit

enum Sender: Equatable, SenderType {
    case user
    case bot
    
    var senderId: String {
        switch self {
        case .user:
            return "user"
        case .bot:
            return "bot"
        }
    }
    
    var displayName: String {
        switch self {
        case .user:
            return "You"
        case .bot:
            return "ChatLlama"
        }
    }
}

struct Message: MessageType {
    var messageId: String
    var sentDate: Date
    var kind: MessageKind
    var sender: SenderType
    
    init(id: String = UUID().uuidString,
         content: String,
         sender: Sender,
         sentDate: Date = Date()) {
        self.messageId = id
        self.sentDate = sentDate
        self.sender = sender
        self.kind = .text(content)
    }
    
    // Helper to get text content
    var content: String {
        switch kind {
        case .text(let text):
            return text
        default:
            return ""
        }
    }
} 
