//
//  CentralManagerDelegate.swift
//  BLEProject
//
//  Created by 조호근 on 7/17/25.
//

import Foundation

@MainActor
protocol CentralManagerDelegate: AnyObject {
    func didReceiveValue(_ value: Int)
    func didUpdateRSSI(_ rssi: Int)
}
