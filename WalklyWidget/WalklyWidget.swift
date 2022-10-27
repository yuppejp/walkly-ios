//
//  WalklyWidget.swift
//  Walkly
//
//  Created on 2022/10/20.
//  
//

import WidgetKit
import SwiftUI
import Intents
import HealthKit

struct Entry: TimelineEntry {
    var date: Date = Date()
    var targetSteps: Double = 0.0
    var statistics: [HealthStatistics] = []
    static var chartData = ChartData(data: [])
    var error: Error?

    func getStatistics(identifier: HKQuantityTypeIdentifier) -> HealthStatistics {
        for stat in statistics {
            if stat.identifier == identifier {
                return stat
            }
        }
        return HealthStatistics(identifier: identifier, value: 0.0) // not found
    }
}

struct Provider: TimelineProvider {
    var model: HealthAsyncModel

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> Void) {
        Task {
            do {
                let todayResults = try await model.fetchTody(identifiers: [.stepCount, .distanceWalkingRunning])
                
                // 成功時の値を保存
                let defaluts = AppDefaults()
                for stat in todayResults {
                    switch stat.identifier  {
                    case .stepCount:
                        defaluts.lastStepCount = stat.value
                        defaluts.lastStepCountDate = stat.endDate
                    case .distanceWalkingRunning:
                        defaluts.lastDistanceWalkingRunning = stat.value
                        defaluts.lastDistanceWalkingRunningDate = stat.endDate
                    default: break
                    }
                }
                
                let startOfToday = Calendar.current.startOfDay(for: Date())
                let from = startOfToday
                let to = Date()
                let anchor = startOfToday
                let interval = DateComponents(hour: 1)
                let periodResult = try await model.fetchPeriod(identifier: .stepCount, from: from, to: to, anchor: anchor, interval: interval)

                let data = ChartData(data: [])
                for result in periodResult {
                    let label = result.startDate.toString("H")
                    let item = ChartDataItem(label: label, value: result.value)
                    data.items.append(item)
                 }
                Entry.chartData = data

                DispatchQueue.main.async {
                    let entry = Entry(targetSteps: defaluts.targetSteps, statistics: todayResults)
                    let timeline = Timeline(entries: [entry], policy: .atEnd)
                    completion(timeline)
                }
            } catch {
                print(error.localizedDescription)
                
                // エラー時は前回の値を使用する
                DispatchQueue.main.async {
                    var statistics: [HealthStatistics] = []
                    let defaluts = AppDefaults()
                    statistics.append(HealthStatistics(identifier: .stepCount,
                                                       startDate: defaluts.lastStepCountDate,
                                                       endDate: defaluts.lastStepCountDate,
                                                       value: defaluts.lastStepCount))
                    statistics.append(HealthStatistics(identifier: .distanceWalkingRunning,
                                                       startDate: defaluts.lastDistanceWalkingRunningDate,
                                                       endDate: defaluts.lastDistanceWalkingRunningDate,
                                                       value: defaluts.lastDistanceWalkingRunning))

                    let entry = Entry(targetSteps: defaluts.targetSteps, statistics: statistics, error: error)
                    let timeline = Timeline(entries: [entry], policy: .atEnd)
                    completion(timeline)
                }
            }
        }

//    var model: HealthModel
//    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> Void) {
//
//        let defaluts = AppDefaults()
//        model.fetchTody(identifiers: [.stepCount, .distanceWalkingRunning], completion: { result, error in
//            var entry = Entry()
//
//            // debug
//            var statistics: [HealthStatistics] = []
//            statistics.append(HealthStatistics(identifier: .stepCount,
//                                               startDate: defaluts.lastStepCountDate,
//                                               endDate: defaluts.lastStepCountDate,
//                                               value: defaluts.lastStepCount))
//            statistics.append(HealthStatistics(identifier: .distanceWalkingRunning,
//                                               startDate: defaluts.lastDistanceWalkingRunningDate,
//                                               endDate: defaluts.lastDistanceWalkingRunningDate,
//                                               value: defaluts.lastDistanceWalkingRunning))
//            if defaluts.lastError != "" {
//                let error = NSError(domain: defaluts.lastError, code: 0)
//                entry = Entry(targetSteps: defaluts.targetSteps, statistics: statistics, error: error)
//            } else {
//                entry = Entry(targetSteps: defaluts.targetSteps, statistics: statistics)
//            }
//            let timeline = Timeline(entries: [entry], policy: .atEnd)
//            completion(timeline)
//
//
//
////            if let result = result {
////                // 成功時の値を保存
////                for stat in result {
////                    switch stat.identifier  {
////                    case .stepCount:
////                        defaluts.lastStepCount = stat.value
////                        defaluts.lastStepCountDate = stat.endDate
////                    case .distanceWalkingRunning:
////                        defaluts.lastDistanceWalkingRunning = stat.value
////                        defaluts.lastDistanceWalkingRunningDate = stat.endDate
////                    default: break
////                    }
////                }
////
////                entry = Entry(targetSteps: defaluts.targetSteps, statistics: result)
////            }
////            if let error = error {
////                // エラー時は前回の値を使用する
////                var statistics: [HealthStatistics] = []
////                statistics.append(HealthStatistics(identifier: .stepCount,
////                                                   startDate: defaluts.lastStepCountDate,
////                                                   endDate: defaluts.lastStepCountDate,
////                                                   value: defaluts.lastStepCount))
////                statistics.append(HealthStatistics(identifier: .distanceWalkingRunning,
////                                                   startDate: defaluts.lastDistanceWalkingRunningDate,
////                                                   endDate: defaluts.lastDistanceWalkingRunningDate,
////                                                   value: defaluts.lastDistanceWalkingRunning))
////
////                entry = Entry(targetSteps: defaluts.targetSteps, statistics: statistics, error: error)
////            }
////
//////            let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date()
//////            let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
//////            completion(timeline)
////
////            let timeline = Timeline(entries: [entry], policy: .atEnd)
////            completion(timeline)
////
//        })
    }

    func getSnapshot(in context: Context, completion: @escaping (Entry) -> Void) {
        let stepCount = HealthStatistics(identifier: .stepCount, value: 5000)
        let distanceWalkingRunning = HealthStatistics(identifier: .distanceWalkingRunning, value: 4.0)
        let entry = Entry(date: Date(), statistics: [stepCount, distanceWalkingRunning])
        completion(entry)
    }

    func placeholder(in context: Context) -> Entry {
        let entry = Entry(date: Date(), statistics: [])
        return entry
    }
}

