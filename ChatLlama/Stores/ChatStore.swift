//
//  ChatStore.swift
//  ChatLlama
//
//  Created by Kush Agrawal on 3/7/25.
//

import Foundation
import MessageKit
import Combine
import CoreData
import UIKit

// MARK: - Debug Logging

/// Simple debugging helper for persistence operations
fileprivate func logDebug(_ message: String) {
    print("📦 [Persistence] \(message)")
}

// MARK: - Persistence protocols and enums
// These will be replaced by proper imports once the build system is set up

/// Enum representing available persistence strategies
enum PersistenceStrategy: CaseIterable {
    /// Store data using JSON files (default)
    case fileSystem
    
    /// Human-readable name for the strategy
    var displayName: String {
        switch self {
        case .fileSystem:
            return "File System"
        }
    }
    
    /// All available cases
    static var allCases: [PersistenceStrategy] {
        return [.fileSystem]
    }
}

/// Protocol defining chat persistence operations
protocol ChatPersistenceManager {
    /// Save chats to persistent storage
    func saveChats(_ chats: [Chat]) async throws
    
    /// Load chats from persistent storage
    func loadChats() async throws -> [Chat]
    
    /// Delete all chats from persistent storage
    func deleteAllChats() async throws
}

// CoreData persistence manager
class CoreDataPersistenceManager: ChatPersistenceManager {
    private let container: NSPersistentContainer
    
    init() {
        logDebug("Initializing Core Data persistence manager")
        // Important: Make sure the name matches exactly the .xcdatamodeld file name
        container = NSPersistentContainer(name: "ChatLlamaDataModel") 
        container.loadPersistentStores { description, error in
            if let error = error {
                logDebug("❌ Core Data loading error: \(error)")
                logDebug("❌ Error details: \(error.localizedDescription)")
                // Print call stack to help debug
                let nsError = error as NSError
                logDebug("❌ Error domain: \(nsError.domain), code: \(nsError.code)")
                if let failureReason = nsError.userInfo["NSLocalizedFailureReason"] as? String {
                    logDebug("❌ Failure reason: \(failureReason)")
                }
            } else {
                logDebug("✅ Core Data store loaded successfully: \(description)")
                // Print the URL of the store for debugging
                if let url = description.url {
                    logDebug("Store URL: \(url)")
                }
            }
        }
    }
    
    func saveChats(_ chats: [Chat]) async throws {
        logDebug("Saving \(chats.count) chats to Core Data")
        let context = container.viewContext
        
        // Clear existing chats
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "CDChat")
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        try context.execute(deleteRequest)
        
        // Add new chats
        for chat in chats {
            let cdChat = NSEntityDescription.insertNewObject(forEntityName: "CDChat", into: context) as! NSManagedObject
            cdChat.setValue(chat.id, forKey: "id")
            cdChat.setValue(chat.created, forKey: "created")
            
            logDebug("Saving chat \(chat.id) with \(chat.messages.count) messages")
            
            for message in chat.messages {
                let cdMessage = NSEntityDescription.insertNewObject(forEntityName: "CDMessage", into: context) as! NSManagedObject
                cdMessage.setValue(message.messageId, forKey: "id")
                cdMessage.setValue(message.sentDate, forKey: "sentDate")
                
                // Handle content type
                switch message.kind {
                case .text(let text):
                    cdMessage.setValue(text, forKey: "content")
                    cdMessage.setValue(false, forKey: "isImage")
                case .photo(let item):
                    cdMessage.setValue("Image", forKey: "content")
                    cdMessage.setValue(true, forKey: "isImage")
                    cdMessage.setValue(item.url, forKey: "imageURL")
                default:
                    cdMessage.setValue(message.content, forKey: "content")
                    cdMessage.setValue(false, forKey: "isImage")
                }
                
                // Set sender type
                if let sender = message.sender as? Sender {
                    cdMessage.setValue(sender == .user ? "user" : "bot", forKey: "senderType")
                }
                
                cdMessage.setValue(cdChat, forKey: "chat")
            }
        }
        
