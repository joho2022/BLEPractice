//
//  CentralView.swift
//  BLEProject
//
//  Created by 조호근 on 7/17/25.
//

import SwiftUI
import Charts

struct CentralView: View {
    @StateObject private var viewModel = CentralViewModel()
    @State private var showLine: Bool = false
    @State private var lineAnimationFraction: CGFloat = 0.0
    
    var body: some View {
        VStack(spacing: 24) {
            rssiView
            
            Text("📡 수신 중인 값")
                .font(.headline)

            Text("\(viewModel.currentValue)")
                .font(.system(size: 48, weight: .bold))
                .foregroundColor(.blue)
            
            HStack {
                Spacer()
                Toggle("", isOn: $showLine)
                    .toggleStyle(.switch)
                    .padding()
            }

            ZStack {
                Chart {
                    ForEach(Array(viewModel.receivedValues.enumerated()), id: \.offset) { index, data in
                        BarMark(
                            x: .value("시간", index),
                            y: .value("혈당", data.displayBarValue)
                        )
                        .foregroundStyle(.cyan.opacity(0.5))
                        .cornerRadius(3)
                    }
                }
                .frame(height: 220)
                .chartXScale(domain: -1...33)
                .chartYScale(domain: 0...200)
                .chartXAxis {
                    AxisMarks(values: Array(stride(from: 0, through: 30, by: 10)))
                }
                .animation(.easeOut(duration: 0.3), value: viewModel.receivedValues.map(\.displayBarValue))

                Chart {
                    ForEach(Array(viewModel.receivedValues.enumerated()), id: \.offset) { index, data in
                        LineMark(
                            x: .value("시간", index),
                            y: .value("혈당", data.displayLineValue)
                        )
                        .foregroundStyle(.blue)
                        .interpolationMethod(.monotone)
                    }
                }
                .frame(height: 220)
                .chartXScale(domain: -1...33)
                .chartYScale(domain: 0...200)
                .chartXAxis(.hidden)
                .chartYAxis(.hidden)
                .mask(
                    GeometryReader { proxy in
                        Rectangle()
                            .frame(width: proxy.size.width * (showLine ? lineAnimationFraction : 0))
                            .animation(.easeOut(duration: 3.0), value: lineAnimationFraction)
                    }
                )
                .padding(.trailing, 25)
            }
            .onChange(of: showLine) { isOn in
                if isOn {
                    lineAnimationFraction = 0.0
                    Task { @MainActor in
                        withAnimation(.easeOut(duration: 5.0)) {
                            lineAnimationFraction = 1.0
                        }
                    }
                } else {
                    lineAnimationFraction = 0.0
                }
            }
            
            Text("BLE 켜져있으면 바로 감지합니다.")
                .bold()
                .foregroundStyle(Color.black)
                .padding()
                .background(.tint.opacity(0.3))
                .cornerRadius(10)
            
            HStack(spacing: 16) {
                Button("🔌 연결 끊기") {
                    viewModel.disconnect()
                }

                Button("🔄 다시 연결") {
                    viewModel.reconnect()
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

extension CentralView {
    var rssiView: some View {
        guard let rssi = viewModel.rssi else {
            return Text("📶 신호 없음")
        }

        switch rssi {
        case let x where x >= -60:
            return Text("🟢 신호 세기(RSSI): \(rssi) dBm")
        case -80...(-61):
            return Text("🟡 신호 세기(RSSI): \(rssi) dBm")
        default:
            return Text("🔴 신호 세기(RSSI): \(rssi) dBm")
        }
    }
}

#Preview {
    CentralView()
}
