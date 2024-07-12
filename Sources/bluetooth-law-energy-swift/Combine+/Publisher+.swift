//
//  Publisher+.swift
//
//
//  Created by Igor  on 12.07.24.
//

import Combine
import CoreBluetooth

extension Publisher where Output == CBManagerState, Failure == Never {
    func dropFirstIfPoweredOff() -> AnyPublisher<CBManagerState, Never> {
        self.scan((0, CBManagerState.unknown)) { acc, newState in
            let (count, _) = acc
            return (count + 1, newState)
        }
        .drop { (count, state) in
            return count == 1 && state == .poweredOff
        }
        .map { $0.1 } // Extract the actual CBManagerState value from the tuple
        .eraseToAnyPublisher()
    }
}

extension Publisher {
    func receiveOnMainAndEraseToAnyPublisher() -> AnyPublisher<Output, Failure> {
        self.receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
}