        do {
            try context.save()
            logDebug("✅ Successfully saved chats to Core Data")
        } catch {
            logDebug("❌ Failed to save Core Data context: \(error)")
            throw error
        }
    }
    
    func loadChats() async throws -> [Chat] {
        logDebug("Loading chats from Core Data")
        let context = container.viewContext
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "CDChat")
        
        do {
            let cdChats = try context.fetch(fetchRequest)
            logDebug("Found \(cdChats.count) chats in Core Data")
            
            if cdChats.isEmpty {
                logDebug("No chats found in Core Data")
                return []
            }
            
            return try cdChats.compactMap { cdChat -> Chat? in
                guard let id = cdChat.value(forKey: "id") as? UUID,
                      let created = cdChat.value(forKey: "created") as? Date else {
                    logDebug("❌ Missing required chat attributes for chat")
                    return nil
                }
                
                // Get messages
                let messagesFetchRequest = NSFetchRequest<NSManagedObject>(entityName: "CDMessage")
                messagesFetchRequest.predicate = NSPredicate(format: "chat = %@", cdChat)
                let cdMessages = try context.fetch(messagesFetchRequest)
                logDebug("Found \(cdMessages.count) messages for chat \(id)")
                
                // Create messages
                let messages = cdMessages.compactMap { cdMessage -> Message? in
                    guard let messageId = cdMessage.value(forKey: "id") as? String,
                          let sentDate = cdMessage.value(forKey: "sentDate") as? Date,
                          let content = cdMessage.value(forKey: "content") as? String,
                          let senderTypeString = cdMessage.value(forKey: "senderType") as? String else {
                        logDebug("❌ Missing required message attributes")
                        return nil
                    }
                    
                    let sender: Sender = senderTypeString == "user" ? .user : .bot
                    
                    let isImage = cdMessage.value(forKey: "isImage") as? Bool ?? false
                    let imageURL = cdMessage.value(forKey: "imageURL") as? URL
                    
                    let kind: MessageKind
                    if isImage, let url = imageURL {
                        let mediaItem = ImageMediaItem(
                            url: url, 
                            image: nil,
                            placeholderImage: UIImage(),
                            size: CGSize(width: 256, height: 256)
                        )
                        kind = .photo(mediaItem)
                    } else {
                        kind = .text(content)
                    }
                    
                    return Message(id: messageId, kind: kind, sender: sender, sentDate: sentDate)
                }
                
                return Chat(id: id, messages: messages, created: created)
            }
        } catch {
            logDebug("❌ Error loading chats from Core Data: \(error)")
            throw error
        }
    }
    
    func deleteAllChats() async throws {
        logDebug("Deleting all chats from Core Data")
        let context = container.viewContext
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "CDChat")
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        
        do {
            try context.execute(deleteRequest)
            try context.save()
            logDebug("✅ Successfully deleted all chats from Core Data")
        } catch {
            logDebug("❌ Error deleting chats from Core Data: \(error)")
            throw error
        }
    }
}

// File-based persistence manager
class FilePersistenceManager: ChatPersistenceManager {
    private let fileManager = FileManager.default
    private let filename = "chats.json"
    
    private var documentsDirectory: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    private var fileURL: URL {
        documentsDirectory.appendingPathComponent(filename)
    }
    
    init() {
        logDebug("Initializing File System persistence manager")
        logDebug("File path: \(fileURL.path)")
        
        // Check permissions on documents directory
        checkDirectoryPermissions()
        
        // Check if file exists at initialization
        if fileManager.fileExists(atPath: fileURL.path) {
            logDebug("✅ Chat file exists at path")
            // Check if file is readable
            if let attributes = try? fileManager.attributesOfItem(atPath: fileURL.path),
               let fileSize = attributes[.size] as? UInt64 {
                logDebug("File size: \(fileSize) bytes")
                
                // Check if file is valid by attempting to read it
                do {
                    let testData = try Data(contentsOf: fileURL, options: .mappedIfSafe)
                    if testData.count <= 4 {
                        logDebug("⚠️ Warning: Existing file appears to be an empty array. Will attempt to find backup.")
                        findAndRestoreBackup()
                    }
                } catch {
                    logDebug("⚠️ Warning: Could not read chat file: \(error)")
                }
            }
        } else {
            logDebug("⚠️ No chat file exists yet at path")
            // Try to find a backup file
            findAndRestoreBackup()
        }
    }
    
