//
//  Sender.swift
//  ChatLlama
//
//  Created by Kush Agrawal on 3/6/25.
//

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
    
    var avatarURL: URL? {
        switch self {
        case .user:
            return URL(string: "https://files.oaiusercontent.com/file-9gmWEsYACQaC2PJwVedftB?se=2025-03-14T01%3A07%3A17Z&sp=r&sv=2024-08-04&sr=b&rscc=max-age%3D604800%2C%20immutable%2C%20private&rscd=attachment%3B%20filename%3Da5540402-8014-47cc-9ab6-5480669c3723.webp&sig=kDIg6DmH900uPeic1oG4JemE1ZJyiS9S96b0UYAVA0w%3D")!
        case .bot:
            return URL(string: "https://files.oaiusercontent.com/file-E2468jfGcFbhMBodnSHoGd?se=2025-03-14T01%3A07%3A09Z&sp=r&sv=2024-08-04&sr=b&rscc=max-age%3D604800%2C%20immutable%2C%20private&rscd=attachment%3B%20filename%3D8faa4a67-cc38-48d7-95c5-8649f8ad3b57.webp&sig=3wa5jtr8WUwJ%2BKP91%2Bd0jQfX8cpWYlkZLS7u8qheTzo%3D")!
        }
    }
}
