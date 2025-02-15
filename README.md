# ChatLlama

ChatLlama is a native iOS application that provides a ChatGPT-style interface for interacting with locally hosted Ollama models. The app features a modern, responsive chat interface built with UIKit and MessageKit.

## Features

- 🎯 Clean, intuitive chat interface
- 💬 Real-time streaming responses from Ollama
- 🎨 Beautiful message bubbles with user/bot differentiation
- 🔄 Asynchronous message handling
- 🌐 Local network communication with Ollama
- ⚡️ Fast and responsive UI

## Requirements

- iOS 14.0+
- Xcode 14.0+
- Mac running Ollama (for the language model backend)
- Local network access between iOS device and Mac

## Installation

1. Clone the repository:
```bash
git clone https://github.com/yourusername/ChatLlama.git
cd ChatLlama
```

2. Open the project in Xcode:
```bash
open ChatLlama.xcodeproj
```

3. Install dependencies using Swift Package Manager:
   - MessageKit (4.0.0+)
   - Alamofire (5.0.0+)

   The dependencies should be automatically resolved when you open the project in Xcode.

4. Build and run the project (⌘+R)

## Setup Ollama

1. Install Ollama on your Mac by following the instructions at [Ollama's website](https://ollama.ai)

2. Pull the Llama model:
```bash
ollama pull llama2
```

3. Start the Ollama server:
```bash
ollama serve
```

## Configuration

By default, ChatLlama attempts to connect to Ollama at `http://localhost:11434`. If you need to use a different host or port:

1. Open `OllamaAPIService.swift`
2. Modify the `baseURL` or use the `configure(host:port:)` method to set your custom endpoint

## Network Permissions

The app requires local network access to communicate with Ollama. These permissions are already configured in the Info.plist file:

- `NSLocalNetworkUsageDescription`: For local network access
- `NSAppTransportSecurity`: Allows local networking

## Architecture

ChatLlama follows a clean architecture pattern:

- **Models**: Message and Sender types for chat data
- **Networking**: OllamaAPIService for API communication
- **ViewControllers**: ChatViewController for UI and user interaction
- **Delegates**: App and Scene delegates for lifecycle management

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details

## Acknowledgments

- [MessageKit](https://github.com/MessageKit/MessageKit) for the chat UI components
- [Alamofire](https://github.com/Alamofire/Alamofire) for networking
- [Ollama](https://ollama.ai) for the local LLM infrastructure 