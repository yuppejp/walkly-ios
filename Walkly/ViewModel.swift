//
//  ViewModel.swift
//  Walkly
//
//  Created on 2022/10/10.
//  
//

import SwiftUI
import HealthKit
import WidgetKit

class ListRowItem: ObservableObject, Identifiable {
    var id = UUID()
    @Published var date: Date
    @Published var value: String
    @Published var description: String

    init(date: Date, value: String, description: String = "") {
        self.date = date
        self.value = value
        self.description = description
    }
}

class Statistics: ObservableObject {
    @Published var date: Date
    @Published var value: Double
    
    init(date: Date = Date(), value: Double = 0) {
        self.date = date
        self.value = value
    }

    init(_ statics: HealthStatistics) {
        self.date = statics.endDate
        self.value = statics.value
    }
}

class ViewModel: ObservableObject, Identifiable {
    let model = HealthModel()
    var fetchDays = 1
    //@Published var dataSource: [ListRowItem] = []
    //@Published var stepHistory: [ListRowItem] = []
    @Published var stepCount: Statistics = Statistics()
    @Published var distanceWalkingRunning: Statistics = Statistics()
    @Published var activeEnergyBurned: Statistics = Statistics()
    @Published var appleExerciseTime: Statistics = Statistics()
    @Published var healthKitError: Error?
    @Published var chartData: ChartData = ChartData(data: [])

    func autoUpdate() {
        let identifiers: [HKQuantityTypeIdentifier] = [.stepCount/*, .oxygenSaturation*/]

        model.enableUpdateHandler(identifiers: identifiers, updateHandler: { (query, completionHandler, error) in
            DispatchQueue.main.async {
                if let error = error {
                    print(error.localizedDescription)
                    self.healthKitError = error
                } else {
                    self.healthKitError = nil
                    self.fetchTody()
                    self.fetchPeriod(days: self.fetchDays)
                }
                completionHandler()
            }
        })
    }
    
    func fetchTody() {
        let identifiers: [HKQuantityTypeIdentifier] = [
            .stepCount, .distanceWalkingRunning, .activeEnergyBurned, .appleExerciseTime//, .walkingStepLength, .walkingHeartRateAverage, .oxygenSaturation
        ]
        
        model.fetchTody(identifiers: identifiers, completion: { result, error in
            let defaults = AppDefaults()

            if let error = error {
                print(error.localizedDescription)
                return
            }
            
            if let result = result {
                DispatchQueue.main.async {
                    if result.count == 0 {
                        // 今日のデータがない場合は0クリア
                        self.stepCount = Statistics()
                        self.distanceWalkingRunning = Statistics()
                        self.activeEnergyBurned = Statistics()
                        self.appleExerciseTime = Statistics()
                        //self.dataSource.removeAll()
                    }
                    
                    for statistics in result {
                        switch statistics.identifier {
                        case .stepCount:
                            //let item = ListRowItem(date: statistics.endDate, value: statistics.value.toIntegerString(), description: "歩数")
                            //self.dataSource.append(item)
                            self.stepCount = Statistics(statistics)
                            
                            // ウィジェットと共有用
                            defaults.lastStepCount = statistics.value
                            defaults.lastStepCountDate = statistics.endDate
                            
                        case .distanceWalkingRunning:
                            //let item = ListRowItem(date: statistics.endDate, value: statistics.value.toDecimalString(0, 2), description: "移動距離")
                            //self.dataSource.append(item)
                            self.distanceWalkingRunning = Statistics(statistics)
                            
                            // ウィジェットと共有用
                            defaults.lastDistanceWalkingRunning = statistics.value
                            defaults.lastDistanceWalkingRunningDate = statistics.endDate
                            
                        case .activeEnergyBurned:
                            //let item = ListRowItem(date: statistics.endDate, value: statistics.value.toDecimalString(0, 1), description: "アクティビティエネルギー")
                            //self.dataSource.append(item)
                            self.activeEnergyBurned = Statistics(statistics)
                            
                        case .appleExerciseTime:
                            //let item = ListRowItem(date: statistics.endDate, value: statistics.value.toIntegerString(), description: "エクササイズ時間")
                            //self.dataSource.append(item)
                            self.appleExerciseTime = Statistics(statistics)
                            
//                        case .walkingStepLength:
//                            //let item = ListRowItem(date: statistics.endDate, value: statistics.value.toIntegerString(), description: "歩幅")
//                            //self.dataSource.append(item)
//
//                        case .walkingHeartRateAverage:
//                            //let item = ListRowItem(date: statistics.endDate, value: statistics.value.toIntegerString(), description: "歩行時平均心拍数")
//                            //self.dataSource.append(item)
//
//                        case .oxygenSaturation:
//                            //let item = ListRowItem(date: statistics.endDate, value: statistics.value.toPercentString(), description: "血中酸素濃度")
//                            //self.dataSource.append(item)
                            
                        default:
                            print(statistics.identifier)
                        }
                    }
                }
            }
        })
    }
    
