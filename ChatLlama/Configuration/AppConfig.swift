import Foundation
import OpenAI

enum LLMProvider {
    case openAI
    case ollama
}

class AppConfig {
    static let shared = AppConfig(.openAI)
        
    private let provider: LLMProvider
    private init(_ provider: LLMProvider) {
        self.provider = provider
    }
    
    var providerConfig: OpenAI.Configuration {
        switch provider {
        case .openAI:
            let apiKey = Bundle.main.object(forInfoDictionaryKey: "OPENAI_API_KEY") as? String ?? ""
            return .init(token: apiKey)
        case .ollama:
            return .init(
                token: "ollama",
                host: "localhost",
                port: 11434,
                scheme: "http"
            )
        }
    }
    
    var model: String {
        switch provider {
        case .ollama:
            return "llama3.2"
        case .openAI:
            return Model.gpt4_o_mini
        }
    }
}

