//
//  ChatViewController.swift
//  ChatLlama
//
//  Created by Kush Agrawal on 2/24/25.
//

import UIKit
import MessageKit
import InputBarAccessoryView
import Combine
import SDWebImage

class ChatViewController: MessagesViewController {
    
    // MARK: - Properties
    
    let viewModel: ChatViewModel
    private var cancellables = Set<AnyCancellable>()
    
    // UI Properties
    private var customTextView: UITextView!
    private var placeholderLabel: UILabel!
    private var voiceButton: UIButton!
    private var sendButton: UIButton!
    private var deepSearchContainer: SelfSizingView!
    private var searchIcon: UIImageView!
    private var searchLabel: UILabel!

    // Custom UIView that sizes itself based on its content
    private class SelfSizingView: UIView {
        override var intrinsicContentSize: CGSize {
            if let stack = subviews.first as? UIStackView {
                let stackSize = stack.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
                // Add padding for leading/trailing (24 points total) and maintain height
                return CGSize(width: stackSize.width + 24, height: stackSize.height)
            }
            return super.intrinsicContentSize
        }
        
        override func layoutSubviews() {
            super.layoutSubviews()
            invalidateIntrinsicContentSize()
        }
    }

    // MARK: - Init

    init(viewModel: ChatViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    @MainActor required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Overrides

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupMessageInputBar()
        setupBindings()
    }

    // MARK: - Private
    
    private func setupUI() {
        title = "Chat Llama"
        navigationController?.navigationBar.prefersLargeTitles = true
        
        // Configure the messages collection view
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        
        // Customize the UI
        messagesCollectionView.backgroundColor = .systemBackground
    }
    
    private func setupMessageInputBar() {
        messageInputBar.delegate = self
        
        // Customize input bar appearance
        messageInputBar.inputTextView.placeholder = "Ask anything..."
        messageInputBar.inputTextView.backgroundColor = .clear
        messageInputBar.inputTextView.layer.cornerRadius = 24
        messageInputBar.inputTextView.layer.masksToBounds = true
        
        // Remove border and change background
        messageInputBar.backgroundView.backgroundColor = .systemBackground
        messageInputBar.separatorLine.isHidden = true
        messageInputBar.inputTextView.scrollIndicatorInsets = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
        
        // Remove default left and right stack items
        messageInputBar.setStackViewItems([], forStack: .left, animated: false)
        messageInputBar.setStackViewItems([], forStack: .right, animated: false)
        
        // Create a container for the input field
        let inputContainer = UIView()
        inputContainer.backgroundColor = .white
        inputContainer.layer.cornerRadius = 24
        
        // Create a custom text view
        let customTextView = UITextView()
        customTextView.font = UIFont.systemFont(ofSize: 16)
        customTextView.backgroundColor = .clear
        customTextView.isScrollEnabled = false
        customTextView.textContainerInset = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 44)
        customTextView.delegate = self
        
        // Add placeholder to the text view
        let placeholderLabel = UILabel()
        placeholderLabel.text = "Ask anything..."
        placeholderLabel.font = UIFont.systemFont(ofSize: 16)
        placeholderLabel.textColor = .systemGray
        placeholderLabel.isHidden = false
        
        // Configure the microphone button (shown when text field is empty)
        let voiceButton = UIButton(type: .system)
        voiceButton.setImage(UIImage(systemName: "waveform"), for: .normal)
        voiceButton.tintColor = .black
        voiceButton.addTarget(self, action: #selector(voiceButtonTapped), for: .touchUpInside)
        
        // Configure the send button (shown when text field has content)
        let sendButton = UIButton(type: .system)
        sendButton.setImage(UIImage(systemName: "arrow.up"), for: .normal)
        sendButton.backgroundColor = .black
        sendButton.tintColor = .white
        sendButton.clipsToBounds = true
        sendButton.widthAnchor.constraint(equalTo: sendButton.heightAnchor).isActive = true
        sendButton.addTarget(self, action: #selector(sendButtonTapped), for: .touchUpInside)
        sendButton.isHidden = true
        sendButton.alpha = 0 // Start with alpha 0 for better animation
        
        // Add views to the container
        inputContainer.addSubview(customTextView)
        inputContainer.addSubview(placeholderLabel)
        inputContainer.addSubview(voiceButton)
        inputContainer.addSubview(sendButton)
        
        // Setup constraints
        customTextView.translatesAutoresizingMaskIntoConstraints = false
        placeholderLabel.translatesAutoresizingMaskIntoConstraints = false
        voiceButton.translatesAutoresizingMaskIntoConstraints = false
        sendButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // Text view constraints
            customTextView.leadingAnchor.constraint(equalTo: inputContainer.leadingAnchor),
            customTextView.trailingAnchor.constraint(equalTo: inputContainer.trailingAnchor),
            customTextView.topAnchor.constraint(equalTo: inputContainer.topAnchor),
            customTextView.bottomAnchor.constraint(equalTo: inputContainer.bottomAnchor),
            
            // Placeholder constraints
            placeholderLabel.leadingAnchor.constraint(equalTo: customTextView.leadingAnchor, constant: 16),
            placeholderLabel.centerYAnchor.constraint(equalTo: customTextView.centerYAnchor),
            
            // Voice button constraints
            voiceButton.trailingAnchor.constraint(equalTo: inputContainer.trailingAnchor, constant: -12),
            voiceButton.centerYAnchor.constraint(equalTo: inputContainer.centerYAnchor),
            voiceButton.widthAnchor.constraint(equalToConstant: 28),
            voiceButton.heightAnchor.constraint(equalToConstant: 28),
            
            // Send button constraints
            sendButton.trailingAnchor.constraint(equalTo: inputContainer.trailingAnchor, constant: -12),
            sendButton.centerYAnchor.constraint(equalTo: inputContainer.centerYAnchor),
            sendButton.widthAnchor.constraint(equalToConstant: 28),
            sendButton.heightAnchor.constraint(equalToConstant: 28)
        ])
        
