import XCTest
import CoreBluetooth
@testable import bluetooth_law_energy_swift

final class BluetoothLEManagerTests: XCTestCase {
    
    func testBluetoothLEManagerCreation() async throws {
        let manager = BluetoothLEManager(logger: nil)
        
        XCTAssertNotNil(manager)
    }
    
}
