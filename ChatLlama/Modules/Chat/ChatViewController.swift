//
//  ChatViewController.swift
//  ChatLlama
//
//  Created by Kush Agrawal on 2/24/25.
//

import UIKit
import MessageKit
import InputBarAccessoryView
import Combine
import SDWebImage

class ChatViewController: MessagesViewController {
    
    // MARK: - Properties
    
    let viewModel: ChatViewModel
    private var cancellables = Set<AnyCancellable>()
    
    var chat: Chat {
        viewModel.chat
    }

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
        setupMessageInputBar()
        setupBindings()
    }

    // MARK: - Private
    
    private func setupUI() {
        title = "Chat Llama 🦙"
        navigationController?.navigationBar.prefersLargeTitles = true
        
        // Configure the messages collection view
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        
        // Customize the UI
        messagesCollectionView.backgroundColor = .systemBackground
    }
    
    private func setupMessageInputBar() {
        messageInputBar.delegate = self
        
        // Customize input bar
        messageInputBar.inputTextView.placeholder = "Ask anything..."
        messageInputBar.sendButton.setTitle("", for: .normal)
        messageInputBar.sendButton.setImage(UIImage(systemName: "arrow.up.circle.fill"), for: .normal)
        messageInputBar.sendButton.tintColor = .systemBlue
    }
    
    private func setupBindings() {
        viewModel.$chat
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.messagesCollectionView.reloadData()
                self?.messagesCollectionView.scrollToLastItem(animated: true)
            }
            .store(in: &cancellables)
        
        viewModel.$isLoading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isLoading in
                self?.messageInputBar.sendButton.isEnabled = !isLoading
            }
            .store(in: &cancellables)
    }
}
