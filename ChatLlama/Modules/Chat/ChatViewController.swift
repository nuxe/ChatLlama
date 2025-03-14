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
        title = "Chat Llama"
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
        
        // Customize input bar appearance
        messageInputBar.inputTextView.placeholder = "Ask anything..."
        messageInputBar.inputTextView.backgroundColor = .systemGray6
        messageInputBar.inputTextView.layer.cornerRadius = 24
        messageInputBar.inputTextView.layer.masksToBounds = true
        
        // Remove border and change background
        messageInputBar.backgroundView.backgroundColor = .systemBackground
        messageInputBar.separatorLine.isHidden = true
        messageInputBar.inputTextView.scrollIndicatorInsets = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
        messageInputBar.setStackViewItems([], forStack: .left, animated: false)
        
        // Create custom button items
        let imageGenButton = InputBarButtonItem()
            .configure {
                $0.setSize(CGSize(width: 36, height: 36), animated: false)
                $0.setImage(UIImage(systemName: "photo"), for: .normal)
                $0.tintColor = .systemBlue
                $0.spacing = .fixed(16)
            }.onTouchUpInside { [weak self] _ in
                self?.viewModel.chatType = .image
            }
        
        let voiceButton = InputBarButtonItem()
            .configure {
                $0.setSize(CGSize(width: 36, height: 36), animated: false)
                $0.setImage(UIImage(systemName: "waveform"), for: .normal)
                $0.tintColor = .systemBlue
                $0.spacing = .fixed(16)
            }
        
        // Configure the existing send button
        messageInputBar.sendButton
            .configure {
                $0.setSize(CGSize(width: 36, height: 36), animated: false)
                $0.setImage(UIImage(systemName: "arrow.up.circle.fill"), for: .normal)
                $0.tintColor = .systemBlue
                $0.setTitle("", for: .normal)
            }
        
        // Configure input bar layout
        messageInputBar.setRightStackViewWidthConstant(to: 132, animated: false)
        messageInputBar.setStackViewItems([imageGenButton, voiceButton, messageInputBar.sendButton], forStack: .right, animated: false)
        
        // Update padding and layout
        messageInputBar.padding.top = 12
        messageInputBar.padding.bottom = 12
        messageInputBar.padding.left = 16
        messageInputBar.padding.right = 16
        
        // Customize text view
        messageInputBar.inputTextView.placeholderTextColor = .systemGray
        messageInputBar.inputTextView.textContainerInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        messageInputBar.inputTextView.placeholderLabelInsets = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
        
        // Set the maxTextViewHeight if you'd like to grow the text view to a certain point
        messageInputBar.maxTextViewHeight = 120
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
                self?.messageInputBar.sendButton.isEnabled = !isLoading
            }
            .store(in: &cancellables)
    }
}
