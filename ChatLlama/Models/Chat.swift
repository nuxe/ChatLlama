//
//  Chat.swift
//  ChatLlama
//
//  Created by Kush Agrawal on 3/6/25.
//

import Foundation
import MessageKit

struct Chat: Identifiable {
    
    var id: UUID
    var messages: [Message]
    var created: Date
   
    init(id: UUID =  UUID(), messages: [Message], created: Date = Date()) {
        self.id = id
        self.messages = messages
        self.created = created
    }
    
    var title: String {
        messages.first { message in
            let sender = message.sender as? Sender
            return sender == .user
        }?.content ?? "New chat"
    }
    
    mutating func addMessage(kind: MessageKind, sender: Sender) {
        let message = Message.init(kind: kind, sender: sender)
        messages.append(message)
    }
}
