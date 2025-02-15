import UIKit
import MessageKit
import InputBarAccessoryView

class ChatViewController: MessagesViewController {
    private var messages: [Message] = []
    private let ollamaService = OllamaAPIService.shared
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupMessageInputBar()
        
        // Add a welcome message
        addMessage(content: "Hello! I'm ChatLlama. How can I help you today?", sender: .bot)
    }
    
    private func setupUI() {
        title = "ChatLlama"
        
        // Configure the messages collection view
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        
        // Customize the UI
        if let layout = messagesCollectionView.collectionViewLayout as? MessagesCollectionViewFlowLayout {
            layout.setMessageOutgoingAvatarSize(.zero)
            layout.setMessageIncomingAvatarSize(.zero)
        }
    }
    
    private func setupMessageInputBar() {
        messageInputBar.delegate = self
        messageInputBar.inputTextView.placeholder = "Type a message"
        messageInputBar.sendButton.setTitle("", for: .normal)
        messageInputBar.sendButton.setImage(UIImage(systemName: "arrow.up.circle.fill"), for: .normal)
    }
    
    private func addMessage(content: String, sender: Sender) {
        let message = Message(content: content, sender: sender)
        messages.append(message)
        
        // Reload the collection view
        messagesCollectionView.reloadData()
        messagesCollectionView.scrollToLastItem(animated: true)
    }
    
    private func sendMessageToOllama(_ text: String) {
        // Show loading indicator
        messageInputBar.inputTextView.placeholder = "ChatLlama is thinking..."
//        messageInputBar.isEnabled = false
        
        Task {
            do {
                let response = try await ollamaService.sendMessage(prompt: text)
                
                // Update UI on main thread
                await MainActor.run {
                    addMessage(content: response, sender: .bot)
                    messageInputBar.inputTextView.placeholder = "Type a message"
//                    messageInputBar.isEnabled = true
                }
            } catch {
                await MainActor.run {
                    // Show error alert
                    let alert = UIAlertController(
                        title: "Error",
                        message: "Failed to get response: \(error.localizedDescription)",
                        preferredStyle: .alert
                    )
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    present(alert, animated: true)
                    
                    messageInputBar.inputTextView.placeholder = "Type a message"
//                    messageInputBar.isEnabled = true
                }
            }
        }
    }
}

// MARK: - MessagesDataSource
extension ChatViewController: MessagesDataSource {
    var currentSender: any MessageKit.SenderType {
        Sender.user
    }
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        return messages[indexPath.section]
    }
    
    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        return messages.count
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
}

// MARK: - InputBarAccessoryViewDelegate
extension ChatViewController: InputBarAccessoryViewDelegate {
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        // Clear input bar
        inputBar.inputTextView.text = ""
        
        // Add user message
        addMessage(content: text, sender: .user)
        
        // Send to Ollama
        sendMessageToOllama(text)
    }
} 
