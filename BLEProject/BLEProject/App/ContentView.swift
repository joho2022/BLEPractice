//
//  ContentView.swift
//  BLEProject
//
//  Created by 조호근 on 7/17/25.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                Text("BLE 모드를 선택하세요")
                    .font(.title)
                    .bold()

                ForEach(BLEMode.allCases) { mode in
                    NavigationLink(destination: view(for: mode)) {
                        Text(mode.rawValue)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
            }
            .padding()
        }
    }
}

extension ContentView {
    @ViewBuilder
    private func view(for mode: BLEMode) -> some View {
        switch mode {
        case .peripheral:
            PeripheralView()
        case .central:
            CentralView()
        }
    }
}

#Preview {
    ContentView()
}
