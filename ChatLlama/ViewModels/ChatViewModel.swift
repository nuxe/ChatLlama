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
    private let appConfig: AppConfig
    
    init(appConfig: AppConfig = .shared) {
        self.appConfig = appConfig
        
        let configuration = appConfig.providerConfig
        self.openAI = OpenAI(configuration: configuration)

        // Add initial welcome message
        let welcomeMessage = "Hello! I'm ChatLlama. How can I help you today?"
        addMessage(content: welcomeMessage, sender: .bot)
    }
    
    func addMessage(content: String, sender: Sender) {
        let message = Message(content: content, sender: sender)
        messages.append(message)
    }
    
    func sendMessage(_ text: String) async throws {
        // Add user message
        addMessage(content: text, sender: .user)
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
        let query = ChatQuery(messages: messageParams, model: appConfig.model)
        
        do {
            let result = try await openAI.chats(query: query)
            
            if let responseContent = result.choices.first?.message.content?.string {
                addMessage(content: responseContent, sender: .bot)
            }
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
