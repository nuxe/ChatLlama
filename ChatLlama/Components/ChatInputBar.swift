//
//  ChatInputBar.swift
//  ChatLlama
//
//  Created by Kush Agrawal on 3/13/25.
//

import UIKit

/// Custom input bar component for chat functionality
class ChatInputBar: UIView {
    
    // MARK: - Types
    
    /// Delegate protocol for handling input bar events
    protocol ChatInputBarDelegate: AnyObject {
        func inputBar(_ inputBar: ChatInputBar, didSendMessage text: String)
        func inputBarDidTapVoice(_ inputBar: ChatInputBar)
        func inputBarDidImageGen(_ isSelected: Bool)
    }
    
    /// Custom UIView that sizes itself based on its content
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
    
    // MARK: - Properties
    
    weak var delegate: ChatInputBarDelegate?
    
    var text: String {
        get { return customTextView.text }
        set {
            customTextView.text = newValue
            updatePlaceholderVisibility()
            toggleSendButton(show: !newValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
    }
    
    var isDeepSearchEnabled: Bool {
        return imageGenContainer.tag == 1
    }
    
    // MARK: - UI Components
    
    private lazy var customTextView: UITextView = {
        let textView = UITextView()
        textView.font = UIFont.systemFont(ofSize: 16)
        textView.backgroundColor = .clear
        textView.isScrollEnabled = false
        textView.textContainerInset = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 44)
        textView.delegate = self
        return textView
    }()
    
    private lazy var placeholderLabel: UILabel = {
        let label = UILabel()
        label.text = "Ask anything..."
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = .systemGray
        label.isHidden = false
        return label
    }()
    
    private lazy var voiceButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "waveform"), for: .normal)
        button.tintColor = .black
        button.addTarget(self, action: #selector(voiceButtonTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var sendButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "arrow.up"), for: .normal)
        button.backgroundColor = .black
        button.tintColor = .white
        button.clipsToBounds = true
        button.widthAnchor.constraint(equalTo: button.heightAnchor).isActive = true
        button.addTarget(self, action: #selector(sendButtonTapped), for: .touchUpInside)
        button.isHidden = true
        button.alpha = 0 // Start with alpha 0 for better animation
        return button
    }()
    
    private lazy var imageGenContainer: SelfSizingView = {
        let container = SelfSizingView()
        container.backgroundColor = .systemGray6 // Light gray background
        container.layer.cornerRadius = 18
        container.tag = 0 // 0 = unselected
        container.setContentHuggingPriority(.defaultHigh, for: .horizontal) // Prefer natural size
        container.setContentCompressionResistancePriority(.required, for: .horizontal) // Don't compress
        
        // Add tap gesture
        let imageGenTap = UITapGestureRecognizer(target: self, action: #selector(imageGenTapped))
        container.addGestureRecognizer(imageGenTap)
        container.isUserInteractionEnabled = true
        
        return container
    }()
    
    private lazy var searchIcon: UIImageView = {
        let imageView = UIImageView(image: UIImage(systemName: "magnifyingglass"))
        imageView.tintColor = .black
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.heightAnchor.constraint(equalToConstant: 20).isActive = true
        imageView.widthAnchor.constraint(equalToConstant: 20).isActive = true
        return imageView
    }()
    
    private lazy var searchLabel: UILabel = {
        let label = UILabel()
        label.text = "DeepSearch"
        label.textColor = .black
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        return label
    }()
    
    private lazy var imageGenStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 8
        stack.alignment = .center
        stack.setContentHuggingPriority(.required, for: .horizontal)
        stack.setContentCompressionResistancePriority(.required, for: .horizontal)
        
        // Add items to stack
        stack.addArrangedSubview(searchIcon)
        stack.addArrangedSubview(searchLabel)
        
        return stack
    }()
    
    private lazy var inputContainer: UIView = {
        let container = UIView()
        container.backgroundColor = .white
        container.layer.cornerRadius = 24
        
        return container
    }()
    
    private lazy var buttonsContainer: UIView = {
        let container = UIView()
        return container
    }()
    
    private lazy var mainStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [inputContainer, buttonsContainer])
        stack.axis = .vertical
        stack.spacing = 8
        stack.distribution = .fill
        
        // Add border to the main container
        stack.layer.borderWidth = 0.5
        stack.layer.borderColor = UIColor.systemGray4.cgColor
        stack.layer.cornerRadius = 24
        stack.clipsToBounds = true
        stack.layoutMargins = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        stack.isLayoutMarginsRelativeArrangement = true
        
        return stack
    }()
    
    // MARK: - Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // Ensure buttons are perfectly round
        if sendButton.frame.height > 0 {
            sendButton.layer.cornerRadius = sendButton.frame.height / 2
        }
    }
    
    // MARK: - UI Setup
    
    private func setupUI() {
        // Set up input container with text view, placeholder, and buttons
        inputContainer.addSubview(customTextView)
        inputContainer.addSubview(placeholderLabel)
        inputContainer.addSubview(voiceButton)
        inputContainer.addSubview(sendButton)
        
        // Setup constraints for input container components
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
        
        // Set up the deep search container and stack
        imageGenContainer.addSubview(imageGenStack)
        
        imageGenStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            imageGenStack.leadingAnchor.constraint(equalTo: imageGenContainer.leadingAnchor, constant: 12),
            imageGenStack.trailingAnchor.constraint(equalTo: imageGenContainer.trailingAnchor, constant: -12),
            imageGenStack.topAnchor.constraint(equalTo: imageGenContainer.topAnchor, constant: 8),
            imageGenStack.bottomAnchor.constraint(equalTo: imageGenContainer.bottomAnchor, constant: -8)
        ])
        
        // Set up buttons container
        buttonsContainer.addSubview(imageGenContainer)
        
        // Position the imageGenContainer explicitly
        imageGenContainer.translatesAutoresizingMaskIntoConstraints = false
        
        // Calculate a fixed height based on content
        let buttonHeight = 36.0 // Fixed height for the DeepSearch button
        
        NSLayoutConstraint.activate([
            imageGenContainer.leadingAnchor.constraint(equalTo: buttonsContainer.leadingAnchor),
            imageGenContainer.topAnchor.constraint(equalTo: buttonsContainer.topAnchor),
            imageGenContainer.bottomAnchor.constraint(equalTo: buttonsContainer.bottomAnchor),
            // Height constraint for buttons container
            buttonsContainer.heightAnchor.constraint(equalToConstant: buttonHeight)
        ])
        
        // Add the main stack to this view
        addSubview(mainStack)
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            mainStack.topAnchor.constraint(equalTo: topAnchor),
            mainStack.leadingAnchor.constraint(equalTo: leadingAnchor),
            mainStack.trailingAnchor.constraint(equalTo: trailingAnchor),
            mainStack.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
    
    // MARK: - Actions
    
    @objc private func voiceButtonTapped() {
        delegate?.inputBarDidTapVoice(self)
    }
    
    @objc private func imageGenTapped() {
        // Toggle selected state
        let isSelected = imageGenContainer.tag == 1
        toggleDeepSearchState(!isSelected)
        delegate?.inputBarDidImageGen(!isSelected)
    }
    
    func toggleDeepSearchState(_ selected: Bool) {
        UIView.animate(withDuration: 0.2) {
            if selected {
                // Selected state - blue background, white text/icon
                self.imageGenContainer.backgroundColor = UIColor.systemBlue
                self.searchIcon.tintColor = .white
                self.searchLabel.textColor = .white
            } else {
                // Unselected state - light gray background, black text/icon
                self.imageGenContainer.backgroundColor = .systemGray6
                self.searchIcon.tintColor = .black
                self.searchLabel.textColor = .black
            }
            
            // Add a subtle transform/bounce effect
            self.imageGenContainer.transform = selected ?
                CGAffineTransform(scaleX: 0.97, y: 0.97) :
                .identity
        }
        
        // Update tag to track state
        imageGenContainer.tag = selected ? 1 : 0
    }
    
    @objc private func sendButtonTapped() {
        guard let text = customTextView.text, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }
        
        delegate?.inputBar(self, didSendMessage: text)
        
        // Clear the text view
        self.text = ""
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
    
    private func updatePlaceholderVisibility() {
        placeholderLabel.isHidden = !customTextView.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    // MARK: - Public Methods
    
    func clearText() {
        text = ""
    }
    
    func setEnabled(_ enabled: Bool) {
        customTextView.isEditable = enabled
        sendButton.isEnabled = enabled
        voiceButton.isEnabled = enabled
        imageGenContainer.isUserInteractionEnabled = enabled
        
        alpha = enabled ? 1.0 : 0.7
    }
}

// MARK: - UITextViewDelegate for ChatInputBar

extension ChatInputBar: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        // Toggle placeholder visibility
        updatePlaceholderVisibility()
        
        // Toggle send button visibility
        let isEmpty = textView.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        toggleSendButton(show: !isEmpty)
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
