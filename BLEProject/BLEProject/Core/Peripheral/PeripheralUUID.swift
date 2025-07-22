//
//  PeripheralUUID.swift
//  BLEProject
//
//  Created by 조호근 on 7/17/25.
//

import CoreBluetooth

enum PeripheralUUID {
    static let service = CBUUID(string: "1234")
    static let characteristic = CBUUID(string: "5678")
}
