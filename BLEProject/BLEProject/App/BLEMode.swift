//
//  BLEMode.swift
//  BLEProject
//
//  Created by 조호근 on 7/17/25.
//

import Foundation

enum BLEMode: String, CaseIterable, Identifiable {
    case peripheral = "Peripheral"
    case central = "Central"

    var id: String { rawValue }
}
