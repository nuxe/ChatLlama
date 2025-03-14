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

    @Published var currentChat: Chat?
    @Published var isLoading: Bool = false
    var chatType: ChatType = .text
    
    private let openAI: OpenAI
    private var cancellables = Set<AnyCancellable>()
    private let llmConfig: LLMConfig
    private let chatStore: ChatStore

    // MARK: - Init
    
    init(llmConfig: LLMConfig = .shared, chatStore: ChatStore) {
        self.llmConfig = llmConfig
        self.chatStore = chatStore
        let configuration = llmConfig.providerConfig
        self.openAI = OpenAI(configuration: configuration)
        setupBindings()
    }

    private func setupBindings() {
        Publishers.CombineLatest(chatStore.$currentChatID, chatStore.$chats)
            .map { currentChatID, chats -> Chat? in
                guard let currentChatID = currentChatID else { return nil }
                return chats.first(where: { $0.id == currentChatID })
            }
            .assign(to: &$currentChat)
    }

    // MARK: - Public

    func sendUserMessage(_ text: String) async throws {
        guard let chat = currentChat else { return }
        // Add user message
        chatStore.addMessage(id: chat.id, kind: .text(text), sender: .user)
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
        guard let chat = currentChat else { return }

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
                chatStore.addMessage(id: chat.id, kind: .text(responseContent), sender: .bot)
            }
        } catch {
            throw error
        }
    }
    
    private func sendImageMessage(_ text: String) async throws {
        guard let chat = currentChat else { return }

        let query = ImagesQuery(prompt: text, n: 1, size: ._256)

        do {
            let imageResult = try await openAI.images(query: query)
            guard let imageURL = URL(string: imageResult.data[0].url ?? "") else { return }
            
            let item = ImageMediaItem.init(url: imageURL, placeholderImage: .init(), size: .init(width: 256, height: 256))
            
            chatStore.addMessage(id: chat.id, kind: .photo(item), sender: .bot)
            
        } catch {
            throw error
        }
    }
} 
