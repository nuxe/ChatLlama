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
    @Published private(set) var messages: [Message] = []
    @Published var isLoading: Bool = false
    
    private let openAI: OpenAI
    private var cancellables = Set<AnyCancellable>()
    private let llmConfig: LLMConfig
    
    init(llmConfig: LLMConfig = .shared) {
        self.llmConfig = llmConfig
        
        let configuration = llmConfig.providerConfig
        self.openAI = OpenAI(configuration: configuration)

        // Add initial welcome message
        let welcomeMessage = "Hello! I'm ChatLlama. How can I help you today?"
        addMessage(kind: .text(welcomeMessage), sender: .bot)
    }

    // Generic
    
    func addMessage(kind: MessageKind, sender: Sender) {
        let message = Message.init(kind: kind, sender: sender)
        messages.append(message)
    }
    
    // Text messages

    func sendUserMessage(_ text: String) async throws {
        // Add user message
        addMessage(kind: .text(text), sender: .user)
        isLoading = true
        
        defer { isLoading = false }
        
        let messageParams: [ChatQuery.ChatCompletionMessageParam] = messages.compactMap { message in
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
        
        // Create chat query
        let query = ChatQuery(messages: messageParams, model: llmConfig.model)
        
        do {
            let result = try await openAI.chats(query: query)
            
            if let responseContent = result.choices.first?.message.content?.string {
                addMessage(kind: .text(responseContent), sender: .bot)
            }
        } catch {
            throw error
        }
    }
    
    // Images
    
    func sendImageMessage() async throws {
        let query = ImagesQuery(prompt: "", n: 1, size: ._256)
        do {
            let imageResult = try await openAI.images(query: query)
            guard let imageURL = URL(string: imageResult.data[0].url ?? "") else { return }
            
            let item = ImageMediaItem.init(url: imageURL, placeholderImage: .init(), size: .init(width: 256, height: 256))
            addMessage(kind: .photo(item), sender: .bot)

            // Add revised prompt here
        } catch {
            throw error
        }
    }
    
    var messageCount: Int {
        messages.count
    }
    
    func getMessage(at index: Int) -> Message {
        messages[index]
    }
} 

import UIKit

struct ImageMediaItem: MediaItem {
    var url: URL?
    
    var image: UIImage?
    
    var placeholderImage: UIImage
    
    var size: CGSize
}
