//
//  ImageMediaItem.swift
//  ChatLlama
//
//  Created by Kush Agrawal on 3/6/25.
//

import UIKit
import MessageKit

struct ImageMediaItem: MediaItem {
    var url: URL?
    var image: UIImage?
    var placeholderImage: UIImage
    var size: CGSize
}