    private func checkDirectoryPermissions() {
        // Check directory permissions
        let directoryPath = documentsDirectory.path
        
        if fileManager.isWritableFile(atPath: directoryPath) {
            logDebug("✅ Documents directory is writable: \(directoryPath)")
        } else {
            logDebug("❌ Documents directory is NOT writable: \(directoryPath)")
        }
        
        if fileManager.isReadableFile(atPath: directoryPath) {
            logDebug("✅ Documents directory is readable: \(directoryPath)")
        } else {
            logDebug("❌ Documents directory is NOT readable: \(directoryPath)")
        }
        
        // Try creating a test file to confirm write permissions
        let testFile = documentsDirectory.appendingPathComponent("test_permissions.txt")
        do {
            try "Test data".write(to: testFile, atomically: true, encoding: .utf8)
            logDebug("✅ Successfully wrote test file")
            try fileManager.removeItem(at: testFile)
            logDebug("✅ Successfully removed test file")
        } catch {
            logDebug("❌ Failed permission test: \(error)")
        }
    }
    
    /// Attempts to find and restore backup files from different app installations
    private func findAndRestoreBackup() {
        logDebug("Attempting to find backup files from previous installations")
        
        // Get the parent container directory
        if let containerDir = fileURL.deletingLastPathComponent().deletingLastPathComponent().path as String? {
            // Look for other app containers
            do {
                let containers = try fileManager.contentsOfDirectory(atPath: containerDir)
                for container in containers {
                    // Full path to another potential container
                    let otherContainerPath = (containerDir as NSString).appendingPathComponent(container)
                    
                    // Check if it's a directory
                    var isDir: ObjCBool = false
                    if fileManager.fileExists(atPath: otherContainerPath, isDirectory: &isDir), isDir.boolValue {
                        // Check for Documents/chats.json in this container
                        let potentialChatFile = (otherContainerPath as NSString).appendingPathComponent("Documents/\(filename)")
                        
                        if fileManager.fileExists(atPath: potentialChatFile) {
                            if let attrs = try? fileManager.attributesOfItem(atPath: potentialChatFile),
                               let size = attrs[.size] as? UInt64, size > 20 { // Ensure it's not an empty file
                                logDebug("✅ Found potential backup at: \(potentialChatFile) (Size: \(size) bytes)")
                                
                                do {
                                    // Try to read and validate the file
                                    let backupData = try Data(contentsOf: URL(fileURLWithPath: potentialChatFile))
                                    if backupData.count > 20 { // Just ensure it's not empty
                                        // Copy it to our path
                                        try backupData.write(to: fileURL)
                                        logDebug("✅ Successfully restored backup file to: \(fileURL.path)")
                                        return
                                    }
                                } catch {
                                    logDebug("❌ Could not restore backup: \(error)")
                                }
                            }
                        }
                    }
                }
                logDebug("No valid backup files found")
            } catch {
                logDebug("❌ Error searching for backups: \(error)")
            }
        }
    }
    
    func saveChats(_ chats: [Chat]) async throws {
        logDebug("Saving \(chats.count) chats to file system")
        
        // Ensure directory exists
        if !fileManager.fileExists(atPath: documentsDirectory.path) {
            do {
                try fileManager.createDirectory(at: documentsDirectory, withIntermediateDirectories: true)
                logDebug("✅ Created documents directory: \(documentsDirectory.path)")
            } catch {
                logDebug("❌ Failed to create documents directory: \(error)")
                throw error
            }
        }
        
        // Convert to simple dictionaries for JSON
        let jsonChats = chats.map { chat -> [String: Any] in
            let messages = chat.messages.map { message -> [String: Any] in
                var messageDict: [String: Any] = [
                    "id": message.messageId,
                    "sentDate": message.sentDate.timeIntervalSince1970,
                    "senderType": (message.sender as? Sender) == .user ? "user" : "bot"
                ]
                
                switch message.kind {
                case .text(let text):
                    messageDict["content"] = text
                    messageDict["isImage"] = false
                case .photo(let item):
                    messageDict["content"] = "Image"
                    messageDict["isImage"] = true
                    messageDict["imageURL"] = item.url?.absoluteString
                default:
                    messageDict["content"] = message.content
                    messageDict["isImage"] = false
                }
                
                return messageDict
            }
            
            return [
                "id": chat.id.uuidString,
                "created": chat.created.timeIntervalSince1970,
                "messages": messages
            ]
        }
        
        do {
            // Make sure we're saving a valid array, not an empty array or nil
            if jsonChats.isEmpty {
                logDebug("Warning: Saving an empty array of chats")
            }
            
            let data = try JSONSerialization.data(withJSONObject: jsonChats, options: .prettyPrinted)
            
            // Ensure we have valid JSON
            if data.count <= 4 { // Just "[]" or less
                logDebug("⚠️ Warning: Generated JSON data is very small (\(data.count) bytes)")
                if let str = String(data: data, encoding: .utf8) {
                    logDebug("JSON content: \(str)")
                }
            }
            
            // Use atomic write for data safety
            try data.write(to: fileURL, options: .atomic)
            
            // Verify write success
            if fileManager.fileExists(atPath: fileURL.path) {
                if let attributes = try? fileManager.attributesOfItem(atPath: fileURL.path),
                   let fileSize = attributes[.size] as? UInt64 {
                    logDebug("✅ Successfully saved chats to file: \(fileURL.path) (Size: \(fileSize) bytes)")
                } else {
                    logDebug("✅ Successfully saved chats to file: \(fileURL.path)")
                }
            } else {
                logDebug("❌ File does not exist after write attempt!")
            }
        } catch {
            logDebug("❌ Error saving chats to file: \(error)")
            throw error
        }
    }
    
