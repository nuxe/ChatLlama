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
         kind: MessageKind,
         sender: Sender,
         sentDate: Date = Date()) {
        self.messageId = id
        self.sentDate = sentDate
        self.sender = sender
        self.kind = kind
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

struct Chat: Identifiable {
    var id: UUID = UUID()
    var messages: [Message]
    var created: Date
    
    var title: String {
        messages.first?.content ?? "New Chat"
    }
    
    mutating func addMessage(kind: MessageKind, sender: Sender) {
        let message = Message.init(kind: kind, sender: sender)
        messages.append(message)
    }
}
