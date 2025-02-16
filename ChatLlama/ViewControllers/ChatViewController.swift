import UIKit
import MessageKit
import InputBarAccessoryView
import Combine

class ChatViewController: MessagesViewController {
    private let viewModel: ChatViewModel
    private var cancellables = Set<AnyCancellable>()
    
    init(viewModel: ChatViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        self.viewModel = ChatViewModel() // Uses shared AppConfig by default
        super.init(coder: coder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupMessageInputBar()
        setupBindings()
    }
    
    private func setupBindings() {
        viewModel.$messages
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.messagesCollectionView.reloadData()
                self?.messagesCollectionView.scrollToLastItem(animated: true)
            }
            .store(in: &cancellables)
        
        viewModel.$isLoading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isLoading in
                self?.messageInputBar.inputTextView.placeholder = isLoading ? "ChatLlama is thinking..." : "Type a message"
                self?.messageInputBar.sendButton.isEnabled = !isLoading
            }
            .store(in: &cancellables)
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
}

// MARK: - MessagesDataSource
extension ChatViewController: MessagesDataSource {
    var currentSender: any MessageKit.SenderType {
        Sender.user
    }
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        return viewModel.getMessage(at: indexPath.section)
    }
    
    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        return viewModel.messageCount
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
        
        Task {
            do {
                try await viewModel.sendMessage(text)
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
