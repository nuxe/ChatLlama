//
//  PersistableModels.swift
//  ChatLlama
//
//  Created by Kush Agrawal on 3/15/25.
//

import Foundation
import MessageKit
import UIKit

// MARK: - Data Models for Persistence

/// A persistable representation of a Chat
struct PersistableChat: Codable, Identifiable {
    var id: UUID
    var messages: [PersistableMessage]
    var created: Date
    
    /// SenderType enum for persistence
    enum PersistableSenderType: String, Codable {
        case user
        case bot
        
        var toSender: Sender {
            switch self {
            case .user: return .user
            case .bot: return .bot
            }
        }
        
        static func from(_ sender: SenderType) -> PersistableSenderType {
            if let sender = sender as? Sender {
                switch sender {
                case .user: return .user
                case .bot: return .bot
                }
            }
            // Default to bot if unknown
            return .bot
        }
    }
    
    // MARK: - Conversion Methods
    
    /// Convert from view model Chat
    static func from(_ chat: Chat) -> PersistableChat {
        return PersistableChat(
            id: chat.id,
            messages: chat.messages.map { PersistableMessage.from($0) },
            created: chat.created
        )
    }
    
    /// Convert to view model Chat
    func toViewModelChat() -> Chat {
        return Chat(
            id: id,
            messages: messages.map { $0.toViewModelMessage() },
            created: created
        )
    }
}

/// A persistable representation of a Message
struct PersistableMessage: Codable, Identifiable {
    var id: String
    var content: String
    var isImage: Bool
    var imageURL: URL?
    var sentDate: Date
    var senderType: PersistableChat.PersistableSenderType
    
    // MARK: - Conversion Methods
    
    /// Convert from view model Message
    static func from(_ message: Message) -> PersistableMessage {
        // Determine if the message contains an image
        var isImage = false
        var imageURL: URL? = nil
        var content = ""
        
        switch message.kind {
        case .text(let textContent):
            content = textContent
        case .photo(let mediaItem):
            isImage = true
            imageURL = mediaItem.url
            content = "Image"
        default:
            // For other message types, try to get content from the content property
            content = message.content
        }
        
        return PersistableMessage(
            id: message.messageId,
            content: content,
            isImage: isImage,
            imageURL: imageURL,
            sentDate: message.sentDate,
            senderType: PersistableChat.PersistableSenderType.from(message.sender)
        )
    }
    
    /// Convert to view model Message
    func toViewModelMessage() -> Message {
        let sender = senderType.toSender
        
        let messageKind: MessageKind
        if isImage, let imageURL = imageURL {
            let mediaItem = ImageMediaItem(
                url: imageURL,
                image: nil,
                placeholderImage: UIImage(),
                size: CGSize(width: 256, height: 256)
            )
            messageKind = .photo(mediaItem)
        } else {
            messageKind = .text(content)
        }
        
        return Message(id: id, kind: messageKind, sender: sender, sentDate: sentDate)
    }
} 