        // Create DeepSearch Button
        let deepSearchContainer = SelfSizingView()
        deepSearchContainer.backgroundColor = .systemGray6 // Light gray background
        deepSearchContainer.layer.cornerRadius = 18
        deepSearchContainer.tag = 0 // 0 = unselected
        deepSearchContainer.setContentHuggingPriority(.defaultHigh, for: .horizontal) // Prefer natural size
        deepSearchContainer.setContentCompressionResistancePriority(.required, for: .horizontal) // Don't compress
        
        // Create a horizontal stack for the icon and text
        let deepSearchStack = UIStackView()
        deepSearchStack.axis = .horizontal
        deepSearchStack.spacing = 8
        deepSearchStack.alignment = .center
        deepSearchStack.setContentHuggingPriority(.required, for: .horizontal)
        deepSearchStack.setContentCompressionResistancePriority(.required, for: .horizontal)
        
        // Add the magnifying glass icon
        let searchIcon = UIImageView(image: UIImage(systemName: "magnifyingglass"))
        searchIcon.tintColor = .black
        searchIcon.contentMode = .scaleAspectFit
        searchIcon.translatesAutoresizingMaskIntoConstraints = false
        searchIcon.heightAnchor.constraint(equalToConstant: 20).isActive = true
        searchIcon.widthAnchor.constraint(equalToConstant: 20).isActive = true
        
        // Add the text label
        let searchLabel = UILabel()
        searchLabel.text = "DeepSearch"
        searchLabel.textColor = .black
        searchLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        
        // Add items to stack
        deepSearchStack.addArrangedSubview(searchIcon)
        deepSearchStack.addArrangedSubview(searchLabel)
        
