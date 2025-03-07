//
//  ChatListViewController.swift
//  ChatLlama
//
//  Created by Kush Agrawal on 2/26/25.
//

import UIKit

// Protocol for communicating chat selection
protocol ChatListViewControllerDelegate: AnyObject {
    func chatListViewController(_ controller: ChatListViewController, didSelectChat chatTitle: String)
}

class ChatListViewController: UITableViewController {
    
    let chats = ["Chat 1", "Chat 2", "Chat 3", "Chat 4"]
    weak var delegate: ChatListViewControllerDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Chats"
        navigationController?.navigationBar.prefersLargeTitles = true
        
        // Customize appearance for slide-in menu
        tableView.backgroundColor = .systemBackground
        
        // Add a "New Chat" button
        let newChatButton = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(createNewChat)
        )
        navigationItem.rightBarButtonItem = newChatButton
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return chats.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
        cell.textLabel?.text = chats[indexPath.row]
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let chatTitle = chats[indexPath.row]
        
        if let delegate = delegate {
            // Use delegate pattern if we have a delegate (inside ContainerViewController)
            delegate.chatListViewController(self, didSelectChat: chatTitle)
        } else if UIDevice.current.userInterfaceIdiom == .pad {
            // For iPad/Split view, show detail view
            let chatVC = ChatViewController(viewModel: .init(llmConfig: .shared))
            chatVC.title = chatTitle
            showDetailViewController(chatVC, sender: nil)
        } else {
            // Fallback to push navigation if not in container
            let chatVC = ChatViewController(viewModel: .init(llmConfig: .shared))
            chatVC.title = chatTitle
            navigationController?.pushViewController(chatVC, animated: true)
        }
    }
    
    @objc private func createNewChat() {
        // Implementation for creating a new chat
        // This would typically add a new chat to the data source and refresh the table
        print("Create new chat")
    }
}
