//
//  HealthModel.swift
//  Walkly
//
//  Created on 2022/10/10.
//  
//

import Foundation
import HealthKit

// HealthKitの組み込み方法
// https://kita-note.com/xcode-config-healthkit

class HealthStatistics {
    var startDate: Date
    var endDate: Date
    var identifier: HKQuantityTypeIdentifier
    var value: Double
    
    init(identifier: HKQuantityTypeIdentifier = .stepCount, startDate: Date = Date(), endDate: Date = Date(), value: Double = 0) {
        self.startDate = startDate
        self.endDate = endDate
        self.identifier = identifier
        self.value = value
    }
    
//    static func get(statistics: [HealthStatistics], identifier: HKQuantityTypeIdentifier) -> HealthStatistics? {
//        for stat in statistics {
//            if stat.identifier == identifier {
//                return stat
//            }
//        }
//        return nil // not found
//    }
}

class HealthModel {
    let healthStore = HKHealthStore()
    static var debugCount = 0.0

    func enableUpdateHandler(identifiers: [HKQuantityTypeIdentifier], updateHandler: @escaping (HKObserverQuery, @escaping HKObserverQueryCompletionHandler, Error?) -> Void) {
        // REF: https://qiita.com/dotrikun/items/73db477f8fb23f9d783b
        
        requestAuthorization(identifiers: identifiers, completion: { (status, error) in
            if let error = error {
                print(error.localizedDescription)
                return
            }
            
            for identifier in identifiers {
                let objectType = HKSampleType.quantityType(forIdentifier: identifier)!
                let query = HKObserverQuery(sampleType: objectType, predicate: nil, updateHandler: { query, completionHandler, error in
                    // 更新検知
                    updateHandler(query, completionHandler, error)
                })
                self.healthStore.execute(query)

                // バックグランドでのヘルスケアデータの更新検知を有効にする
                self.healthStore.enableBackgroundDelivery(for: objectType, frequency: .immediate, withCompletion: { success, error in
                    if success {
                        print("Enabled background delivery.")
                    } else {
                        if let error = error {
                            print("Failed to enable background delivery.")
                            print("Error = \(error)")
                        }
                    }
                })
            }
        })
    }

    private func requestAuthorization(identifiers: [HKQuantityTypeIdentifier], completion: @escaping (HKAuthorizationRequestStatus?, Error?) -> ()) {
        var readTypes: Set<HKQuantityType> = []
        
        for identifier in identifiers {
            readTypes.insert(HKQuantityType.quantityType(forIdentifier: identifier)!)
        }
        
        healthStore.getRequestStatusForAuthorization(toShare: [], read: readTypes, completion: { status, error in
            if let error = error {
                completion(status, error)
                return
            }
            
            switch status {
            case .shouldRequest:
                print("requestAuthorization: shouldRequest")
                
                // ユーザーに許可を求める
                self.healthStore.requestAuthorization(toShare: [], read: readTypes, completion: { success, error in
                    if let error = error {
                        print("[requestAuthorization] error: ", error.localizedDescription)
                        completion(nil, error)
                        return
                    }
                    
                    // もう一度状態を確認
                    self.healthStore.getRequestStatusForAuthorization(toShare: [], read: readTypes, completion: { status, error in
                        completion(status, error)
                    })
                })
                
            case .unnecessary:
                print("requestAuthorization: unnecessary")
                completion(status, error)
                
            case .unknown:
                print("requestAuthorization: unknown")
                completion(status, error)

            default:
                print("requestAuthorization: \(status)")
                completion(status, error)
            }
        })
    }
    
    private func getRequestStatusForAuthorization(identifiers: [HKQuantityTypeIdentifier], completion: @escaping (HKAuthorizationRequestStatus?, Error?) -> ()) {
        var readTypes: Set<HKQuantityType> = []
        
        for identifier in identifiers {
            readTypes.insert(HKQuantityType.quantityType(forIdentifier: identifier)!)
        }

        healthStore.getRequestStatusForAuthorization(toShare: [], read: readTypes, completion: { status, error in
            completion(status, error)
        })
    }

    private func requestAuthorization(read: Set<HKObjectType>, completion: @escaping (Bool?, Error?) -> ()) {
        healthStore.requestAuthorization(toShare: [], read: read, completion: { status, error in
            completion(status, error)
        })
    }