        // Add stack to container
        deepSearchContainer.addSubview(deepSearchStack)
        deepSearchStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            deepSearchStack.leadingAnchor.constraint(equalTo: deepSearchContainer.leadingAnchor, constant: 12),
            deepSearchStack.trailingAnchor.constraint(equalTo: deepSearchContainer.trailingAnchor, constant: -12),
            deepSearchStack.topAnchor.constraint(equalTo: deepSearchContainer.topAnchor, constant: 8),
            deepSearchStack.bottomAnchor.constraint(equalTo: deepSearchContainer.bottomAnchor, constant: -8)
        ])
        
        // Add tap gesture
        let deepSearchTap = UITapGestureRecognizer(target: self, action: #selector(deepSearchTapped))
        deepSearchContainer.addGestureRecognizer(deepSearchTap)
        deepSearchContainer.isUserInteractionEnabled = true
        
        // Create a UIView container instead of stack view for more control
        let buttonsContainer = UIView()
        buttonsContainer.addSubview(deepSearchContainer)
        
        // Position the deepSearchContainer explicitly
        deepSearchContainer.translatesAutoresizingMaskIntoConstraints = false
        
        // Calculate a fixed height based on content
        let buttonHeight = 36.0 // Fixed height for the DeepSearch button
        
        NSLayoutConstraint.activate([
            deepSearchContainer.leadingAnchor.constraint(equalTo: buttonsContainer.leadingAnchor),
            deepSearchContainer.topAnchor.constraint(equalTo: buttonsContainer.topAnchor),
            deepSearchContainer.bottomAnchor.constraint(equalTo: buttonsContainer.bottomAnchor),
            // Height constraint for buttons container
            buttonsContainer.heightAnchor.constraint(equalToConstant: buttonHeight)
        ])
        
        // Create the main vertical stack for the entire input bar
        let mainStack = UIStackView(arrangedSubviews: [inputContainer, buttonsContainer])
        mainStack.axis = .vertical
        mainStack.spacing = 8
        mainStack.distribution = .fill
        
        // Add border to the main container
        mainStack.layer.borderWidth = 0.5
        mainStack.layer.borderColor = UIColor.systemGray4.cgColor
        mainStack.layer.cornerRadius = 24
        mainStack.clipsToBounds = true
        mainStack.layoutMargins = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        mainStack.isLayoutMarginsRelativeArrangement = true
        
        // Configure input bar with our custom view
        messageInputBar.setMiddleContentView(mainStack, animated: false)
        
        // Zero out stackView spacings
        messageInputBar.leftStackView.spacing = 0
        messageInputBar.rightStackView.spacing = 0
        messageInputBar.setLeftStackViewWidthConstant(to: 0, animated: false)
        messageInputBar.setRightStackViewWidthConstant(to: 0, animated: false)
        
        // Update padding and layout
        messageInputBar.padding.top = 12
        messageInputBar.padding.bottom = 12
        messageInputBar.padding.left = 8  // Further reduce left padding
        messageInputBar.padding.right = 8 // Further reduce right padding
        
        // Set max height
        messageInputBar.maxTextViewHeight = 120
        
        // Store references to UI elements for later access
        self.customTextView = customTextView
        self.placeholderLabel = placeholderLabel
        self.voiceButton = voiceButton
        self.sendButton = sendButton
        self.deepSearchContainer = deepSearchContainer
        self.searchIcon = searchIcon
        self.searchLabel = searchLabel
    }
    
    @objc private func voiceButtonTapped() {
        // Handle voice button tap
        print("Voice button tapped")
    }
    
    @objc private func deepSearchTapped() {
        // Toggle selected state
        let isSelected = deepSearchContainer.tag == 1
        toggleDeepSearchState(!isSelected)
    }
    
    private func toggleDeepSearchState(_ selected: Bool) {
        UIView.animate(withDuration: 0.2) {
            if selected {
                // Selected state - blue background, white text/icon
                self.deepSearchContainer.backgroundColor = UIColor.systemBlue
                self.searchIcon.tintColor = .white
                self.searchLabel.textColor = .white
            } else {
                // Unselected state - light gray background, black text/icon
                self.deepSearchContainer.backgroundColor = .systemGray6
                self.searchIcon.tintColor = .black
                self.searchLabel.textColor = .black
            }
            
            // Add a subtle transform/bounce effect
            self.deepSearchContainer.transform = selected ? 
                CGAffineTransform(scaleX: 0.97, y: 0.97) : 
                .identity
        }
        
        // Update tag to track state
        deepSearchContainer.tag = selected ? 1 : 0
        
        // Print for debugging
        print("DeepSearch is now \(selected ? "selected" : "unselected")")
    }
    
    @objc private func sendButtonTapped() {
        // Handle send button tap
        guard let text = customTextView.text, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }
        
        // Send the message
        Task {
            do {
                try await viewModel.sendUserMessage(text)
            } catch {
                print("Error sending message: \(error)")
            }
        }
        
        // Clear the text view
        customTextView.text = ""
        placeholderLabel.isHidden = false
        toggleSendButton(show: false)
    }
    
    private func toggleSendButton(show: Bool) {
        // Improve animation with spring effect and cross-fade
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.2, options: [], animations: {
            // Voice button
            self.voiceButton.alpha = show ? 0 : 1
            self.voiceButton.transform = show ? 
                CGAffineTransform(scaleX: 0.8, y: 0.8) : 
                CGAffineTransform.identity
            
            // Send button
            self.sendButton.alpha = show ? 1 : 0
            self.sendButton.transform = show ? 
                CGAffineTransform.identity : 
                CGAffineTransform(scaleX: 0.8, y: 0.8)
        }) { _ in
            // After animation completes, update visibility
            self.voiceButton.isHidden = show
            self.sendButton.isHidden = !show
        }
    }
    
    private func setupBindings() {
        viewModel.$currentChat
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.messagesCollectionView.reloadData()
                self?.messagesCollectionView.scrollToLastItem(animated: true)
            }
            .store(in: &cancellables)
        
        viewModel.$isLoading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isLoading in
                self?.messageInputBar.sendButton.isEnabled = !isLoading
            }
            .store(in: &cancellables)
    }
    
    // Make sure to update the button shape after layout
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // Ensure buttons are perfectly round - safely check for nil and valid dimensions
        if let sendButton = sendButton, sendButton.frame.height > 0 {
            sendButton.layer.cornerRadius = sendButton.frame.height / 2
        }
    }
}

// MARK: - UIColor Extension

extension UIColor {
    func darker(by percentage: CGFloat = 0.2) -> UIColor {
        return self.adjust(by: -1 * abs(percentage))
    }
    
    func adjust(by percentage: CGFloat = 0.2) -> UIColor {
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        if self.getRed(&red, green: &green, blue: &blue, alpha: &alpha) {
            return UIColor(red: max(0, min(1, red + percentage)),
                          green: max(0, min(1, green + percentage)),
                          blue: max(0, min(1, blue + percentage)),
                          alpha: alpha)
        }
        return self
    }
}

// MARK: - UITextViewDelegate

extension ChatViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        // Toggle placeholder visibility
        let isEmpty = textView.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        placeholderLabel.isHidden = !isEmpty
        
        // Toggle send button visibility
        toggleSendButton(show: !isEmpty)
    }
}
