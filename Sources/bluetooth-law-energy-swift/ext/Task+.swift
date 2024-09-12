//
//  Task+.swift
//
//
//  Created by Igor  on 18.07.24.
//

import Foundation


/// Extends Task to provide a sleep function when used in an async context.
@available(iOS, introduced: 15.0)
@available(macOS, introduced: 12.0)
@available(watchOS, introduced: 8.0)
@available(tvOS, introduced: 15.0)
extension Task where Success == Never, Failure == Never {
    
    /// Suspends the current task for the given time interval.
    ///
    /// - Parameter duration: The time interval to sleep for.
    static func sleep(for duration: Double) async throws {
        if #available(iOS 16, macOS 13, tvOS 16.0, watchOS 9.0, *) {
            try await Task.sleep(for: .seconds(duration))
        } else {
            try await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
        }
    }
}