    func fetchTody(identifiers: [HKQuantityTypeIdentifier], completion: @escaping ([HealthStatistics]?, Error?) -> ()) {

        requestAuthorization(identifiers: identifiers, completion: { success, error in
            var results: [HealthStatistics] = []

            if let error = error {
                completion(nil, error)
                return
            }

#if targetEnvironment(simulator)
            // demo data
            let today = Calendar.current.startOfDay(for: Date())
            let startDate = Calendar.current.date(bySettingHour: 18, minute: 0, second: 0, of: today) ?? today
            let endDate = Calendar.current.date(bySettingHour: 18, minute: 51, second: 0, of: today) ?? today
            let steps = HealthStatistics(identifier: .stepCount, startDate: startDate, endDate: endDate, value: 5000)
            let km = HealthStatistics(identifier: .distanceWalkingRunning, startDate: startDate, endDate: endDate, value: 3.1)
            let burned = HealthStatistics(identifier: .activeEnergyBurned, startDate: startDate, endDate: endDate, value: 321.9)
            let time = HealthStatistics(identifier: .appleExerciseTime, startDate: startDate, endDate: endDate, value: 28)
            results.append(steps)
            results.append(km)
            results.append(burned)
            results.append(time)
            completion(results, nil)
            return
#else
            var resultCount = 0
            for identifier in identifiers {
                self.queryToday(healthStore: self.healthStore, identifier: identifier, completion: { result, error in
                    resultCount += 1
                    if let nsError = error as? NSError {
                        // errorNoData は想定内のためエラーにしない
                        if nsError.code != HKError.Code.errorNoData.rawValue {
                            completion(nil, error)
                            return
                        }
                    }
                    if let result = result {
                        results.append(result)
                    }
                    if identifiers.count == resultCount {
                        completion(results, nil)
                    }
                })
            }
#endif
        })
    }

//    func fetchTody(identifiers: [HKQuantityTypeIdentifier], completion: @escaping ([HealthStatistics]?, Error?) -> ()) {
//
////        // demo data
////        var results: [HealthStatistics] = []
////        let startDate = Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date() // 昨日
////        let endDate = Date()
////        let steps = HealthStatistics(identifier: .stepCount, startDate: startDate, endDate: endDate, value: 20_000 /*5_000*/)
////        let km = HealthStatistics(identifier: .distanceWalkingRunning, startDate: startDate, endDate: endDate, value: 3.1)
////        results.append(steps)
////        results.append(km)
////        completion(results, nil)
////        return
//
//        requestAuthorization(identifiers: identifiers, completion: { success, error in
//            let defaluts = AppDefaults()
//
//            if let error = error {
//                defaluts.lastError = error.localizedDescription
//                completion(nil, error)
//                return
//            }
//
//            self.fetchOneTody(identifier: .stepCount, completion: { result, error in
//                if let result = result {
//                    defaluts.lastError = ""
//                    defaluts.lastStepCount = result.value
//                    defaluts.lastStepCountDate = result.endDate
//                }
//            })
//
//            completion([], nil)
//        })
//
//
////        requestAuthorization(identifiers: identifiers, completion: { success, error in
////            var results: [HealthStatistics] = []
////
////            if let error = error {
////                completion(nil, error)
////                return
////            }
////
////            var index = 0
////            self.fetchOneTody(identifier: identifiers[index], completion: { result, error in
////                if let error = error {
////                    completion(nil, error)
////                    return
////                }
////                if let result = result {
////                    results.append(result)
////
////                    index += 1
////                    self.fetchOneTody(identifier: identifiers[index], completion: { result, error in
////                        if let error = error {
////                            completion(results, error)
////                            return
////                        }
////                        if let result = result {
////                            results.append(result)
////                            completion(results, nil)
////                        } else {
////                            completion(results, error)
////                        }
////                    })
////                }
////            })
////        })
//    }
//
//    func fetchOneTody(identifier: HKQuantityTypeIdentifier, completion: @escaping (HealthStatistics?, Error?) -> ()) {
//
//        requestAuthorization(identifiers: [identifier], completion: { success, error in
//            if let error = error {
//                completion(nil, error)
//                return
//            }
//
//#if targetEnvironment(simulator)
//            // demo data
//            let startDate = Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date() // 昨日
//            let endDate = Date()
//            switch identifier {
//            case .stepCount:
//                let steps = HealthStatistics(identifier: .stepCount, startDate: startDate, endDate: endDate, value: 20_000 /*5_000*/)
//                completion(steps, nil)
//            case .stepCount:
//                let km = HealthStatistics(identifier: .distanceWalkingRunning, startDate: startDate, endDate: endDate, value: 3.1)
//                completion(km, nil)
//            default:
//                let error = NSError(domain: "[fetchOneTody] Unknown HKQuantityTypeIdentifier", code: identifier.rawValue)
//                completion(nil, nil)
//            }
//#else
//            self.queryToday(healthStore: self.healthStore, identifier: identifier, completion: { result, error in
//                if let nsError = error as? NSError {
//                    // errorNoData は想定内のためエラーにしない
//                    if nsError.code == HKError.Code.errorNoData.rawValue {
//                        let now = Date()
//                        let result = HealthStatistics(identifier: identifier, startDate: now, endDate: now, value: 0.0)
//                        completion(result, nil)
//                    } else {
//                        completion(nil, error)
//                    }
//                }
//                if let result = result {
//                    completion(result, nil)
//                } else {
//                    completion(nil, error)
//                }
//            })
//#endif
//        })
//    }


