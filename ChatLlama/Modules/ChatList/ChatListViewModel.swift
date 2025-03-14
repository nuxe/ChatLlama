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
    private let chatStore: ChatStore
    
    init(chatStore: ChatStore) {
        self.chatStore = chatStore
        setupBindings()
    }
    
    // MARK: - Private

    private func setupBindings() {
        chatStore.$chats
            .assign(to: &$chats)
    }
    
    func createNewChat() {
        chatStore.createNewChat()
    }
} 