//struct AccessoryProvider: TimelineProvider {
//    var model: HealthModel
//
//    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> Void) {
//        let defaluts = AppDefaults()
//
//        model.fetchTody(identifiers: [.stepCount, .distanceWalkingRunning], completion: { result, error in
//            var entry = Entry()
//
//            if let result = result {
//                // 成功時の値を保存
//                for stat in result {
//                    switch stat.identifier  {
//                    case .stepCount:
//                        defaluts.lastStepCount = stat.value
//                        defaluts.lastStepCountDate = stat.endDate
//                    case .distanceWalkingRunning:
//                        defaluts.lastDistanceWalkingRunning = stat.value
//                        defaluts.lastDistanceWalkingRunningDate = stat.endDate
//                    default: break
//                    }
//                }
//
//                entry = Entry(targetSteps: defaluts.targetSteps, statistics: result)
//            }
//            if let error = error {
//                // エラー時は前回の値を使用する
//                var statistics: [HealthStatistics] = []
//                statistics.append(HealthStatistics(identifier: .stepCount,
//                                                   startDate: defaluts.lastStepCountDate,
//                                                   endDate: defaluts.lastStepCountDate,
//                                                   value: defaluts.lastStepCount))
//                statistics.append(HealthStatistics(identifier: .distanceWalkingRunning,
//                                                   startDate: defaluts.lastDistanceWalkingRunningDate,
//                                                   endDate: defaluts.lastDistanceWalkingRunningDate,
//                                                   value: defaluts.lastDistanceWalkingRunning))
//
//                entry = Entry(targetSteps: defaluts.targetSteps, statistics: statistics, error: error)
//            }
//
////            let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date()
////            let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
////            completion(timeline)
//
//            let timeline = Timeline(entries: [entry], policy: .atEnd)
//            completion(timeline)
//
//        })
//    }
//
//    func getSnapshot(in context: Context, completion: @escaping (Entry) -> Void) {
//        let stepCount = HealthStatistics(identifier: .stepCount, value: 5000)
//        let distanceWalkingRunning = HealthStatistics(identifier: .distanceWalkingRunning, value: 4.0)
//        let entry = Entry(date: Date(), statistics: [stepCount, distanceWalkingRunning])
//        completion(entry)
//    }
//
//    func placeholder(in context: Context) -> Entry {
//        let entry = Entry(date: Date(), statistics: [])
//        return entry
//    }
//}

