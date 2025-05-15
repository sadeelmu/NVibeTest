//
//  String+HTML.swift
//  NVibeTest
//
//  Created by Sadeel Muwahed on 15/05/2025.
//

import Foundation

extension String {
    func stripHTML() -> String {
        guard let data = data(using: .utf8) else { return self }
        if let attributed = try? NSAttributedString(data: data, options: [.documentType: NSAttributedString.DocumentType.html], documentAttributes: nil) {
            return attributed.string
        }
        return self
    }
}