    func loadChats() async throws -> [Chat] {
        if !fileManager.fileExists(atPath: fileURL.path) {
            logDebug("No chat file exists at \(fileURL.path)")
            return []
        }
        
        logDebug("Loading chats from file system")
        
        do {
            let data = try Data(contentsOf: fileURL)
            logDebug("Read \(data.count) bytes from file")
            
            // Log the raw JSON for debugging
            if let jsonString = String(data: data, encoding: .utf8) {
                logDebug("Raw JSON content (first 100 chars): \(String(jsonString.prefix(100)))")
            }
            
            let jsonObject = try JSONSerialization.jsonObject(with: data)
            
            // Explicitly check the type and provide better error handling
            guard let jsonArray = jsonObject as? [[String: Any]] else {
                // If parsing succeeded but we didn't get the expected array, log what we did get
                logDebug("❌ JSON parsing succeeded but result is not an array of dictionaries")
                logDebug("Instead got: \(type(of: jsonObject))")
                
                if let dict = jsonObject as? [String: Any] {
                    logDebug("Got a dictionary instead of an array. Keys: \(dict.keys.joined(separator: ", "))")
                } else if let array = jsonObject as? [Any], !array.isEmpty {
                    logDebug("Got an array but first element is type: \(type(of: array[0]))")
                }
                
                // Return empty to trigger new chat creation
                return []
            }
            
            logDebug("Found \(jsonArray.count) chats in file")
            
            let chats = jsonArray.compactMap { chatDict -> Chat? in
                guard let idString = chatDict["id"] as? String,
                      let id = UUID(uuidString: idString),
                      let createdTimestamp = chatDict["created"] as? TimeInterval,
                      let messagesArray = chatDict["messages"] as? [[String: Any]] else {
                    logDebug("❌ Missing required chat attributes in chat dictionary")
                    if let id = chatDict["id"] {
                        logDebug("ID exists but is type: \(type(of: id))")
                    } else {
                        logDebug("ID key missing from chat dict. Available keys: \(chatDict.keys.joined(separator: ", "))")
                    }
                    return nil
                }
                
                let created = Date(timeIntervalSince1970: createdTimestamp)
                
                let messages = messagesArray.compactMap { messageDict -> Message? in
                    guard let id = messageDict["id"] as? String,
                          let sentDateTimestamp = messageDict["sentDate"] as? TimeInterval,
                          let content = messageDict["content"] as? String,
                          let senderTypeString = messageDict["senderType"] as? String,
                          let isImage = messageDict["isImage"] as? Bool else {
                        logDebug("❌ Missing required message attributes in message")
                        logDebug("Available keys: \(messageDict.keys.joined(separator: ", "))")
                        return nil
                    }
                    
                    let sentDate = Date(timeIntervalSince1970: sentDateTimestamp)
                    let sender: Sender = senderTypeString == "user" ? .user : .bot
                    
                    let kind: MessageKind
                    if isImage, 
                       let urlString = messageDict["imageURL"] as? String,
                       let url = URL(string: urlString) {
                        let mediaItem = ImageMediaItem(
                            url: url, 
                            image: nil,
                            placeholderImage: UIImage(),
                            size: CGSize(width: 256, height: 256)
                        )
                        kind = .photo(mediaItem)
                    } else {
                        kind = .text(content)
                    }
                    
                    return Message(id: id, kind: kind, sender: sender, sentDate: sentDate)
                }
                
                logDebug("Loaded chat \(id) with \(messages.count) messages")
                return Chat(id: id, messages: messages, created: created)
            }
            
            logDebug("✅ Successfully loaded \(chats.count) chats from file")
            return chats
        } catch let error as NSError {
            logDebug("❌ Error loading chats from file: \(error.localizedDescription)")
            logDebug("❌ Error domain: \(error.domain), code: \(error.code)")
            
            // Check specific case of data format issues
            if error.domain == NSCocoaErrorDomain && error.code == 3840 {
                logDebug("❌ JSON parsing error - invalid format")
            }
            
            throw error
        }
    }
    