struct WidgetContentView: View {
    var entry: Entry
    @Environment(\.widgetFamily) var WidgetFamily

    var body: some View {
        switch WidgetFamily {
        case .systemSmall: SystemSmallWidgetView(entry: entry)
        case .systemMedium: SystemMediumWidgetView(entry: entry)
        case .accessoryCircular: AccessoryCircularWidgetView(entry: entry)
        case .accessoryRectangular: AccessoryRectangularWidgetView(entry: entry)
        case .accessoryInline: AccessoryInlineWidgetView(entry: entry)
        default:
            Text(WidgetFamily.description)
        }
    }
}

struct SystemSmallWidgetView: View {
    var entry: Entry

    var body: some View {
        let stepCount = entry.getStatistics(identifier: .stepCount)
        let distanceWalkingRunning = entry.getStatistics(identifier: .distanceWalkingRunning)
        let total: Double = entry.targetSteps
        let steps = stepCount.value
        let percent = total == 0 ? 0 : steps / total

        VStack(alignment: .leading, spacing: 0) {
            HStack {
                // 歩数ゲージ
                Gauge(value: steps, in: 0...total) {
                    Image(systemName: "figure.walk")
                }
                .gaugeStyle(.accessoryCircularCapacity)
                .tint(.green)

                // 達成率
                VStack(alignment: .leading) {
                    HStack {
                        Text((percent).toPercentString(percentSymbol: ""))
                            .font(.title)
                        + Text("%")
                            .font(.body)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    // 計測時刻
                    HStack {
                        Text(stepCount.endDate, style: .time)
                            .font(.caption)
                            .foregroundColor(.gray)
                        + Text("計測")
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                }
            }
            .frame(maxHeight: .infinity)

            // 歩数
            HStack(spacing: 0) {
                Text(stepCount.value, format: .number.precision(.fractionLength(0)))
                    .font(.title3)
                + Text(" / ")
                    .font(.caption2)
                + Text(entry.targetSteps, format: .number.precision(.fractionLength(0)))
                    .font(.caption2)
                + Text("歩")
                    .font(.caption2)
            }

            // 歩行距離
            HStack(spacing: 0) {
                Text(distanceWalkingRunning.value, format: .number.precision(.fractionLength(1)))
                    .font(.title3)
                + Text(" km")
                    .font(.caption)
            }

            // 更新時間
            HStack {
                // エラー時
                if entry.error != nil {
                    HStack(spacing: 0) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.caption2)
                        Text(Date(), style: .offset)
                            .font(.caption2)
                            .foregroundColor(.gray)
                        + Text(" タップで更新")
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                } else {
                    Text(Date(), style: .time)
                        .font(.caption2)
                        .foregroundColor(.gray)
                    + Text("表示")
                        .font(.caption2)
                        .foregroundColor(.gray)
                    + Text(Date(), style: .offset)
                        .font(.caption2)
                        .foregroundColor(.gray)
                    + Text("経過")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(EdgeInsets(top: 14, leading: 14, bottom: 14, trailing: 4))
    }
}

struct SystemMediumWidgetView: View {
    var entry: Entry
//    var chartData = ChartData(data: [
//        .init(label: "Sun", value: 9000),
//        .init(label: "Mon", value: 5000),
//        .init(label: "Tue", value: 7000),
//        .init(label: "Wed", value: 4000),
//        .init(label: "Thu", value: 3000),
//        .init(label: "Fri", value: 8000),
//        .init(label: "Sat", value: 13000)
//    ])

    var body: some View {
        HStack(spacing: 0) {
            SystemSmallWidgetView(entry: entry)
            LineChartView(data: Entry.chartData, stacked: true, target: entry.targetSteps, xAxis: false, yAxis: false)
                .frame(maxWidth: .infinity)
                .padding(EdgeInsets(top: 16, leading: 0, bottom: 16, trailing: 16))
        }
    }
}

struct AccessoryCircularWidgetView: View {
    var entry: Entry

    var body: some View {
        let stepCount = entry.getStatistics(identifier: .stepCount)
        let steps = stepCount.value
        let total = entry.targetSteps

        Gauge(value: steps, in: 0...total) {
            if entry.error == nil {
                Image(systemName: "figure.walk")
                    .font(.headline)
                    .offset(y: 1)
            } else {
                ZStack {
                    Image(systemName: "figure.walk")
                        .font(.headline)
                        .offset(x: -4, y: 1)
                    Image(systemName: "exclamationmark.triangle.fill")
                        .offset(x: 4, y: 0)
                }
            }
        } currentValueLabel: {
            VStack(spacing: 0) {
                if AppDefaults().showOffsetTime {
                    Text(steps, format: .number.precision(.fractionLength(0)))
                        .font(.headline)
                        .offset(y: 2)
                    Text(Date(), style: .offset)
                        .multilineTextAlignment(.center)
                        .font(.caption)
                        .offset(y: -2)
                } else {
                    Text(steps, format: .number.precision(.fractionLength(0)))
                        .font(.headline)
                }
            }
        }
        .gaugeStyle(.accessoryCircular)
    }
}

struct AccessoryRectangularWidgetView: View {
    var entry: Entry

    var body: some View {
        let stepCount = entry.getStatistics(identifier: .stepCount)
        let steps = stepCount.value
        let total = entry.targetSteps
        //let km = entry.getStatistics(identifier: .distanceWalkingRunning)
        
        HStack(spacing: 0) {
            AccessoryCircularWidgetView(entry: entry)
//            Gauge(value: steps, in: 0...total) {
//                Image(systemName: "figure.walk")
//                    .font(.headline)
//            } currentValueLabel: {
//                Text(steps, format: .number.precision(.fractionLength(0)))
//                    .font(.headline)
//            }
//            .gaugeStyle(.accessoryCircular)


        LineChartView(data: Entry.chartData, stacked: true, target: entry.targetSteps, xAxis: false, yAxis: false)
                .frame(maxWidth: .infinity)
            
//            VStack(alignment: .leading, spacing: 0) {
//                HStack(spacing: 0) {
//                    if entry.error == nil {
//                        Text(km.value, format: .number.precision(.fractionLength(1)))
//                        + Text(" km")
//                            .font(.caption)
//                    } else {
//                        HStack(spacing: 0) {
//                            Image(systemName: "exclamationmark.triangle.fill")
//                                .font(.caption2)
//                            Text("タップで更新")
//                                .font(.caption2)
//                        }
//                    }
//                }
//                HStack(spacing: 0) {
//                    Text(stepCount.endDate, style: .time)
//                    + Text(" 計測")
//                        .font(.caption)
//                }
//                HStack(spacing: 0) {
//                    Text(Date(), style: .time)
//                    + Text(Date(), style: .offset)
//                        .font(.caption)
//                }
//            }
//            .padding(.leading, 6)
        }
    }
}

struct AccessoryInlineWidgetView: View {
    var entry: Entry

    var body: some View {
        let stepCount = entry.getStatistics(identifier: .stepCount)
        let km = entry.getStatistics(identifier: .distanceWalkingRunning)
        
        HStack(spacing: 0) {
            if entry.error == nil {
                Image(systemName: "figure.walk")
            } else {
                Image(systemName: "exclamationmark.triangle.fill")
            }
            Text(stepCount.value, format: .number.precision(.fractionLength(0)))
            + Text("歩 ")
            + Text(km.value, format: .number.precision(.fractionLength(1)))
            + Text("km ")
        }
    }
}

@main
struct WalklyWedget: Widget {
    private let kind = AppDefaults.widgetKind
    private let model = HealthAsyncModel()

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider(model: model), content: { entry in
            WidgetContentView(entry: entry)
        }).description(Text("Appleヘルスケアのデータを元に歩数や関連情報を表示します"))
            .configurationDisplayName(Text("歩数の表示"))
            .supportedFamilies([.systemSmall, .systemMedium,
                                .accessoryCircular, .accessoryRectangular, .accessoryInline])
    }
}

//struct WalklyAccessoryWedget: Widget {
//    private let kind = AppDefaults.accessoryWidgetKind
//    private let model = HealthModel()
//
//    var body: some WidgetConfiguration {
//        StaticConfiguration(kind: kind, provider: AccessoryProvider(model: model), content: { entry in
//            WidgetContentView(entry: entry)
//        }).description(Text("Appleヘルスケアのデータを元に歩数や関連情報を表示します"))
//            .configurationDisplayName(Text("歩数の表示"))
//            .supportedFamilies([.accessoryCircular, .accessoryRectangular, .accessoryInline])
//    }
//}
//
//@main
//struct ExampleWidgets: WidgetBundle {
//    @WidgetBundleBuilder
//    var body: some Widget {
//        //WalklyWedget()
//        WalklyAccessoryWedget()
//    }
//}

struct WalklyWedget_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            WidgetContentView(entry: Entry(date: Date(), statistics: []))
                .previewContext(WidgetPreviewContext(family: .systemMedium))
                .previewDisplayName("systemMedium")
            WidgetContentView(entry: Entry(date: Date(), statistics: []))
                .previewContext(WidgetPreviewContext(family: .systemSmall))
                .previewDisplayName("systemSmall")
            WidgetContentView(entry: Entry(date: Date(), statistics: []))
                .previewContext(WidgetPreviewContext(family: .accessoryRectangular))
                .previewDisplayName("accessoryRectangular")
            WidgetContentView(entry: Entry(date: Date(), statistics: []))
                .previewContext(WidgetPreviewContext(family: .accessoryCircular))
                .previewDisplayName("accessoryCircular")
        }
        .environment(\.locale, .init(identifier: "ja"))
    }
}


