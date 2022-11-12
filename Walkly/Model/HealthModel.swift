//
//  HealthModel.swift
//  Walkly
//
//  Created on 2022/10/10.
//  
//

import Foundation
import HealthKit

// REF: https://kita-note.com/xcode-config-healthkit

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
}

class HealthModel {
    let healthStore = HKHealthStore()
    static var debugCount = 0.0

    func isAvailable() -> Bool {
        return HKHealthStore.isHealthDataAvailable()
    }
    
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
                    // update detection
                    updateHandler(query, completionHandler, error)
                })
                self.healthStore.execute(query)

                // Enable Background Health Data Update Detection
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
                
                // ask user for permission
                self.healthStore.requestAuthorization(toShare: [], read: readTypes, completion: { success, error in
                    if let error = error {
                        print("[requestAuthorization] error: ", error.localizedDescription)
                        completion(nil, error)
                        return
                    }
                    
                    // check status again
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
                self.queryToday(identifier: identifier, completion: { result, error in
                    resultCount += 1
                    if let nsError = error as? NSError {
                        // errorNoData is not an error because it is within expectations
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

    private func queryToday(identifier: HKQuantityTypeIdentifier, completion: @escaping (HealthStatistics?, Error?) -> ()) {
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        let type = HKSampleType.quantityType(forIdentifier: identifier)!
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
        
        // REF: https://zenn.dev/ueshun/scraps/90fbb43a2bb3d7
        let healthStore = HKHealthStore()
        
        requestAuthorization(identifiers: [identifier], completion: { success, error in
            if let error = error {
                completion(nil, error)
            }
            
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
                                let value = quantity.doubleValue(for: .meterUnit(with: .kilo))
                                result.append(HealthStatistics(identifier: identifier, startDate: startDate, endDate: endDate, value: value))
                            }
                        case .walkingStepLength:
                            if let quantity = stats.averageQuantity() {
                                let value = quantity.doubleValue(for: .meterUnit(with: .centi))
                                result.append(HealthStatistics(identifier: identifier, startDate: startDate, endDate: endDate, value: value))
                            }
                        case .activeEnergyBurned:
                            if let quantity = stats.sumQuantity() {
                                let value = quantity.doubleValue(for: .kilocalorie())
                                result.append(HealthStatistics(identifier: identifier, startDate: startDate, endDate: endDate, value: value))
                            }
                        case .appleExerciseTime:
                            if let quantity = stats.sumQuantity() {
                                let value = quantity.doubleValue(for: .minute())
                                result.append(HealthStatistics(identifier: identifier, startDate: startDate, endDate: endDate, value: value))
                            }
                        case .walkingHeartRateAverage:
                            if let quantity = stats.averageQuantity() {
                                let value = quantity.doubleValue(for: HKUnit(from: "count/min"))
                                result.append(HealthStatistics(identifier: identifier, startDate: startDate, endDate: endDate, value: value))
                            }
                        case .oxygenSaturation:
                            if let quantity = stats.averageQuantity() {
                                let value = quantity.doubleValue(for: .percent())
                                result.append(HealthStatistics(identifier: identifier, startDate: startDate, endDate: endDate, value: value))
                            }
                        default:
                            print("[enumerateStatistics] Unkown identifier: ", identifier)
                        }
                    }
                }

#if targetEnvironment(simulator)
                // demo data
                let demoSteps: [Double] = [90.0, 1000.0, 200.0, 70.0, 20.0, 1000.0, 120.0, 100.0, 200.0, 100, 500, 1600.0]
                let today = Calendar.current.startOfDay(for: Date())
                var hour = 7
                for steps in demoSteps {
                    let startDate = Calendar.current.date(byAdding: .hour, value: hour, to: today) ?? Date()
                    let endDate = Calendar.current.date(byAdding: .minute, value: 59, to: startDate) ?? Date()

                    switch identifier {
                    case .stepCount:
                        let steps = HealthStatistics(identifier: identifier, startDate: startDate, endDate: endDate, value: steps)
                        result.append(steps)
                    case .distanceWalkingRunning:
                        let km = HealthStatistics(identifier: identifier, startDate: startDate, endDate: endDate, value: Double.random(in: 0.1...2.0))
                        result.append(km)
                    case .walkingStepLength:
                        let length = HealthStatistics(identifier: identifier, startDate: startDate, endDate: endDate, value: Double.random(in: 0.1...2.0))
                        result.append(length)
                    default: break
                    }
                    hour += 1
                }
#endif
                
                if result.count == 0 && identifier == .stepCount {
                    let now = Date()
                    let stat = HealthStatistics(identifier: .stepCount, startDate: now, endDate: now, value: 0.0)
                    result.append(stat)
                }

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
                print("can't access data")
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
