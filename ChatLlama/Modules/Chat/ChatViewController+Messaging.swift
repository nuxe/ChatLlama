//
//  ChatViewController+Messaging.swift
//  ChatLlama
//
//  Created by Kush Agrawal on 2/26/25.
//

import UIKit
import MessageKit
import InputBarAccessoryView
import Combine
import SDWebImage

// MARK: - MessagesDataSource
extension ChatViewController: MessagesDataSource {
    var currentSender: any MessageKit.SenderType {
        Sender.user
    }
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        guard let chat = viewModel.currentChat else { return Message.empty }
        return chat.messages[indexPath.section]
    }
    
    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        guard let chat = viewModel.currentChat else { return 0 }
        return chat.messages.count
    }
}

// MARK: - MessagesLayoutDelegate
extension ChatViewController: MessagesLayoutDelegate {
    func footerViewSize(for section: Int, in messagesCollectionView: MessagesCollectionView) -> CGSize {
        return CGSize(width: 0, height: 8)
    }
}

// MARK: - MessagesDisplayDelegate
extension ChatViewController: MessagesDisplayDelegate {
    func backgroundColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
        return message.sender.senderId == Sender.user.senderId ? .systemBlue : .systemGray5
    }
    
    func messageStyle(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageStyle {
        let corner: MessageStyle.TailCorner = message.sender.senderId == Sender.user.senderId ? .bottomRight : .bottomLeft
        return .bubbleTail(corner, .curved)
    }
    
    func configureAvatarView(_ avatarView: AvatarView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        guard let sender = message.sender as? Sender else { return }
        
        if let avatarURL = sender.avatarURL {
            // Use SDWebImage since it's already in your project
            avatarView.sd_setImage(with: avatarURL, placeholderImage: nil)
        }
    }
    
    func configureMediaMessageImageView(_ imageView: UIImageView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        switch message.kind {
            
        case let .photo(mediaItem):
            let imageURL = mediaItem.url
            imageView.sd_setImage(with: imageURL)
        default:
            break
        }
    }
}

// MARK: - InputBarAccessoryViewDelegate
extension ChatViewController: InputBarAccessoryViewDelegate {
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        // Clear input bar
        inputBar.inputTextView.text = ""
        
        Task {
            do {
                try await viewModel.sendUserMessage(text)
            } catch {
                // Show error alert
                let alert = UIAlertController(
                    title: "Error",
                    message: "Failed to get response: \(error.localizedDescription)",
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                present(alert, animated: true)
            }
        }
    }
}