//// スケルトン
//struct Provider: IntentTimelineProvider {
//    func placeholder(in context: Context) -> SimpleEntry {
//        SimpleEntry(date: Date(), configuration: ConfigurationIntent())
//    }
//
//    func getSnapshot(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (SimpleEntry) -> ()) {
//        let entry = SimpleEntry(date: Date(), configuration: configuration)
//        completion(entry)
//    }
//
//    func getTimeline(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
//        var entries: [SimpleEntry] = []
//
//        // Generate a timeline consisting of five entries an hour apart, starting from the current date.
//        let currentDate = Date()
//        for hourOffset in 0 ..< 5 {
//            let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
//            let entry = SimpleEntry(date: entryDate, configuration: configuration)
//            entries.append(entry)
//        }
//
//        let timeline = Timeline(entries: entries, policy: .atEnd)
//        completion(timeline)
//    }
//}
//
//struct SimpleEntry: TimelineEntry {
//    let date: Date
//    let configuration: ConfigurationIntent
//}
//
//struct WalklyWidgetEntryView : View {
//    var entry: Provider.Entry
//
//    var body: some View {
//        VStack {
//            Text(entry.date, style: .time)
//            Text(entry.date, style: .offset)
//                .multilineTextAlignment(.center)
//        }
//    }
//}
//
//@main
//struct WalklyWidget: Widget {
//    let kind: String = "WalklyWidget"
//
//    var body: some WidgetConfiguration {
//        IntentConfiguration(kind: kind, intent: ConfigurationIntent.self, provider: Provider()) { entry in
//            WalklyWidgetEntryView(entry: entry)
//        }
//        .configurationDisplayName("My Widget")
//        .description("This is an example widget.")
//    }
//}
//
//struct WalklyWidget_Previews: PreviewProvider {
//    static var previews: some View {
//        WalklyWidgetEntryView(entry: SimpleEntry(date: Date(), configuration: ConfigurationIntent()))
//            .previewContext(WidgetPreviewContext(family: .systemSmall))
//    }
//}
