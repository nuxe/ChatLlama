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
        
        let chatListVC = ChatListViewController()
        let chatVC = ChatViewController(viewModel: .init(llmConfig: .shared))
        
        let navList = UINavigationController(rootViewController: chatListVC)
        let navChat = UINavigationController(rootViewController: chatVC)
        
        self.viewControllers = [navList, navChat]
        self.delegate = self
        preferredDisplayMode = .oneBesideSecondary
    }
}
