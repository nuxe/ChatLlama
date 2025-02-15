import Foundation
import Alamofire

struct OllamaRequest: Encodable {
    let model: String
    let prompt: String
}

struct OllamaResponse: Decodable {
    let response: String
}

enum OllamaError: Error {
    case invalidURL
    case networkError(Error)
    case invalidResponse
}

class OllamaAPIService {
    static let shared = OllamaAPIService()
    
    // Default to localhost:11434 - can be configured
    private var baseURL = "http://localhost:11434/api/generate"
    
    private init() {}
    
    func configure(host: String, port: Int) {
        baseURL = "http://\(host):\(port)/api/generate"
    }
    
    func sendMessage(prompt: String) async throws -> String {
        let request = OllamaRequest(model: "llama3.2", prompt: prompt)
        
        return try await withCheckedThrowingContinuation { continuation in
            AF.request(baseURL,
                      method: .post,
                      parameters: request,
                      encoder: JSONParameterEncoder.default)
            .validate()
            .responseDecodable(of: OllamaResponse.self) { response in
                switch response.result {
                case .success(let ollamaResponse):
                    continuation.resume(returning: ollamaResponse.response)
                case .failure(let error):
                    continuation.resume(throwing: OllamaError.networkError(error))
                }
            }
        }
    }
} 
