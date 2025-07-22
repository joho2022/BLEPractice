//
//  PeripheralManager.swift
//  BLEProject
//
//  Created by 조호근 on 7/17/25.
//

import Foundation
import CoreBluetooth
import os

final class PeripheralManager: NSObject {
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "Peripheral", category: "Peripheral")

    private var peripheralManager: CBPeripheralManager!
    private var characteristic: CBMutableCharacteristic?
    private var timer: Timer?
    
    private var isAdvertising = false

    weak var delegate: PeripheralManagerDelegate?

    override init() {
        super.init()
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
    }

    func start() {
        guard peripheralManager.state == .poweredOn else {
            logger.error("❗️Bluetooth is not powered on")
            return
        }
        guard !isAdvertising else {
            logger.debug("ℹ️ Already advertising")
            return
        }

        let char = CBMutableCharacteristic(
            type: PeripheralUUID.characteristic,
            properties: [.notify],
            value: nil,
            permissions: [.readable]
        )
        self.characteristic = char

        let service = CBMutableService(type: PeripheralUUID.service, primary: true)
        service.characteristics = [char]

        peripheralManager.add(service)

        peripheralManager.startAdvertising([
            CBAdvertisementDataServiceUUIDsKey: [PeripheralUUID.service],
            CBAdvertisementDataLocalNameKey: "PeripheralTest"
        ])
        isAdvertising = true
        
        Task { @MainActor in
            delegate?.didChangeAdvertisingState(true)
        }
        logger.info("📡 Started advertising")
    }

    func stop() {
        guard isAdvertising else {
            logger.debug("ℹ️ Not advertising. Stop skipped.")
            return
        }
        
        peripheralManager.stopAdvertising()
        timer?.invalidate()
        isAdvertising = false
        timer = nil
        
        Task { @MainActor in
            delegate?.didChangeAdvertisingState(false)
        }
        logger.info("🛑 Stopped advertising")
    }
}

extension PeripheralManager: CBPeripheralManagerDelegate {
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        switch peripheral.state {
        case .poweredOn:
            logger.info("✅ Bluetooth ON")
        case .poweredOff:
            logger.warning("❌ Bluetooth OFF")
        case .unsupported:
            logger.error("⚠️ BLE unsupported on this device")
        default:
            logger.debug("ℹ️ Peripheral state: \(peripheral.state.rawValue)")
        }
    }

    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didSubscribeTo characteristic: CBCharacteristic) {
        logger.info("🟢Central subscribed. Start sending values.")

        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            let value = Int.random(in: 70...180)
            self.logger.debug("Sending value: \(value)")

            let data = withUnsafeBytes(of: value.bigEndian, Array.init)
            self.peripheralManager.updateValue(Data(data), for: self.characteristic!, onSubscribedCentrals: nil)

            Task { @MainActor in
                self.delegate?.didUpdateValue(value)                
            }
        }
    }

    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didUnsubscribeFrom characteristic: CBCharacteristic) {
        logger.info("Central unsubscribed. Stop sending.")
        timer?.invalidate()
        timer = nil
    }
}
