//
//  Publisher+.swift
//
//
//  Created by Igor  on 12.07.24.
//

import Combine
import CoreBluetooth

/// Extension to the Publisher type where the Output is CBManagerState and Failure is Never
extension Publisher where Output == CBManagerState, Failure == Never {
    
    /// Custom operator to drop the first state if it is .poweredOff
    ///
    /// - Returns: An `AnyPublisher` that drops the first state if it is .poweredOff
    func dropFirstIfPoweredOff() -> AnyPublisher<CBManagerState, Never> {
        // Accumulates state with a count
        self.scan((0, CBManagerState.unknown)) { acc, newState in
            let (count, _) = acc
            // Increment count and update state
            return (count + 1, newState)
        }
        // Drop the first state if it is .poweredOff
        .drop { (count, state) in
            return count == 1 && state == .poweredOff
        }
        // Extract the actual CBManagerState value from the tuple
        .map { $0.1 }
        // Erase to AnyPublisher to hide the implementation details
        .eraseToAnyPublisher()
    }
}

/// Extension to the Publisher type for receiving on the main queue and erasing to AnyPublisher
extension Publisher {
    
    /// Custom operator to receive output on the main thread and erase to AnyPublisher
    ///
    /// - Returns: An `AnyPublisher` that ensures the output is received on the main thread
    func receiveOnMainAndEraseToAnyPublisher() -> AnyPublisher<Output, Failure> {
        // Ensure the publisher receives output on the main thread
        self.receive(on: DispatchQueue.main)
            // Erase to AnyPublisher to hide the implementation details
            .eraseToAnyPublisher()
    }
}
