//
//  Message.swift
//  ChatLlama
//
//  Created by Kush Agrawal on 3/6/25.
//

import Foundation
import MessageKit

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
    
    static var empty = Message.init(kind: .text(""), sender: .bot)
}
