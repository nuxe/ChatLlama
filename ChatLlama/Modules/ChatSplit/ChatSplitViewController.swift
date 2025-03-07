//
//  ChatSplitViewController.swift
//  ChatLlama
//
//  Created by Kush Agrawal on 2/27/25.
//

import UIKit

class ChatSplitViewController: UISplitViewController, UISplitViewControllerDelegate {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Create controllers
        let chatListVC = ChatListViewController()
        let chatVC = ChatViewController(viewModel: .init(llmConfig: .shared))
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
