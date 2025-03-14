//
//  ChatViewModel.swift
//  ChatLlama
//
//  Created by Kush Agrawal on 2/24/25.
//

import Foundation
import Combine

@MainActor
class ChatListViewModel: ObservableObject {

    @Published private(set) var chats: [Chat] = []
    private let chatManager: ChatManager
    
    init(chatManager: ChatManager) {
        self.chatManager = chatManager
        setupBindings()
    }
    
    // MARK: - Private

    private func setupBindings() {
        chatManager.$chats
            .assign(to: &$chats)
    }
    
    func createNewChat() {
        chatManager.createNewChat()
    }

    func getChat(at index: Int) -> Chat {
        chats[index]
    }
} 
