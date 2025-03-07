//
//  ChatMenuViewController.swift
//  ChatLlama
//
//  Created by Kush Agrawal on 2/27/25.
//

import UIKit

class ChatMenuViewController: UIViewController {
    
    // MARK: - Properties
    
    private let chatListWidth: CGFloat = 280
    private var isChatListVisible = false
    
    private lazy var chatListViewController: ChatListViewController = {
        let controller = ChatListViewController(chatListViewModel: chatListViewModel, chatViewModel: chatViewModel)
        return controller
    }()
    
    private lazy var chatViewController: ChatViewController = {
        let controller = ChatViewController(viewModel: chatViewModel)
        return controller
    }()
    
    private lazy var chatNavigationController: UINavigationController = {
        let navigationController = UINavigationController(rootViewController: chatViewController)
        return navigationController
    }()
    
    private lazy var dimView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        view.alpha = 0
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleDimViewTap))
        view.addGestureRecognizer(tapGesture)
        
        return view
    }()
    
    private let chatViewModel: ChatViewModel
    private let chatListViewModel: ChatListViewModel

    // MARK: - Init

    init(chatViewModel: ChatViewModel,
         chatListViewModel: ChatListViewModel) {
        self.chatViewModel = chatViewModel
        self.chatListViewModel = chatListViewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupChildViewControllers()
        setupNavigationButtons()
        
        // Add edge swipe gesture to show menu
        let edgeSwipe = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(handleEdgeSwipe(_:)))
        edgeSwipe.edges = .left
        view.addGestureRecognizer(edgeSwipe)
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        coordinator.animate(alongsideTransition: { _ in
            // Update frames for rotation
            self.chatNavigationController.view.frame = CGRect(origin: .zero, size: size)
            self.dimView.frame = CGRect(origin: .zero, size: size)
            
            let chatListFrame = CGRect(
                x: self.isChatListVisible ? 0 : -self.chatListWidth,
                y: 0,
                width: self.chatListWidth,
                height: size.height
            )
            self.chatListViewController.view.frame = chatListFrame
        })
    }
    
    // MARK: - Private
    
    private func setupChildViewControllers() {
        // Add the chat view controller (main content)
        addChild(chatNavigationController)
        view.addSubview(chatNavigationController.view)
        chatNavigationController.view.frame = view.bounds
        chatNavigationController.didMove(toParent: self)
        
        // Add dim view (initially hidden)
        view.addSubview(dimView)
        dimView.frame = view.bounds
        
        // Add the chat list view controller (off-screen initially)
        addChild(chatListViewController)
        view.addSubview(chatListViewController.view)
        chatListViewController.view.frame = CGRect(x: -chatListWidth, y: 0, width: chatListWidth, height: view.bounds.height)
        chatListViewController.didMove(toParent: self)
        
        // Configure chat list view
        chatListViewController.delegate = self
    }
    
    @objc private func createNewChat() {
        chatListViewModel.createNewChat()
    }
    
    private func setupNavigationButtons() {
        let menuButton = UIBarButtonItem(
            image: UIImage(systemName: "line.horizontal.3"),
            style: .plain,
            target: self,
            action: #selector(toggleChatList)
        )
        chatViewController.navigationItem.leftBarButtonItem = menuButton
        
        let newChatButton = UIBarButtonItem(
            image: UIImage(systemName: "square.and.pencil"),
            style: .plain,
            target: self,
            action: #selector(createNewChat)
        )
        chatViewController.navigationItem.rightBarButtonItem = newChatButton
    }
    
    @objc
    private func toggleChatList() {
        if isChatListVisible {
            hideChatList()
        } else {
            showChatList()
        }
    }
    
    @objc
    private func handleDimViewTap() {
        hideChatList()
    }
    
    @objc
    private func handleEdgeSwipe(_ gesture: UIScreenEdgePanGestureRecognizer) {
        if gesture.state == .began {
            showChatList()
        }
    }
    
    private func showChatList() {
        // Animate chat list in
        UIView.animate(withDuration: 0.3) {
            self.chatListViewController.view.frame.origin.x = 0
            self.dimView.alpha = 1
        }
        isChatListVisible = true
    }
    
    private func hideChatList() {
        // Animate chat list out
        UIView.animate(withDuration: 0.3) {
            self.chatListViewController.view.frame.origin.x = -self.chatListWidth
            self.dimView.alpha = 0
        }
        isChatListVisible = false
    }
}

// MARK: - ChatListViewControllerDelegate
extension ChatMenuViewController: ChatListViewControllerDelegate {
    func chatListViewController(_ controller: ChatListViewController, didSelectChat chatTitle: String) {
        // Update the chat view with the selected chat
        chatViewController.title = chatTitle
        
        // Hide the chat list after selection
        hideChatList()
    }
} 
