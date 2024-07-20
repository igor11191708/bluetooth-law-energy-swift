//
//  CBPeripheral+.swift
//
//
//  Created by Igor  on 19.07.24.
//

import CoreBluetooth

@available(macOS 12, iOS 15, tvOS 15.0, watchOS 8.0, *)
public extension CBPeripheral {
    
    // MARK: - Computed Properties
    
    /// Checks if the peripheral is connected.
    var isConnected: Bool {
        self.state == .connected
    }
    
    /// Checks if the peripheral is not connected.
    var isNotConnected: Bool {
        self.state != .connected
    }
    
    /// Retrieves the identifier of the peripheral.
    var getId: UUID {
        return self.identifier
    }
    
    /// Retrieves the name of the peripheral. If the name is nil, returns "unknown".
    var getName: String {
        name ?? "unknown"
    }
}


fileprivate func censorWords(in text: String, using words: [String]) -> String {
    var censoredText = text
    
    for word in words {
        let pattern = "\\b\(word)\\b"
        let regex = try! NSRegularExpression(pattern: pattern, options: .caseInsensitive)
        let range = NSRange(location: 0, length: censoredText.utf16.count)
        censoredText = regex.stringByReplacingMatches(in: censoredText, options: [], range: range, withTemplate: String(repeating: "*", count: word.count))
    }
    
    return censoredText
}
