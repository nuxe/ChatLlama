//
//  StorageSettingsViewController.swift
//  ChatLlama
//
//  Created by Kush Agrawal on 3/20/25.
//

import UIKit
import Combine

/// View controller for managing storage settings
final class StorageSettingsViewController: UIViewController {
    
    // MARK: - Properties
    
    private let chatStore: ChatStore
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - UI Components
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        tableView.translatesAutoresizingMaskIntoConstraints = false
        return tableView
    }()
    
    // MARK: - Init
    
    init(chatStore: ChatStore) {
        self.chatStore = chatStore
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupBindings()
    }
    
    // MARK: - Setup
    
    private func setupView() {
        title = "Storage Settings"
        view.backgroundColor = .systemBackground
        
        // Add table view
        view.addSubview(tableView)
        
        // Set constraints
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }
    
    private func setupBindings() {
        // Update table view when persistence strategy changes
        chatStore.$persistenceStrategy
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.tableView.reloadData()
            }
            .store(in: &cancellables)
    }
}

// MARK: - UITableViewDataSource

extension StorageSettingsViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return PersistenceStrategy.allCases.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        
        // Configure cell
        let strategies = PersistenceStrategy.allCases
        let strategy = strategies[indexPath.row]
        
        var config = cell.defaultContentConfiguration()
        config.text = strategy.displayName
        cell.contentConfiguration = config
        
        // Add checkmark if selected
        cell.accessoryType = strategy == chatStore.persistenceStrategy ? .checkmark : .none
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Data Storage"
    }
    
    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return "Choose where to save your chat history. Changes will apply immediately."
    }
}

// MARK: - UITableViewDelegate

extension StorageSettingsViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        // Change persistence strategy
        let strategy = PersistenceStrategy.allCases[indexPath.row]
        chatStore.changePersistenceStrategy(to: strategy)
    }
} 