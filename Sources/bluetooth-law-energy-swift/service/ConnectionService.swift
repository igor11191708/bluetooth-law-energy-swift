import CoreBluetooth

extension BluetoothLEManager {
    
    // Define an actor for handling Bluetooth connection services
    actor ConnectionService {
        
        /// Type alias for CheckedContinuation used for async operations
        private typealias Promise = CheckedContinuation<CBPeripheral, Error>
        
        /// Dictionary to register ongoing connections by UUID
        private var register: [UUID: Promise] = [:]

        /// Checks if the peripheral is not currently connecting.
        ///
        /// - Parameter peripheral: The `CBPeripheral` instance to check.
        /// - Returns: A Boolean value indicating whether the peripheral is not connecting.
        private func isNotConnecting(_ peripheral: CBPeripheral) -> Bool {
            return register[peripheral.identifier] == nil
        }
        
        /// Checks if the peripheral is connected.
        ///
        /// - Parameter peripheral: The `CBPeripheral` instance to check.
        /// - Returns: A Boolean value indicating whether the peripheral is connected.
        private func isConnected(_ peripheral: CBPeripheral) -> Bool {
            return peripheral.state == .connected
        }
        
        /// Checks if the peripheral is not connected.
        ///
        /// - Parameter peripheral: The `CBPeripheral` instance to check.
        /// - Returns: A Boolean value indicating whether the peripheral is not connected.
        private func isNotConnected(_ peripheral: CBPeripheral) -> Bool {
            !isConnected(peripheral)
        }
        
        /// Adds a continuation to the register for a given peripheral.
        ///
        /// - Parameters:
        ///   - continuation: The `Promise` continuation to add.
        ///   - peripheral: The `CBPeripheral` instance to associate with the continuation.
        private func add(_ continuation: Promise, for peripheral: CBPeripheral) {
            register[peripheral.identifier] = continuation
        }
        
        /// Removes a continuation from the register for a given peripheral.
        ///
        /// - Parameter peripheral: The `CBPeripheral` instance to remove.
        private func remove(for peripheral: CBPeripheral) {
            register.removeValue(forKey: peripheral.identifier)
        }
        
        /// Handles the result of a connection attempt.
        ///
        /// - Parameters:
        ///   - peripheral: The `CBPeripheral` instance involved in the connection attempt.
        ///   - result: The `Result` of the connection attempt.
        private func handleResult(for peripheral: CBPeripheral, result: Result<CBPeripheral, Error>) {
            let id = peripheral.identifier
            
            // Ensure there's a registered continuation
            guard let continuation = register[id] else {
                return
            }
            
            remove(for: peripheral)
            
            // Resume the continuation based on the result
            switch result {
            case .success(let peripheral):
                continuation.resume(returning: peripheral)
            case .failure(let error):
                continuation.resume(throwing: error)
            }
        }
        
        /// Starts a timeout task for a given peripheral.
        ///
        /// - Parameters:
        ///   - peripheral: The `CBPeripheral` instance to start the timeout for.
        ///   - timeout: The timeout duration in nanoseconds.
        private func startTimeoutTask(for peripheral: CBPeripheral, timeout: Double) {
            Task {
                try? await Task.sleep(for: .seconds(timeout))
                if register[peripheral.identifier] != nil {
                    handleResult(for: peripheral, result: .failure(Errors.timeout(peripheral)))
                }
            }
        }
        
        /// Connects to a given peripheral.
        ///
        /// - Parameters:
        ///   - peripheral: The `CBPeripheral` instance to connect to.
        ///   - centralManager: The `CBCentralManager` instance used for the connection.
        ///   - timeout: The timeout duration in nanoseconds.
        /// - Returns: The connected `CBPeripheral` instance.
        /// - Throws: A `BluetoothLEManager.Errors` error if the connection fails or times out.
        public func connect(to peripheral: CBPeripheral, using centralManager: CBCentralManager, timeout: Double = 5.0) async throws -> CBPeripheral {
            return try await withCheckedThrowingContinuation { continuation in
                
                guard isNotConnected(peripheral) else {
                    continuation.resume(throwing: Errors.connected(peripheral))
                    return
                }
                
                guard isNotConnecting(peripheral) else {
                    continuation.resume(throwing: Errors.connecting(peripheral))
                    return
                }
                
                #if DEBUG
                print("Connecting to \(peripheral.name!)")
                #endif
                
                add(continuation, for: peripheral)
                centralManager.connect(peripheral, options: nil)
                startTimeoutTask(for: peripheral, timeout: timeout)
            }
        }
        
        /// Handles the event when a peripheral is connected.
        ///
        /// - Parameter peripheral: The `CBPeripheral` instance that was connected.
        public func handleDidConnect(_ peripheral: CBPeripheral) {
            handleResult(for: peripheral, result: .success(peripheral))

            #if DEBUG
            print("didConnect \(peripheral.name) Total: \(register.count)")
            #endif
        }
        
        /// Handles the event when a connection to a peripheral fails.
        ///
        /// - Parameters:
        ///   - peripheral: The `CBPeripheral` instance that failed to connect.
        ///   - error: The error that occurred during the connection attempt, if any.
        public func handleDidFailToConnect(_ peripheral: CBPeripheral, with error: Error?) {
            handleResult(for: peripheral, result: .failure(Errors.connection(peripheral, error)))
            
            #if DEBUG
            print("FailToConnect \(register.count) \(peripheral.name ?? "")")
            #endif
        }
    }
}
