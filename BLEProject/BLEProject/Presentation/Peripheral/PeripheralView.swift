//
//  PeripheralView.swift
//  BLEProject
//
//  Created by 조호근 on 7/17/25.
//

import SwiftUI

struct PeripheralView: View {
    @StateObject private var viewModel = PeripheralViewModel()

    var body: some View {
        VStack(spacing: 16) {
            Text("📡 Advertising: \(viewModel.isAdvertising ? "ON" : "OFF")")
            Text("🩸 Value: \(viewModel.value)")

            HStack {
                Button("Start") {
                    viewModel.start()
                }
                Button("Stop") {
                    viewModel.stop()
                }
            }
        }
        .padding()
    }
}

#Preview {
    PeripheralView()
}
