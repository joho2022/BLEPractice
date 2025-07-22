//
//  CentralViewModel.swift
//  BLEProject
//
//  Created by 조호근 on 7/17/25.
//

import Foundation

@MainActor
final class CentralViewModel: ObservableObject {
    private let manager = CentralManager()
    
    @Published var currentValue: Int = 0
    @Published var receivedValues: [MarkData] = []
    @Published var rssi: Int? = nil
    
    init() {
        self.manager.delegate = self
    }
    
    func disconnect() {
        manager.disconnect()
    }

    func reconnect() {
        manager.startScan()
    }
}

extension CentralViewModel: CentralManagerDelegate {
    func didReceiveValue(_ value: Int) {
        currentValue = value
        
        let newItem = MarkData(rawValue: value)
        receivedValues.append(newItem)
        
        if receivedValues.count > 30 {
            receivedValues.removeFirst()
        }
        
        let lastIndex = receivedValues.count - 1
        
        Task { @MainActor in
            receivedValues[lastIndex].barAnimated = true
            receivedValues[lastIndex] = receivedValues[lastIndex]
        }
    }

    
    func didUpdateRSSI(_ rssi: Int) {
        self.rssi = rssi
    }
}
