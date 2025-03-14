//
//  ChatListViewController.swift
//  ChatLlama
//
//  Created by Kush Agrawal on 2/26/25.
//

import UIKit
import Combine

// Protocol for communicating chat selection
protocol ChatListViewControllerDelegate: AnyObject {
    func chatListViewController(_ controller: ChatListViewController, didSelectChat chat: Chat)
}

class ChatListViewController: UITableViewController {

    // MARK: - Properties
    
    weak var delegate: ChatListViewControllerDelegate?
    private var cancellables = Set<AnyCancellable>()
    let chatListViewModel: ChatListViewModel
    let chatViewModel: ChatViewModel

    // MARK: - Init

    init(chatListViewModel: ChatListViewModel, chatViewModel: ChatViewModel) {
        self.chatListViewModel = chatListViewModel
        self.chatViewModel = chatViewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Overrides
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Chats"
        navigationController?.navigationBar.prefersLargeTitles = true
        // Customize appearance for slide-in menu
        tableView.backgroundColor = .systemBackground
        
        setupNavigationButtons()
        setupBindings()
    }
    
    // MARK: - UITableView
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return chatListViewModel.chats.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
        cell.textLabel?.text = chatListViewModel.chats[indexPath.row].title
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let chat = chatListViewModel.chats[indexPath.row]
                
        if let delegate = delegate {
            // Use delegate pattern if we have a delegate (inside ContainerViewController)
            delegate.chatListViewController(self, didSelectChat: chat)
        } else if UIDevice.current.userInterfaceIdiom == .pad {
            // For iPad/Split view, show detail view
            let chatVC = ChatViewController(viewModel: chatViewModel)
            chatVC.title = chat.title
            showDetailViewController(chatVC, sender: nil)
        } else {
            // Fallback to push navigation if not in container
            let chatVC = ChatViewController(viewModel: chatViewModel)
            chatVC.title = chat.title
            navigationController?.pushViewController(chatVC, animated: true)
        }
    }
    
    // MARK: - Private
    
    private func setupNavigationButtons() {
        // Add a "New Chat" button
        let newChatButton = UIBarButtonItem(
            image: UIImage(systemName: "square.and.pencil"),
            style: .plain,
            target: self,
            action: #selector(createNewChat)
        )
        navigationItem.rightBarButtonItem = newChatButton
    }
    
    private func setupBindings() {
        chatListViewModel.$chats
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.tableView.reloadData()
            }
            .store(in: &cancellables)
    }
    
    @objc
    private func createNewChat() {
        chatListViewModel.createNewChat()
    }
}
