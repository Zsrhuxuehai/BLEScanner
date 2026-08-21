import CoreBluetooth
import SwiftUI

struct BLEDevice: Identifiable {
    let id = UUID()
    let identifier: String
    let name: String
    let rssi: Int
    let peripheral: CBPeripheral
}

class BLEManager: NSObject, ObservableObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    @Published var devices: [BLEDevice] = []
    @Published var isScanning = false
    @Published var isConnected = false
    @Published var connectedDevice: BLEDevice?
    @Published var responseLog = ""
    @Published var showDeviceView = false
    
    private var centralManager: CBCentralManager!
    private var targetPeripheral: CBPeripheral?
    private var rxCharacteristic: CBCharacteristic?
    private var txCharacteristic: CBCharacteristic?
    
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    // MARK: - Scanning
    
    func startScan() {
        guard centralManager.state == .poweredOn else { return }
        devices.removeAll()
        isScanning = true
        centralManager.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: false])
    }
    
    func stopScan() {
        centralManager.stopScan()
        isScanning = false
    }
    
    // MARK: - Connection
    
    func connect(to device: BLEDevice) {
        stopScan()
        targetPeripheral = device.peripheral
        targetPeripheral?.delegate = self
        centralManager.connect(device.peripheral, options: nil)
    }
    
    func disconnect() {
        guard let p = targetPeripheral else { return }
        centralManager.cancelPeripheralConnection(p)
    }
    
    // MARK: - Send
    
    func sendA0() {
        guard let tx = txCharacteristic else {
            responseLog += "TX characteristic not found\n"
            return
        }
        let data = Data([0xA0])
        targetPeripheral?.writeValue(data, for: tx, type: .withResponse)
        responseLog += ">>> A0\n"
    }
    
    // MARK: - CBCentralManagerDelegate
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            startScan()
        }
    }
    
    func centralManager(_ central: CBCentralManager,
                        didDiscover peripheral: CBPeripheral,
                        advertisementData: [String: Any],
                        rssi RSSI: NSNumber) {
        let name = peripheral.name ?? advertisementData[CBAdvertisementDataLocalNameKey] as? String ?? "Unknown"
        let device = BLEDevice(
            identifier: peripheral.identifier.uuidString,
            name: name,
            rssi: RSSI.intValue,
            peripheral: peripheral
        )
        if !devices.contains(where: { $0.identifier == device.identifier }) {
            devices.append(device)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        isConnected = true
        responseLog = ""
        if let idx = devices.firstIndex(where: { $0.identifier == peripheral.identifier.uuidString }) {
            connectedDevice = devices[idx]
        }
        showDeviceView = true
        peripheral.discoverServices(nil)
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        isConnected = false
        connectedDevice = nil
        rxCharacteristic = nil
        txCharacteristic = nil
        responseLog += "Disconnected\n"
    }
    
    // MARK: - CBPeripheralDelegate
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }
        for service in services {
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral,
                    didDiscoverCharacteristicsFor service: CBService,
                    error: Error?) {
        guard let characteristics = service.characteristics else { return }
        for c in characteristics {
            responseLog += "Found: \(c.uuid) [\(c.properties.rawValue)]\n"
            
            // Subscribe to characteristics with notify/indicate
            if c.properties.contains(.notify) || c.properties.contains(.indicate) {
                peripheral.setNotifyValue(true, for: c)
                rxCharacteristic = c
                responseLog += "  -> Subscribed (RX)\n"
            }
            
            // Find writable characteristic
            if c.properties.contains(.write) || c.properties.contains(.writeWithoutResponse) {
                txCharacteristic = c
                responseLog += "  -> Writable (TX)\n"
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral,
                    didUpdateValueFor characteristic: CBCharacteristic,
                    error: Error?) {
        if let data = characteristic.value {
            let hex = data.map { String(format: "%02X", $0) }.joined(separator: " ")
            responseLog += "<<< \(hex)\n"
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral,
                    didWriteValueFor characteristic: CBCharacteristic,
                    error: Error?) {
        if let err = error {
            responseLog += "Write error: \(err.localizedDescription)\n"
        } else {
            responseLog += "Write OK\n"
        }
    }
}