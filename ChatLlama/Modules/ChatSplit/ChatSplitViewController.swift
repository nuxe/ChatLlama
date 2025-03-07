//
//  ChatSplitViewController.swift
//  ChatLlama
//
//  Created by Kush Agrawal on 2/27/25.
//

import UIKit

class ChatSplitViewController: UISplitViewController, UISplitViewControllerDelegate {
    
    let chatViewModel: ChatViewModel
    let chatListViewModel: ChatListViewModel

    // MARK: - Init

    init(chatViewModel: ChatViewModel, chatListViewModel: ChatListViewModel) {
        self.chatViewModel = chatViewModel
        self.chatListViewModel = chatListViewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Overrides

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Create controllers
        let chatListVC = ChatListViewController(chatListViewModel: chatListViewModel, chatViewModel: chatViewModel)
        let chatVC = ChatViewController(viewModel: chatViewModel)
        chatVC.title = "Select a Chat"
        
        // Create navigation controllers
        let navList = UINavigationController(rootViewController: chatListVC)
        let navChat = UINavigationController(rootViewController: chatVC)
        
        // Configure split view
        self.viewControllers = [navList, navChat]
        self.delegate = self
        preferredDisplayMode = .oneBesideSecondary
        
        // Additional customizations for iPad
        presentsWithGesture = true // Allow swipe to show sidebar
//        preferredSplitBehavior = .tile // Keep sidebar visible in landscape
    }
    
    // MARK: - UISplitViewControllerDelegate
    
    func splitViewController(_ svc: UISplitViewController, topColumnForCollapsingToProposedTopColumn proposedTopColumn: UISplitViewController.Column) -> UISplitViewController.Column {
        // Always prefer the secondary (detail) view when collapsing
        return .secondary
    }
}
