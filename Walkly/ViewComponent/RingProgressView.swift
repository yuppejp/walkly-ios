//
//  RingProgressView.swift
//  Walkly
//
//  Created on 2022/10/10.
//  
//

import SwiftUI

struct RingProgressView: View {
    var title: String
    var label: String
    var total: Double
    var value: Double
    var date: Date
    @State var ratio: Double = 0.0
    var lineWidth: CGFloat = 15.0
    var outerRingColor: Color = Color.gray.opacity(0.3)
    var innerRingColor: Color = Color.green
    
    var body: some View {
        ZStack {
            VStack {
                Text(title)
                    .font(.caption)
                Text(getRatio().toPercentString())
                    .font(.caption)
                    .foregroundColor(.gray)
                Text(value.toIntegerString())
                    .font(.title)
                HStack(spacing: 0) {
                    Text("\(label): ")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text(total.toIntegerString())
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                Text(date, style: .time)
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
            Circle()
                .stroke(lineWidth: lineWidth)
                .foregroundColor(outerRingColor)
            Circle()
//                .trim(from: 0.0, to: min(ratio, 1.0))
                .trim(from: 0.0, to: min(max(0.001, getRatio()), 1.0))
                .stroke(
                    style: StrokeStyle(
                        lineWidth: lineWidth,
                        lineCap: .round, // .square
                        lineJoin: .round
                    )
                )
                .foregroundColor(innerRingColor)
                .rotationEffect(.degrees(-90.0))
//                .onAppear {
//                    withAnimation(.linear(duration: 0.5)) {
//                        ratio = max(0.001, getRatio())
//                    }
//                }
        }
        .padding(.all, lineWidth / 2)
    }
    
    func getRatio() -> Double {
        var ratio = 0.0
        if (total > 0) {
            ratio = value / total
        }
        return ratio
    }
}

struct RingProgressView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            //RingProgressView(title: "歩数", label: "目標", total: 8000, value: 1000, date: Date())
            
            CircularCapacityTestView()
        }
    }
}

struct CircularCapacityView: View {
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
                    //print("***** [CircularCapacityView] current: \(current), total: \(total)")
                    
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
            CircularCapacityView(value: progress, total: 1000)
            Button("+") {
                progress += 100
            }
        }
    }
}