    func fetchPeriod(days: Int?) {
        if let days = days {
            if fetchDays != days {
                fetchDays = days
                chartData.items.removeAll()
            }
        }
        
        let startOfToday = Calendar.current.startOfDay(for: Date())
        let lastWeek = Calendar.current.date(byAdding: .day, value: -7, to: startOfToday) ?? Date()
//        let startOfWeek = Calendar.current.(for: Date())
        var from = Date()
        let to = Date()
        var anchor = Date()
        var interval = DateComponents()
        // let interval = DateComponents(minute: 1)
        // let interval = DateComponents(hour: 1)
        
        switch fetchDays {
        case 1:
            from = startOfToday
            anchor = startOfToday
            interval = DateComponents(hour: 1)
        case 6:
            from = Calendar.current.date(byAdding: .day, value: -6, to: startOfToday) ?? Date()
            anchor = from
            interval = DateComponents(day: 1)
        case 7:
            from = Calendar.current.date(byAdding: .day, value: -7, to: startOfToday) ?? Date()
            anchor = from
            interval = DateComponents(day: 1)
        case 30:
            from = Calendar.current.date(byAdding: .month, value: -1, to: startOfToday) ?? Date()
            anchor = from
            interval = DateComponents(day: 1)
        case 365:
            from = Calendar.current.date(byAdding: .year, value: -1, to: startOfToday) ?? Date()
            anchor = from
            interval = DateComponents(month: 1)
        case 999:
            from = Calendar.current.date(byAdding: .year, value: -10, to: startOfToday) ?? Date()
            anchor = from
            interval = DateComponents(year: 1)
        default:
            print("error")
        }
        
        model.fetchPeriod(identifier: .stepCount, from: from, to: to, anchor: anchor, interval: interval, completion: { results, error in
            if let results = results {
                DispatchQueue.main.async {
                    if results.count != self.chartData.items.count {
                        // データの個数が変わった場合はオールクリア
                        self.chartData.items.removeAll()
                        
//                        if results.count == 0 {
//                            // 日足の場合は現在時間を0にセット
//                            if self.fetchDays == 1 {
//                                let now = Date()
//                                let label = now.toString("H")
//                                let item = ChartDataItem(label: label, value: 0.0)
//                                self.chartData.items.append(item)
//                            }
//                        }
                    }
                    
                    for result in results {
                        //print("***** startDate: \(result.startDate.toString()), endDate: \(result.endDate.toString()), value: \(result.value)")
                        
                        var label = ""
                        
                        switch self.fetchDays {
                        case 1:
                            // 時間
                            //let formatter = DateFormatter()
                            //formatter.dateFormat = DateFormatter.dateFormat(fromTemplate: "H", options: 0, locale: Locale(identifier: "ja_JP"))
                            //label = formatter.string(from: result.startDate)
                            label = result.startDate.toString("H")
                        case 6, 7:
                            // 曜日
                            let formatter = DateFormatter()
                            formatter.dateFormat = DateFormatter.dateFormat(fromTemplate: "EEEEEE", options: 0, locale: Locale(identifier: "ja_JP"))
                            label = formatter.string(from: result.startDate)
                            
                            // ラベル名が重複しているとグラフがグループされれるため重複しない名前に変更
                            if result.startDate <= lastWeek {
                                label = " " + label
                            }
                            
                        case 30:
                            // 日
                            let formatter = DateFormatter()
                            formatter.dateFormat = DateFormatter.dateFormat(fromTemplate: "d", options: 0, locale: Locale(identifier: "ja_JP"))
                            label = formatter.string(from: result.startDate)
                        case 365:
                            // 月
                            let formatter = DateFormatter()
                            formatter.dateFormat = DateFormatter.dateFormat(fromTemplate: "M", options: 0, locale: Locale(identifier: "ja_JP"))
                            label = formatter.string(from: result.endDate)
                        case 999:
                            // 年
                            let formatter = DateFormatter()
                            formatter.dateFormat = DateFormatter.dateFormat(fromTemplate: "y", options: 0, locale: Locale(identifier: "ja_JP"))
                            label = formatter.string(from: result.endDate)
                        default:
                            print("error")
                        }
                        
                        var found = false
                        for i in 0 ..< self.chartData.items.count {
                            // 既存のデータラベルがあれば値だけ更新する
                            if self.chartData.items[i].label == label {
                                self.chartData.items[i].value = result.value
                                found = true
                                break
                            }
                        }
                        if !found {
                            // 見つからない場合は追加
                            let item = ChartDataItem(label: label, value: result.value)
                            self.chartData.items.append(item)
                        }
                    }
                }
            }
        })
    }
}
