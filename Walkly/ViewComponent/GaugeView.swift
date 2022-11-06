//
//  GaugeView.swift
//  Walkly
//
//  Created on 2022/10/10.
//  
//

import SwiftUI

struct GaugeView: View {
    var value: Double
    var total: Double
    @State private var current = 1.0
    @State private var scale = 1.0
    //@State private var padding = 0.0
    
    var body: some View {
        GeometryReader{ geometry in
            VStack {
                Gauge(value: current, in: 1...total) {
                    //Text(value / 100, format: .percent)
                }
                .gaugeStyle(.accessoryCircularCapacity)
                .scaleEffect(scale)
                .tint(.green)
                .background(GeometryReader{ inner -> Text in
                    DispatchQueue.main.async {
                        let diameter = geometry.size.width
                        scale = inner.size.width == 0 ? 1.0 : diameter / inner.size.width
                        //padding = (diameter - inner.size.width) / 3
                    }
                    return Text("")
                })
                //.padding(padding)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity) // GeometryReaderを使用するとセンタリングされない問題の対処
            .padding()
            .onAppear {
                withAnimation() {
                    current = min(max(value, 1), total) // ゲージの範囲に収める(1〜total)
                }
            }
            .onChange(of: value) { newValue in
                withAnimation() {
                    current = min(max(newValue, 1), total) // ゲージの範囲に収める(1〜total)
                }
            }
        }
    }
}

struct CircularCapacityTestView: View {
    @State private var progress: Double = 100
    
    var body: some View {
        VStack {
            GaugeView(value: progress, total: 1000)
            Button("+") {
                progress += 100
            }
        }
    }
}

struct GaugeView_Previews: PreviewProvider {
    static var previews: some View {
        CircularCapacityTestView()
        .environment(\.locale, .init(identifier: "ja"))
        //.environment(\.locale, .init(identifier: "en"))
    }
}
