//
//  HtmlString.swift
//  iBoard
//
//  Created by Kigen on 04/07/2018.
//  Copyright © 2018 Kigen. All rights reserved.
//

import Foundation

extension String {
    var htmlToAttributedString: NSAttributedString? {
        guard let data = data(using: .utf8) else { return NSAttributedString() }
        do {
            return try NSAttributedString(data: data, options: [.documentType: NSAttributedString.DocumentType.html, .characterEncoding:String.Encoding.utf8.rawValue], documentAttributes: nil)
        } catch {
            return NSAttributedString()
        }
    }
    
    var htmlToString: String {
        return htmlToAttributedString?.string ?? ""
    }
    
    func index(from: Int) -> Index {
        return self.index(startIndex, offsetBy: from)
    }
    
    /*
     let name = "Marie Curie"
     let firstSpace = name.index(of: " ") ?? name.endIndex
     let firstName = name[..<firstSpace]
     // firstName == "Marie"
     */
    
    func substring(from: Int) -> String {
        let fromIndex = index(from: from)
        
    
        return substring(from: fromIndex)
    }
    
    func substring(to: Int) -> String {
        let toIndex = index(from: to)
        return substring(to: toIndex)
    }
    
    func substring(with r: Range<Int>) -> String {
        let startIndex = index(from: r.lowerBound)
        let endIndex = index(from: r.upperBound)
        return substring(with: startIndex..<endIndex)
    }
}
