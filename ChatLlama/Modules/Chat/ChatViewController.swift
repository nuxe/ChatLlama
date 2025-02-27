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
        title = "Chat Llama 🦙"
        navigationController?.navigationBar.prefersLargeTitles = true
        
        if UIDevice.current.userInterfaceIdiom == .phone {
            let menuButton = UIBarButtonItem(image: UIImage(systemName: "line.horizontal.3"),
                                             style: .plain,
                                             target: self,
                                             action: #selector(openMenu))
            navigationItem.leftBarButtonItem = menuButton
        }

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
    
    @objc
    private func openMenu() {
        let menuVC = ChatListViewController()
        menuVC.modalPresentationStyle = .overCurrentContext
        menuVC.view.backgroundColor = UIColor.black.withAlphaComponent(0.3) // Dimmed effect

        navigationController?.present(menuVC, animated: true)
    }
}
