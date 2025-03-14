//
//  ChatViewModel.swift
//  ChatLlama
//
//  Created by Kush Agrawal on 2/24/25.
//

import Foundation
import OpenAI
import Combine
import MessageKit

@MainActor
class ChatViewModel: ObservableObject {
    
    enum ChatType {
        case image
        case text
    }
    
    // MARK: - Properties

    @Published var chat: Chat?
    @Published var isLoading: Bool = false
    var chatType: ChatType = .text
    
    private let openAI: OpenAI
    private var cancellables = Set<AnyCancellable>()
    private let llmConfig: LLMConfig
    private let chatManager: ChatManager
    private var currentChatID: UUID?
    // MARK: - Init
    
    init(llmConfig: LLMConfig = .shared, chatManager: ChatManager) {
        self.llmConfig = llmConfig
        self.chatManager = chatManager
        let configuration = llmConfig.providerConfig
        self.openAI = OpenAI(configuration: configuration)
        setupBindings()
    }

    private func setupBindings() {
        chatManager
            .$currentChatID
            .sink { [weak self] currentChatID in
                guard let self else { return }
                self.currentChatID = currentChatID
                self.updateCurrentChat()
            }
            .store(in: &cancellables)
        
        chatManager
            .$chats
            .sink { [weak self] _ in
                guard let self else { return }
                self.updateCurrentChat()
            }
            .store(in: &cancellables)
    }
    
    private func updateCurrentChat() {
        guard let currentChatID = currentChatID else { return }
        self.chat = chatManager.chats.first(where: {$0.id == currentChatID })
    }
    
    // MARK: - Public

    func sendUserMessage(_ text: String) async throws {
        guard let currentChatID else { return }
        // Add user message
        chatManager.addMessage(id: currentChatID, kind: .text(text), sender: .user)
        isLoading = true
        
        defer { isLoading = false }
        
        do {
            switch chatType {
            case .image:
                try await sendImageMessage(text)
            case .text:
                try await sendTextMessage(text)
            }
        } catch {
            throw error
        }
    }
    
    // MARK: - Private

    private func sendTextMessage(_ text: String) async throws {
        guard let chat = chat else { return }

        let messageParams: [ChatQuery.ChatCompletionMessageParam] = chat.messages.compactMap { message in
            guard let messageSenderType = message.sender as? Sender else {
                return nil
            }
            switch messageSenderType {
            case .bot:
                return .init(
                    role: .assistant,
                    content: message.content)
            case .user:
                return .init(
                    role: .user,
                    content: message.content)
            }
        }

        let query = ChatQuery(messages: messageParams, model: llmConfig.model)

        do {
            let result = try await openAI.chats(query: query)
            
            if let responseContent = result.choices.first?.message.content?.string {
                chatManager.addMessage(id: chat.id, kind: .text(responseContent), sender: .bot)
            }
        } catch {
            throw error
        }
    }
    
    private func sendImageMessage(_ text: String) async throws {
        guard let chat = chat else { return }

        let query = ImagesQuery(prompt: text, n: 1, size: ._256)

        do {
            let imageResult = try await openAI.images(query: query)
            guard let imageURL = URL(string: imageResult.data[0].url ?? "") else { return }
            
            let item = ImageMediaItem.init(url: imageURL, placeholderImage: .init(), size: .init(width: 256, height: 256))
            
            chatManager.addMessage(id: chat.id, kind: .photo(item), sender: .bot)
        } catch {
            throw error
        }
    }
} 
