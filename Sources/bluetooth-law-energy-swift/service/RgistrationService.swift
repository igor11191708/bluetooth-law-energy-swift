import CoreBluetooth

extension BluetoothLEManager {
    
    
    enum ServiceType: String{
        case connection = "Connecting to"
        case discovering = "Discovering for"
    }
    
    actor RegistrationService<T> {
        
        init(type: ServiceType) {
            self.type = type
        }
        
        
        public let type : ServiceType
        
        typealias Promise = CheckedContinuation<T, Error>
        
        private var register: [UUID: Promise] = [:]

        public func isNotActive(_ id: UUID) -> Bool {
            return register[id] == nil
        }
        
        public func add(_ continuation: Promise, for id: UUID) {
            register[id] = continuation
        }
        
        private func remove(for id: UUID) {
            register.removeValue(forKey: id)
        }
        
        func handleResult(for peripheral: CBPeripheral, result: Result<T, Error>) {
            let id = peripheral.identifier
            
            guard let continuation = register[id] else {
                return
            }
            
            remove(for: id)
            
            switch result {
                case .success(let value):
                    continuation.resume(returning: value)
                case .failure(let error):
                    continuation.resume(throwing: error)
            }
        }

        private func timeoutTask(for id: UUID, timeout: Double) {
            Task {
                try? await Task.sleep(for: timeout)
                
                guard let continuation = register[id] else {
                    return
                }
                
                remove(for: id)
                
                #if DEBUG
                print("timeout \(type) \(id)")
                #endif
                
                continuation.resume(throwing: Errors.timeout)
            }
        }
        
        public func register(
            to id: UUID,
            name: String,
            with continuation: CheckedContinuation<T, Error>,
            timeout: Double = 30.0
        ) throws {
            
            guard isNotActive(id) else {
                continuation.resume(throwing: Errors.connecting(name))
                return
            }
            
            add(continuation, for: id)
            
            #if DEBUG
            print("\(type.rawValue) \(name)")
            #endif
            
            timeoutTask(for: id, timeout: timeout)
        }
    }
}

