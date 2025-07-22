//
//  PeripheralViewModel.swift
//  BLEProject
//
//  Created by 조호근 on 7/17/25.
//

import Foundation

@MainActor
final class PeripheralViewModel: ObservableObject {

    @Published var value: Int = 0
    @Published var isAdvertising: Bool = false

    private let manager = PeripheralManager()

    init() {
        manager.delegate = self
    }

    func start() {
        manager.start()
    }

    func stop() {
        manager.stop()
    }
}

extension PeripheralViewModel: PeripheralManagerDelegate {
    func didUpdateValue(_ value: Int) {
        self.value = value
    }

    func didChangeAdvertisingState(_ isAdvertising: Bool) {
        self.isAdvertising = isAdvertising
    }
}
