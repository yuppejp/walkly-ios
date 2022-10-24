//
//  ChartView.swift
//  Walkly
//
//  Created on 2022/10/10.
//  
//

import SwiftUI
import Charts

struct ChartDataItem: Identifiable, Equatable {
    var id = UUID()
    var label: String
    var value: Double
}

class ChartData: ObservableObject {
    @Published var items: [ChartDataItem] = []
    
    init(data: [ChartDataItem]) {
        self.items = data
    }
}

struct BarChartView: View {
    @ObservedObject var data: ChartData
    @State var items: [ChartDataItem] = []
    @State var maxY = 0.0
    var annotation: Bool = true
    var target: Double?

    var body: some View {
        Chart(items) { item in
            BarMark(
                x: .value("label", item.label),
                y: .value("value", item.value)
            )
            .foregroundStyle(Color.green.gradient)
            .annotation(position: .top, alignment: .center) {
                if annotation {
                    Text("\(item.value, format: .number.precision(.fractionLength(0)))")
                        .font(.caption2)
                        .foregroundColor(.gray)
                        //.foregroundColor(.white)
                        //.rotationEffect(.degrees(90))
                } else {
                    Text("")
                }
            }
            .foregroundStyle(Color.green.gradient.opacity(0.3))

            if let target = target {
                RuleMark(y: .value("Target", target))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [3]))
                    .foregroundStyle(.gray)
                    .annotation(position: .top, alignment: .leading) {
                        Text("目標 \(target.toIntegerString())")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
            }
        }
        .chartYScale(domain: 0...maxY)
        .chartYAxis(Visibility.hidden)
        //.chartYScale(domain: ClosedRange(uncheckedBounds: (lower: 0, upper: maxY)))
        //.chartXAxisLabel("Label")
        
        .onAppear {
            withAnimation() {
                maxY = maxValue(data.items) * 1.1
                items = data.items
            }
        }
        .onChange(of: data.items) { newValue in
            withAnimation() {
                maxY = maxValue(newValue) * 1.1
                items = newValue
            }
        }
    }
    
    private func maxValue(_ items: [ChartDataItem]) -> Double {
        var maxValue = 0.0
        for i in 0 ..< items.count {
            maxValue = max(maxValue, items[i].value)
        }
        if let target = target {
            maxValue = max(target, maxValue)
        }
        return maxValue
    }
}

struct LineChartView: View {
    @ObservedObject var data: ChartData
    @State var chartItems: [ChartDataItem] = []
    @State var total = 0.0
    @State var maxY = 0.0
    var stacked = false
    var target: Double?
    var annotation: Bool = true

    var body: some View {
        Chart(chartItems) { item in
            LineMark(
                x: .value("label", item.label),
                y: .value("value", item.value)
            )
            .foregroundStyle(Color.green.gradient.opacity(0.7))
            
            PointMark(
                x: .value("label", item.label),
                y: .value("value", item.value)
            )
            .foregroundStyle(Color.green.opacity(0.7))

            if stacked {
                RuleMark(y: .value("Current", total))
                    .lineStyle(StrokeStyle(lineWidth: 1))
                    .foregroundStyle(.gray)
                    .annotation(position: .top, alignment: .trailing) {
                        Text("現在 \(total.toIntegerString())")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
            }

            if let target = target {
                RuleMark(y: .value("Target", target))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [3]))
                    .foregroundStyle(.gray)
                    .annotation(position: .top, alignment: .leading) {
                        Text("目標 \(target.toIntegerString())")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
            }
        }
        .chartXAxis(Visibility.automatic)
        .chartYAxis(Visibility.automatic)
        .chartYScale(domain: 0...(maxY * 1.1))
        //.chartYScale(domain: ClosedRange(uncheckedBounds: (lower: 0, upper: maxY)))
        //.chartXAxisLabel("Label")
        
        .onAppear {
            update(data.items)
        }
        .onChange(of: data.items) { newValue in
            update(newValue)
        }
    }
    
    private func update(_ items: [ChartDataItem]) {
        if stacked {
            var accumu = 0.0
            var tempItems = items
            for i in 0 ..< tempItems.count {
                accumu += tempItems[i].value
                tempItems[i].value = accumu
            }
            
            var maxValue = accumu
            if let target = target {
                maxValue = max(target, maxValue)
            }
            
            withAnimation() {
                total = accumu
                maxY = maxValue
                chartItems = tempItems
            }
        } else {
            var maxValue = 0.0
            for i in 0 ..< items.count {
                maxValue = max(maxValue, items[i].value)
            }
            withAnimation() {
                maxY = maxValue
                chartItems = items
            }
        }
    }
}

struct BarChartTestView: View {
    @ObservedObject var chartData = ChartData(data: [
        .init(label: "Sun", value: 9000),
        .init(label: "Mon", value: 5000),
        .init(label: "Tue", value: 7000),
        .init(label: "Wed", value: 4000),
        .init(label: "Thu", value: 3000),
        .init(label: "Fri", value: 8000),
        .init(label: "Sat", value: 13000)
    ])
    
    var body: some View {
        VStack {
            BarChartView(data: chartData)
            LineChartView(data: chartData, stacked: true, target: 20000.0)
            
            Button("+") {
                chartData.items[6].value += 100
            }
        }
        .padding()
    }
}

struct BarChartView_Previews: PreviewProvider {
    static var previews: some View {
        BarChartTestView()
    }
}
