//
//  ChatViewController.swift
//  ChatLlama
//
//  Created by Kush Agrawal on 2/24/25.
//

import UIKit
import MessageKit
import Combine

class ChatViewController: MessagesViewController {
    
    // MARK: - Properties
    
    let viewModel: ChatViewModel
    private var cancellables = Set<AnyCancellable>()
    
    // Custom input bar
    private lazy var chatInputBar: ChatInputBar = {
        let chatInputBar = ChatInputBar(frame: .zero)
        chatInputBar.delegate = self
        return chatInputBar
    }()

    // MARK: - Init

    init(viewModel: ChatViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    @MainActor required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Overrides

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupCustomInputBar()
        setupBindings()
    }

    // MARK: - Private Methods
    
    private func setupUI() {
        title = "Chat Llama"
        navigationController?.navigationBar.prefersLargeTitles = true
        
        // Configure the messages collection view
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        
        // Customize the UI
        messagesCollectionView.backgroundColor = .systemBackground
    }
    
    private func setupCustomInputBar() {
        // Add it to the messageInputBar
        messageInputBar.backgroundView.backgroundColor = .systemBackground
        messageInputBar.separatorLine.isHidden = true
        
        // Remove default items from the input bar
        messageInputBar.inputTextView.isHidden = true
        messageInputBar.setLeftStackViewWidthConstant(to: 0, animated: false)
        messageInputBar.setRightStackViewWidthConstant(to: 0, animated: false)
        messageInputBar.setStackViewItems([], forStack: .left, animated: false)
        messageInputBar.setStackViewItems([], forStack: .right, animated: false)
        
        // Set our custom input bar as the middle content view
        messageInputBar.setMiddleContentView(chatInputBar, animated: false)
        
        // Update padding
        messageInputBar.padding = UIEdgeInsets(top: 12, left: 8, bottom: 12, right: 8)
    }
    
    private func setupBindings() {
        viewModel.$currentChat
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.messagesCollectionView.reloadData()
                self?.messagesCollectionView.scrollToLastItem(animated: true)
            }
            .store(in: &cancellables)
        
        viewModel.$isLoading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isLoading in
                self?.chatInputBar.setEnabled(!isLoading)
                self?.setTypingIndicatorViewHidden(!isLoading, animated: true)
            }
            .store(in: &cancellables)
    }
}

// MARK: - ChatInputBarDelegate

extension ChatViewController: ChatInputBar.ChatInputBarDelegate {
    
    func inputBar(_ inputBar: ChatInputBar, didSendMessage text: String) {
        // Send the message
        Task {
            do {
                try await viewModel.sendUserMessage(text)
            } catch {
                print("Error sending message: \(error)")
            }
        }
    }
    
    func inputBarDidTapVoice(_ inputBar: ChatInputBar) {
        // Handle voice button tap
        print("Voice button tapped")
    }
    
    func inputBarDidImageGen(_ isSelected: Bool) {
        viewModel.chatType = isSelected ? .image : .text
    }
}


