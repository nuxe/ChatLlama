//
//  ChatManager.swift
//  ChatLlama
//
//  Created by Kush Agrawal on 3/7/25.
//

import Foundation
import MessageKit

class ChatManager: ObservableObject {
    
    static let shared = ChatManager()
    
    @Published var chats: [Chat] = []
    @Published var currentChatID: UUID?
    
    init() {
        createNewChat()
    }
    
    func addMessage(id: UUID, kind: MessageKind, sender: Sender) {
        guard let chatIndex = getChatIndex(id) else { return }
        var chat = chats[chatIndex]
        chat.addMessage(kind: kind, sender: sender)
        chats[chatIndex] = chat
    }

    func createNewChat() {
        var chat = Chat(messages: [], created: Date())

        let welcomeMessage = "Hello! I'm ChatLlama. How can I help you today?"
        chat.addMessage(kind: .text(welcomeMessage), sender: .bot)

        chats.append(chat)
        currentChatID = chat.id
    }
    
    func getChatIndex(_ id: UUID) -> Int? {
        return chats.firstIndex(where: { chat in
            chat.id == id
        })
    }
}