    func deleteAllChats() async throws {
        if !fileManager.fileExists(atPath: fileURL.path) {
            logDebug("No chat file to delete at \(fileURL.path)")
            return
        }
        
        logDebug("Deleting chat file from file system")
        
        do {
            try fileManager.removeItem(at: fileURL)
            logDebug("✅ Successfully deleted chat file")
        } catch {
            logDebug("❌ Error deleting chat file: \(error)")
            throw error
        }
    }
}

// Factory class for persistence managers
class PersistenceFactory {
    static let shared = PersistenceFactory()
    
    private init() {}
    
    func createPersistenceManager() -> ChatPersistenceManager {
        createPersistenceManager(strategy: .fileSystem)
    }
    
    func createPersistenceManager(strategy: PersistenceStrategy) -> ChatPersistenceManager {
        logDebug("Creating persistence manager for strategy: \(strategy.displayName)")
        // Only file system persistence is supported for now
        return FilePersistenceManager()
    }
}

// MARK: - ChatStore implementation

class ChatStore: ObservableObject {
    
    static let shared = ChatStore()
    
    @Published var chats: [Chat] = []
    @Published var currentChatID: UUID?
    @Published var persistenceStrategy: PersistenceStrategy = .fileSystem
    
    private var persistenceManager: ChatPersistenceManager
    private var autoSaveSubject = PassthroughSubject<Void, Never>()
    private var cancellables = Set<AnyCancellable>()
    
    init(persistenceManager: ChatPersistenceManager? = nil) {
        logDebug("Initializing ChatStore")
        // Use provided persistence manager or create one from factory
        self.persistenceManager = persistenceManager ?? PersistenceFactory.shared.createPersistenceManager()
        
        // First load existing chats
        loadChats()
        
        // Then set up other bindings that might trigger saves
        setupAutoSave()
        setupAppLifecycleHandling()
        
        // Set up persistence strategy binding last, since it can trigger a save
        setupPersistenceStrategyBinding()
    }
    
    // MARK: - Lifecycle handling
    
    private func setupAppLifecycleHandling() {
        // Listen for app entering foreground
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
        
        // Listen for app becoming active
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
        
        // Listen for app entering background
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        
        logDebug("Set up app lifecycle handlers")
    }
    
    @objc private func appWillEnterForeground() {
        logDebug("App will enter foreground - reloading chats")
        loadChats()
    }
    
    @objc private func appDidBecomeActive() {
        logDebug("App did become active")
    }
    
    @objc private func appDidEnterBackground() {
        logDebug("App entering background - forcing immediate save")
        // Force immediate save without debounce when app goes to background
        saveChats(immediate: true)
    }
    
    // MARK: - Public methods
    
    func addMessage(id: UUID, kind: MessageKind, sender: Sender) {
        guard let chatIndex = getChatIndex(id) else { return }
        var chat = chats[chatIndex]
        chat.addMessage(kind: kind, sender: sender)
        chats[chatIndex] = chat
        
        logDebug("Added message to chat \(id), triggering save")
        // Trigger auto-save
        autoSaveSubject.send()
    }

    func createNewChat() {
        var chat = Chat(messages: [], created: Date())

        let welcomeMessage = "Hello! I'm ChatLlama. How can I help you today?"
        chat.addMessage(kind: .text(welcomeMessage), sender: .bot)

        chats.append(chat)
        currentChatID = chat.id
        
        logDebug("Created new chat with ID \(chat.id), triggering save")
        // Trigger auto-save
        autoSaveSubject.send()
    }
    
