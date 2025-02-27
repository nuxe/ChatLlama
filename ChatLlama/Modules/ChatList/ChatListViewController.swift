//
//  ChatListViewController.swift
//  ChatLlama
//
//  Created by Kush Agrawal on 2/26/25.
//

import UIKit


class ChatListViewController: UITableViewController {
    
    let chats = ["Chat 1", "Chat 2", "Chat 3", "Chat 4"]

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Chats"
        navigationController?.navigationBar.prefersLargeTitles = true
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
        let chatVC = ChatViewController(viewModel: .init(llmConfig: .shared))
        chatVC.title = chats[indexPath.row]
        
        if UIDevice.current.userInterfaceIdiom == .pad {
            showDetailViewController(chatVC, sender: nil)
        } else {
            navigationController?.pushViewController(chatVC, animated: true)
        }
    }
}