    private func queryToday(healthStore: HKHealthStore, identifier: HKQuantityTypeIdentifier, completion: @escaping (HealthStatistics?, Error?) -> ()) {
        let calendar = Calendar(identifier: .gregorian)
        let from = calendar.date(bySettingHour: 0, minute: 0, second: 0, of: Date() /* - (60 * 60 * 24) */)
        let to = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: Date() /*  - (60 * 60 * 24) */)
        
        let type = HKSampleType.quantityType(forIdentifier: identifier)!
        let predicate = HKQuery.predicateForSamples(withStart: from, end: to)
        
        var options: HKStatisticsOptions
        switch identifier {
        case .stepCount, .distanceWalkingRunning, .activeEnergyBurned, .appleExerciseTime:
            options = [.cumulativeSum]
        case .walkingStepLength, .walkingHeartRateAverage, .oxygenSaturation:
            options = [.discreteAverage]
        default:
            options = []
        }
        
        let query = HKStatisticsQuery(quantityType: type,
                                      quantitySamplePredicate: predicate,
                                      options: options) { (query, statistics, error) in
            if let error = error {
                print("[getTody@HKStatisticsQuery] error: ", error.localizedDescription)
                completion(nil, error)
            }
            
            if let statistics = statistics {
                var value = 0.0
                
                switch identifier {
                case .stepCount:
                    if let quantity = statistics.sumQuantity() {
                        value = quantity.doubleValue(for: .count())
                    }
                case .distanceWalkingRunning:
                    if let quantity = statistics.sumQuantity() {
                        value = quantity.doubleValue(for: .meterUnit(with: .kilo))
                    }
                case .activeEnergyBurned:
                    if let quantity = statistics.sumQuantity() {
                        value = quantity.doubleValue(for: .kilocalorie())
                    }
                case .appleExerciseTime:
                    if let quantity = statistics.sumQuantity() {
                        value = quantity.doubleValue(for: .minute())
                    }
                    
                case .walkingStepLength:
                    if let quantity = statistics.averageQuantity() {
                        value = quantity.doubleValue(for: .meterUnit(with: .centi))
                    }
                case .walkingHeartRateAverage:
                    if let quantity = statistics.averageQuantity() {
                        value = quantity.doubleValue(for: HKUnit(from: "count/min"))
                    }
                case .oxygenSaturation:
                    if let quantity = statistics.averageQuantity() {
                        value = quantity.doubleValue(for: .percent())
                    }
                default:
                    print("[getTody@startDate] Unkown identifier: ", identifier)
                }
                
                let result = HealthStatistics(identifier: identifier,
                                              startDate: statistics.startDate,
                                              endDate: statistics.endDate,
                                              value: value)
                
                completion(result, nil)
            }
        }
        healthStore.execute(query)
    }
    
    func fetchPeriod(identifier: HKQuantityTypeIdentifier, from: Date, to: Date, anchor: Date,
                     interval: DateComponents, completion: @escaping ([HealthStatistics]?, Error?) -> ()) {
        
        // https://zenn.dev/ueshun/scraps/90fbb43a2bb3d7
        let healthStore = HKHealthStore()
//        let readTypes = Set([
//            HKQuantityType.quantityType(forIdentifier: identifier)!
//        ])
        
        requestAuthorization(identifiers: [identifier], completion: { success, error in
            if let error = error {
                completion(nil, error)
            }
            
            // 取得間隔
            //let interval = DateComponents(day: 1)
            //let interval = DateComponents(hour: 1)
            //let interval = DateComponents(minute: 1)

    //        // アンカーポイントの日付を月曜日の午前0時に設定
    //        let calendar = Calendar.current
    //        let components = DateComponents(
    //            calendar: calendar,
    //            timeZone: calendar.timeZone,
    //            hour: 0,
    //            minute: 0,
    //            second: 0,
    //            weekday: 2
    //        )
    //
    //        // アンカーポイントを直前の月曜に補正
    //        let anchorDate = calendar.nextDate(
    //            after: Date(),
    //            matching: components,
    //            matchingPolicy: .nextTime,
    //            repeatedTimePolicy: .first,
    //            direction: .backward) ?? Date()
    //        let anchorDate = Calendar.current.startOfDay(for: Date())

            var options: HKStatisticsOptions
            if identifier == .walkingStepLength {
                options = [.discreteAverage ]
            } else {
                options = [.cumulativeSum ]
            }
            
            let query = HKStatisticsCollectionQuery(
                quantityType: .quantityType(forIdentifier: identifier)!,
                quantitySamplePredicate: nil,
                options: options,
                anchorDate: anchor,
                intervalComponents: interval
            )

            query.initialResultsHandler = { query, collection, error in
                var result: [HealthStatistics] = []
                
                if let collection = collection {
                    collection.enumerateStatistics(from: from, to: to) { stats, stop in
                        let startDate = stats.startDate
                        let endDate = stats.endDate

                        switch identifier {
                        case .stepCount:
                            if let quantity = stats.sumQuantity() {
                                let value = quantity.doubleValue(for: .count())
                                //print("date: \(self.toDateString(date)), value: \(value)")
                                //print("***** identifier: \(identifier.rawValue), start: \(stats.startDate.toString()), end\(stats.endDate.toString()) value: \(value)")
                                result.append(HealthStatistics(identifier: identifier, startDate: startDate, endDate: endDate, value: value))
                            }
                        case .distanceWalkingRunning:
                            if let quantity = stats.sumQuantity() {
                                let value = quantity.doubleValue(for: .meterUnit(with: .none))
                                result.append(HealthStatistics(identifier: identifier, startDate: startDate, endDate: endDate, value: value))
                            }
                        case .walkingStepLength:
                            if let quantity = stats.averageQuantity() {
                                let value = quantity.doubleValue(for: .meterUnit(with: .none))
                                result.append(HealthStatistics(identifier: identifier, startDate: startDate, endDate: endDate, value: value))
                            }
                        default:
                            print("[enumerateStatistics] Unkown identifier: ", identifier)
                        }
                    }
                }

#if targetEnvironment(simulator)
                // demo
                let demoSteps: [Double] = [90.0, 1000.0, 200.0, 70.0, 20.0, 1000.0, 120.0, 100.0, 200.0, 100, 500, 1600.0]
                let today = Calendar.current.startOfDay(for: Date())
                var i = 0
                for hour in 7 ..< 19 {
                    let startDate = Calendar.current.date(byAdding: .hour, value: hour, to: today) ?? Date()
                    let endDate = Calendar.current.date(byAdding: .minute, value: 59, to: startDate) ?? Date()

                    switch identifier {
                    case .stepCount:
                        let steps = HealthStatistics(identifier: identifier, startDate: startDate, endDate: endDate, value: demoSteps[i])
                        result.append(steps)
                    case .distanceWalkingRunning:
                        let km = HealthStatistics(identifier: identifier, startDate: startDate, endDate: endDate, value: Double.random(in: 0.1...2.0))
                        result.append(km)
                    case .walkingStepLength:
                        let length = HealthStatistics(identifier: identifier, startDate: startDate, endDate: endDate, value: Double.random(in: 0.1...2.0))
                        result.append(length)
                    default: break
                    }
                    i += 1
                }
#endif
                completion(result, nil)
            }
            healthStore.execute(query)
        })
    }
    
    func fetchSumTest(fromDate: Date, toDate: Date) {
        let readTypes = Set([
            HKQuantityType.quantityType(forIdentifier: .stepCount )!
        ])
        
        healthStore.requestAuthorization(toShare: [], read: readTypes, completion: { success, error in
            if success == false {
                print("データにアクセスできません")
                return
            }

            // 歩数を取得
            let type = HKSampleType.quantityType(forIdentifier: .stepCount)!
            let predicate = HKQuery.predicateForSamples(withStart: fromDate, end: toDate)
            let query = HKStatisticsQuery(quantityType: type,
                                          quantitySamplePredicate: predicate,
                                          options: .cumulativeSum) { query, statistics, error in
                guard error == nil else {
                    print("error")
                    return
                }

                print("sumQuantity: ------------------------")
                if let sum = statistics?.sumQuantity()?.doubleValue(for: HKUnit.count()) {
                    print("sumQuantity: " + String(sum))
                }
                print("sumQuantity: ------------------------")
            }
            self.healthStore.execute(query)
        })
    }
}