    func deleteChat(id: UUID) {
        guard let index = getChatIndex(id) else { return }
        chats.remove(at: index)
        
        // If we deleted the current chat, select another one
        if currentChatID == id {
            currentChatID = chats.first?.id
        }
        
        logDebug("Deleted chat \(id), triggering save")
        // Trigger auto-save
        autoSaveSubject.send()
    }
    
    func getChatIndex(_ id: UUID) -> Int? {
        return chats.firstIndex(where: { chat in
            chat.id == id
        })
    }
    
    /// Change the persistence strategy
    func changePersistenceStrategy(to strategy: PersistenceStrategy) {
        logDebug("Changing persistence strategy to \(strategy.displayName)")
        persistenceStrategy = strategy
    }
    
    // MARK: - Private methods
    
    private func setupAutoSave() {
        // Debounce save operations to avoid excessive disk writes
        autoSaveSubject
            .debounce(for: .seconds(1.0), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.saveChats()
            }
            .store(in: &cancellables)
    }
    
    private func setupPersistenceStrategyBinding() {
        // When persistence strategy changes, update the persistence manager
        $persistenceStrategy
            .sink { [weak self] strategy in
                self?.updatePersistenceManager(for: strategy)
            }
            .store(in: &cancellables)
    }
    
    private func updatePersistenceManager(for strategy: PersistenceStrategy) {
        logDebug("Updating persistence manager for strategy: \(strategy.displayName)")
        // Create a new persistence manager for the strategy
        let newManager = PersistenceFactory.shared.createPersistenceManager(strategy: strategy)
        
        // Save current chats only if we have any
        Task {
            do {
                // Only save if we have chats to avoid overwriting with empty array
                if !self.chats.isEmpty {
                    logDebug("Saving \(self.chats.count) chats to new persistence manager")
                    try await newManager.saveChats(self.chats)
                } else {
                    logDebug("No chats to save when switching persistence managers")
                    // Try to load chats from the new manager instead
                    let loadedChats = try await newManager.loadChats()
                    if !loadedChats.isEmpty {
                        logDebug("Loaded \(loadedChats.count) chats from new persistence manager")
                        await MainActor.run {
                            self.chats = loadedChats
                            self.currentChatID = loadedChats.first?.id
                        }
                    }
                }
                
                // Update the manager
                self.persistenceManager = newManager
                
                logDebug("Successfully switched to \(strategy.displayName) persistence")
            } catch {
                logDebug("❌ Error switching persistence strategy: \(error)")
            }
        }
    }
    
    private func saveChats(immediate: Bool = false) {
        logDebug("Saving \(chats.count) chats to persistence" + (immediate ? " (immediate)" : ""))
        // Keep a local copy of chats to prevent race conditions
        let chatsToSave = self.chats
        
        Task {
            do {
                try await persistenceManager.saveChats(chatsToSave)
                logDebug("Successfully saved \(chatsToSave.count) chats")
                
                // Verify file exists after save
                if let filePersistence = persistenceManager as? FilePersistenceManager {
                    logDebug("Checking if file was saved correctly")
                    // Verification handled in FilePersistenceManager now
                }
            } catch {
                logDebug("❌ Error saving chats: \(error.localizedDescription)")
                logDebug("❌ Error details: \(error)")
            }
        }
    }
    
    private func loadChats() {
        logDebug("Loading chats from persistence")
        Task { @MainActor in
            do {
                let loadedChats = try await persistenceManager.loadChats()
                logDebug("Loaded \(loadedChats.count) chats from persistence")
                
                // Only create a new chat if we don't have any
                if loadedChats.isEmpty {
                    logDebug("No chats found, creating new chat")
                    createNewChat()
                } else {
                    // Ensure we're updating on the main thread
                    DispatchQueue.main.async { [weak self] in
                        guard let self = self else { return }
                        self.chats = loadedChats
                        self.currentChatID = loadedChats.first?.id
                        logDebug("Set current chat ID to \(String(describing: loadedChats.first?.id))")
                    }
                }
            } catch {
                logDebug("❌ Error loading chats: \(error)")
                // Create a new chat if loading fails
                createNewChat()
            }
        }
    }
} 
