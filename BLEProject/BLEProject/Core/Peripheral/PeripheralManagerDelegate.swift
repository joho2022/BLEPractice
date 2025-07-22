//
//  PeripheralManagerDelegate.swift
//  BLEProject
//
//  Created by 조호근 on 7/17/25.
//

import Foundation

@MainActor
protocol PeripheralManagerDelegate: AnyObject {
    func didUpdateValue(_ value: Int)
    func didChangeAdvertisingState(_ isAdvertising: Bool)
}
