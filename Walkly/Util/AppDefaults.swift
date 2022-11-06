//
//  AppDefaults.swift
//  Walkly
//
//  Created on 2022/10/10.
//  
//

import SwiftUI
import CoreData
import WidgetKit

struct AppDefaultsView: View {
    @StateObject var defaults: AppDefaults
    @Environment(\.openURL) var openURL
    
    var body: some View {
        Form {
            Section(header: Text("TargetStepsPerDay")) {
                Stepper(value: $defaults.targetSteps, in: 100...60_000, step: 100) {
                    HStack {
                        Text(defaults.targetSteps, format: .number.precision(.fractionLength(0)))
                        Text("StepsUnit")
                    }
                }
            }
            Section(header: Text("AccessoryCircularWidget")) {
                Toggle(isOn: $defaults.showOffsetTime) {
                    VStack(alignment: .leading) {
                        Text("ShowUpdateTime")
                        Text("ShowUpdateTimeDescription")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }
            Section(header: Text("DataSource")) {
                if HealthModel().isAvailable() {
                    Button(action: {
                        openURL(URL(string: "x-apple-health://")!)
                    }) {
                        Label("OpenHealthCare", systemImage: "staroflife.fill")
                    }
                } else {
                    Text("HealthIsUnavailable")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
        }
        .onChange(of: defaults.showOffsetTime) { newValue in 
            // Update notification to widget
            WidgetCenter.shared.reloadTimelines(ofKind: AppDefaults.simpleWidgetKind)
            WidgetCenter.shared.reloadTimelines(ofKind: AppDefaults.chartWidgetKind)
        }
    }
}

struct AppDefaultsView_Previews: PreviewProvider {
    static var previews: some View {
        AppDefaultsView(defaults: AppDefaults())
    }
}

// Widgetkit cannot use @AppStrage, so use UserDefaults
class AppDefaults: ObservableObject {
    static let appGroupName = "group.jp.yuppe.walkly"
    static let simpleWidgetKind = "jp.yuppe.Walkly.WalklyWedget"
    static let chartWidgetKind = "jp.yuppe.Walkly.chartWedget"
    private let userDefaults = UserDefaults(suiteName: appGroupName)

    @Published var targetSteps: Double {
        didSet {
            userDefaults!.set(targetSteps, forKey: "targetSteps")
        }
    }

    @Published var showOffsetTime: Bool {
        didSet {
            userDefaults!.set(showOffsetTime, forKey: "showOffsetTime")
        }
    }

    @Published var refreshInterval: Int {
        didSet {
            userDefaults!.set(refreshInterval, forKey: "refreshInterval")
        }
    }
    
    // for sharing widgets
    @Published var lastError: String {
        didSet {
            userDefaults!.set(lastError, forKey: "lastError")
        }
    }
    @Published var lastStepCount: Double {
        didSet {
            userDefaults!.set(lastStepCount, forKey: "lastStepCount")
        }
    }
    @Published var lastStepCountDate: Date {
        didSet {
            userDefaults!.set(lastStepCountDate, forKey: "lastStepCountDate")
        }
    }
    @Published var lastDistanceWalkingRunning: Double {
        didSet {
            userDefaults!.set(lastDistanceWalkingRunning, forKey: "lastDistanceWalkingRunning")
        }
    }
    @Published var lastDistanceWalkingRunningDate: Date {
        didSet {
            userDefaults!.set(lastDistanceWalkingRunningDate, forKey: "lastDistanceWalkingRunningDate")
        }
    }
    
    init() {
        userDefaults!.register(defaults: ["targetSteps": 8000,
                                          "showOffsetTime": false,
                                          "refreshInterval": 15])
        
        targetSteps = userDefaults!.double(forKey: "targetSteps")
        showOffsetTime = userDefaults!.bool(forKey: "showOffsetTime")
        refreshInterval = userDefaults!.integer(forKey: "refreshInterval")

        lastError = userDefaults!.string(forKey: "lastError") ?? ""
        lastStepCount = userDefaults!.double(forKey: "lastStepCount")
        lastStepCountDate = userDefaults!.object(forKey: "lastStepCountDate") as? Date ?? Date()
        lastDistanceWalkingRunning = userDefaults!.double(forKey: "lastDistanceWalkingRunning")
        lastDistanceWalkingRunningDate = userDefaults!.object(forKey: "lastDistanceWalkingRunningDate")  as? Date ?? Date()
        
//        print("=== AppDefaults ===================================================")
//        print("  lastError                      :", lastError)
//        print("  lastStepCount                  :", lastStepCount)
//        print("  lastStepCountDate              :", lastStepCountDate.toString())
//        print("  lastDistanceWalkingRunning     :", lastDistanceWalkingRunning)
//        print("  lastDistanceWalkingRunningDate :", lastDistanceWalkingRunningDate.toString())
    }
}

