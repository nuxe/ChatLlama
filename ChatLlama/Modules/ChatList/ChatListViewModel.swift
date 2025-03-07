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
        
    init() {}

    // Generic
    
    func createNewChat() {
        let chat = Chat(messages: [], created: Date())
        chats.append(chat)
    }
    
    var chatCount: Int {
        chats.count
    }
    
    func getChat(at index: Int) -> Chat {
        chats[index]
    }
} 
