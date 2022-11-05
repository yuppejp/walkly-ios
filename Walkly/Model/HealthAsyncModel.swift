//
//  HealthAyncModel.swift
//  Walkly
//
//  Created by yukio on 2022/11/03.
//

import Foundation
import HealthKit

class HealthAsyncModel {
    let healthStore = HKHealthStore()

    func enableUpdateHandler(identifiers: [HKQuantityTypeIdentifier], updateHandler: @escaping (HKObserverQuery, @escaping HKObserverQueryCompletionHandler, Error?) -> Void) async throws {
        // REF: https://qiita.com/dotrikun/items/73db477f8fb23f9d783b
        
        _ = try await requestAuthorization(identifiers: identifiers)
        
        for identifier in identifiers {
            let objectType = HKSampleType.quantityType(forIdentifier: identifier)!
            let query = HKObserverQuery(sampleType: objectType, predicate: nil, updateHandler: { query, completionHandler, error in
                // update detection
                updateHandler(query, completionHandler, error)
            })
            healthStore.execute(query)
            
            // Enable Background Health Data Update Detection
            try await healthStore.enableBackgroundDelivery(for: objectType, frequency: .immediate)
        }
    }

    private func requestAuthorization(identifiers: [HKQuantityTypeIdentifier]) async throws -> HKAuthorizationRequestStatus {
        var status: HKAuthorizationRequestStatus = .unknown
        
        status = try await getRequestStatusForAuthorization(identifiers: identifiers)
        switch status {
        case .shouldRequest:
            print("requestAuthorization: shouldRequest")
            
            // ask user for permission
            var readTypes: Set<HKQuantityType> = []
            for identifier in identifiers {
                readTypes.insert(HKQuantityType.quantityType(forIdentifier: identifier)!)
            }
            _ = try await requestAuthorization(read: readTypes)
            
            // check status again
            status = try await getRequestStatusForAuthorization(identifiers: identifiers)
            
        case .unnecessary:
            print("requestAuthorization: unnecessary")
            
        case .unknown:
            print("requestAuthorization: unknown")
            
        default:
            print("requestAuthorization: \(status)")
        }
            
        return status
    }
    
    private func getRequestStatusForAuthorization(identifiers: [HKQuantityTypeIdentifier]) async throws -> HKAuthorizationRequestStatus {
        var readTypes: Set<HKQuantityType> = []
        
        for identifier in identifiers {
            readTypes.insert(HKQuantityType.quantityType(forIdentifier: identifier)!)
        }

        return try await withCheckedThrowingContinuation { continuation in
            healthStore.getRequestStatusForAuthorization(toShare: [], read: readTypes) { status, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: status)
                }
            }
        }
    }

    private func requestAuthorization(read: Set<HKObjectType>) async throws -> Bool {
        return try await withCheckedThrowingContinuation { continuation in
            healthStore.requestAuthorization(toShare: [], read: read, completion: { success, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: success)
                }
            })
        }
    }

    func fetchTody(identifiers: [HKQuantityTypeIdentifier]) async throws -> [HealthStatistics] {
        let status = try await requestAuthorization(identifiers: identifiers)
        print("status: \(status)")
        
        var results: [HealthStatistics] = []
        for identifier in identifiers {
            do {
                let result = try await fetchOneToday(healthStore: healthStore, identifier: identifier)
                results.append(result)
            } catch {
                // errorNoData is not an error because it is within expectations
                let nsError = error as NSError
                if nsError.code != HKError.Code.errorNoData.rawValue {
                    throw error
                }
            }
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
#endif
        return results
    }

    private func fetchOneToday(healthStore: HKHealthStore, identifier: HKQuantityTypeIdentifier) async throws -> HealthStatistics {
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
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(quantityType: type,
                                          quantitySamplePredicate: predicate,
                                          options: options) { (query, statistics, error) in
                if let error = error {
                    print("[getTody@HKStatisticsQuery] error: ", error.localizedDescription)
                    continuation.resume(throwing: error)
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
                    
                    continuation.resume(returning: result)
                }
            }
            healthStore.execute(query)
        }
    }
    
    func fetchPeriod(identifier: HKQuantityTypeIdentifier, from: Date, to: Date, anchor: Date,
                     interval: DateComponents) async throws -> [HealthStatistics] {
        
        // https://zenn.dev/ueshun/scraps/90fbb43a2bb3d7
        let healthStore = HKHealthStore()
        
        let status = try await requestAuthorization(identifiers: [identifier])
        if status != .unnecessary {
            print("requestAuthorization: ", status)
            throw NSError(domain: "Error: requestAuthorization", code: status.rawValue)
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

        return try await withCheckedThrowingContinuation { continuation in
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
                if result.count == 0 && identifier == .stepCount {
                    let now = Date()
                    let stat = HealthStatistics(identifier: .stepCount, startDate: now, endDate: now, value: 0.0)
                    result.append(stat)
                }

                continuation.resume(returning: result)
            }
            healthStore.execute(query)
        }
    }
}

