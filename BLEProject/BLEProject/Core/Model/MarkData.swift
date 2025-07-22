//
//  MarkData.swift
//  BLEProject
//
//  Created by 조호근 on 7/18/25.
//

import Foundation

final class MarkData: Identifiable {
    let id = UUID()
    private let rawValue: Int

    var barAnimated: Bool = false

    var displayBarValue: Int { barAnimated ? rawValue : 0 }
    var displayLineValue: Int { rawValue }

    init(rawValue: Int) {
        self.rawValue = rawValue
    }
}
