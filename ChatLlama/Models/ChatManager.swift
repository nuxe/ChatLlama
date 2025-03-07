//
//  ChatManager.swift
//  ChatLlama
//
//  Created by Kush Agrawal on 3/7/25.
//

import Foundation
import MessageKit

class ChatManager {
    
    static let shared = ChatManager()
    
    var chats: [Chat]
    var currentChat: Chat
    
    init() {
        chats = [ChatManager.createNewChat()]
        currentChat = chats.last!
    }
    
    func addMessage(kind: MessageKind, sender: Sender) {
        currentChat.addMessage(kind: kind, sender: sender)
    }

    static func createNewChat() -> Chat {
        var chat = Chat(messages: [], created: Date())

        let welcomeMessage = "Hello! I'm ChatLlama. How can I help you today?"
        chat.addMessage(kind: .text(welcomeMessage), sender: .bot)

        return chat
    }
}
