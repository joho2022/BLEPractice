//
//  CentralManager.swift
//  BLEProject
//
//  Created by 조호근 on 7/17/25.
//

import Foundation
import CoreBluetooth
import os

final class CentralManager: NSObject {
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "BLECentral", category: "CentralManager")
    
    private var centralManager: CBCentralManager!
    private var connectedPeripheral: CBPeripheral?
    private var targetCharacteristic: CBCharacteristic?
    private var rssiTimer: Timer?
    
    private(set) var isScanning = false
    
    weak var delegate: CentralManagerDelegate?

    private(set) var receivedValue: Int?

    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }

    func startScan() {
        guard !isScanning else {
            logger.debug("ℹ️ 이미 스캔 중 - 중복 호출 무시")
            return
        }
        
        logger.info("🔍 스캔 시작됨")
        centralManager.scanForPeripherals(
            withServices: [PeripheralUUID.service]
        )
        isScanning = true
    }

    func stopScan() {
        guard isScanning else {
            logger.debug("ℹ️ 스캔 중 아님 - 중지 무시")
            return
        }
        logger.info("🛑 스캔 중지됨")
        centralManager.stopScan()
        isScanning = false
    }
    
    func startRSSIUpdates() {
        rssiTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            guard let peripheral = self?.connectedPeripheral else { return }
            peripheral.readRSSI()
        }
    }

    func stopRSSIUpdates() {
        rssiTimer?.invalidate()
        rssiTimer = nil
    }
    
    func disconnect() {
        guard let peripheral = connectedPeripheral else {
            logger.warning("⛔️ 연결된 Peripheral 없음 - disconnect 무시")
            return
        }
    
        logger.info("🔌 연결 중지 시도")
        centralManager.cancelPeripheralConnection(peripheral)
    }
}

extension CentralManager: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            logger.info("✅ BLE 켜짐")
            startScan()
            
        case .poweredOff:
            logger.warning("❌ BLE 꺼짐")
        case .unsupported:
            logger.error("⚠️ 디바이스 BLE 미지원")
        default:
            logger.debug("ℹ️ BLE 상태: \(central.state.rawValue)")
        }
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        logger.info("🔍 발견된 Peripheral: \(peripheral.name ?? "Unknown"), RSSI: \(RSSI.intValue)")
        logger.info("📡 이름: \(peripheral.name ?? "이름 없음")")
        logger.info("🆔 UUID: \(peripheral.identifier)")
        logger.info("🔗 상태: \(peripheral.state.rawValue)")
        
        
        Task { @MainActor in
            self.delegate?.didUpdateRSSI(RSSI.intValue)
        }
        
        stopScan()
        connectedPeripheral = peripheral
        peripheral.delegate = self
        centralManager.connect(peripheral, options: nil)
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        logger.info("✅ Peripheral 연결됨")
        stopScan()
        peripheral.discoverServices([PeripheralUUID.service])
        startRSSIUpdates()
    }

}

extension CentralManager: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error {
            logger.error("🚨 서비스 탐색 실패: \(error.localizedDescription)")
            return
        }

        guard let service = peripheral.services?.first else {
            logger.warning("⚠️ 서비스 없음")
            return
        }

        logger.info("📦 서비스 발견됨 - characteristics 탐색 시작")
        peripheral.discoverCharacteristics([PeripheralUUID.characteristic], for: service)
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let error {
            logger.error("🚨 characteristic 탐색 실패: \(error.localizedDescription)")
            return
        }

        guard let characteristic = service.characteristics?.first else {
            logger.warning("⚠️ characteristic 없음")
            return
        }

        self.targetCharacteristic = characteristic
        peripheral.setNotifyValue(true, for: characteristic)
        logger.info("🟢 Notify 등록됨")
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error {
            logger.error("❌ 데이터 수신 실패: \(error.localizedDescription)")
            return
        }

        guard let data = characteristic.value else {
            logger.warning("⚠️ 수신 데이터 없음")
            return
        }

        let value = data.withUnsafeBytes { $0.load(as: Int.self).bigEndian }
        self.receivedValue = value
        logger.debug("📥 수신값: \(value)")
        
        Task { @MainActor in
            self.delegate?.didReceiveValue(value)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
        if let error = error {
            logger.error("❌ RSSI 읽기 실패: \(error.localizedDescription)")
            return
        }

        logger.debug("📶 최신 RSSI: \(RSSI.intValue)")
        
        Task { @MainActor in
            self.delegate?.didUpdateRSSI(RSSI.intValue)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        logger.warning("⚠️ Peripheral 연결 끊김: \(error?.localizedDescription ?? "No error")")
        stopRSSIUpdates() 
        connectedPeripheral = nil
    }
}
