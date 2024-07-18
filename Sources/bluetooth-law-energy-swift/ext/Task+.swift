//
//  Task+.swift
//
//
//  Created by Igor  on 18.07.24.
//

import Foundation

// Define the Duration struct to represent time intervals in seconds
struct Duration {
    let seconds: Double
    
    static func seconds(_ value: Double) -> Duration {
        return Duration(seconds: value)
    }
}

@available(iOS, introduced: 15.0)
@available(macOS, introduced: 12.0)
extension Task where Success == Never, Failure == Never {
    
    /// Suspends the current task for the given time interval.
    ///
    /// - Parameter duration: The time interval to sleep for.
    static func sleep(for duration: Duration) async throws {
        if #available(iOS 16, macOS 13, *) {
            try await Task.sleep(for: .seconds(duration.seconds))
        } else {
            try await Task.sleep(nanoseconds: UInt64(duration.seconds * 1_000_000_000))
        }
    }
}
