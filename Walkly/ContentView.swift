//
//  ContentView.swift
//  Walkly
//
//  Created on 2022/10/20.
//  
//

import SwiftUI
import WidgetKit

struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject var viewModel = ViewModel()
    @StateObject var defaults = AppDefaults()

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                GaugeView(value: viewModel.stepCount.value, total: defaults.targetSteps)
                    .frame(width: 200, height: 200)
                    .background {
                        VStack {
                            Image(systemName: "figure.walk")
                                .font(.title2)
                            Text(viewModel.stepCount.value, format: .number.precision(.fractionLength(0)))
                                .font(.largeTitle)
                            Text((viewModel.stepCount.value / defaults.targetSteps), format: .percent.precision(.fractionLength(0)))
                                .font(.headline)
                                .foregroundColor(.gray)
                            Text(viewModel.stepCount.date, style: .time)
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }

                ActivityView(distanceWalkingRunning: viewModel.distanceWalkingRunning,
                             activeEnergyBurned: viewModel.activeEnergyBurned,
                             appleExerciseTime: viewModel.appleExerciseTime)
                
                HistoryView(viewModel: viewModel, data: viewModel.chartData, defaults: defaults)

                if let error = viewModel.healthKitError {
                    Text(error.localizedDescription)
                        .foregroundColor(.gray)
                }
//                Button("+") {
//                    viewModel.chartData.items[0].value += 100
//                }
            }
            .navigationBarTitle(Text("Steps"), displayMode: .inline)
            .navigationBarItems(trailing:
                                    NavigationLink(destination: AppDefaultsView(defaults: defaults)
                                        .navigationTitle("Settings")
                                    ) {
                Image(systemName: "gearshape.fill")
                    .foregroundColor(.gray)
            })
        }
        .onAppear {
            viewModel.autoUpdate()
        }
        .onChange(of: scenePhase) { phase in
            if phase == .active {
                // nofification to widget
                WidgetCenter.shared.reloadTimelines(ofKind: AppDefaults.simpleWidgetKind)
                WidgetCenter.shared.reloadTimelines(ofKind: AppDefaults.chartWidgetKind)
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environment(\.locale, .init(identifier: "ja"))
            //.environment(\.locale, .init(identifier: "en"))
    }
}

struct ActivityView: View {
    @ObservedObject var distanceWalkingRunning: Statistics
    @ObservedObject var activeEnergyBurned: Statistics
    @ObservedObject var appleExerciseTime: Statistics

    private let distance = NSLocalizedString("Distance", comment: "Distance")
    private let EnergyBurned = NSLocalizedString("EnergyBurned", comment: "EnergyBurned")
    private let Exercise = NSLocalizedString("Exercise", comment: "Exercise")
    private let hours = NSLocalizedString("hours", comment: "hours")

    var body: some View {
        HStack {
            Spacer()
            
            if let value = distanceWalkingRunning.value, let date = distanceWalkingRunning.date  {
                ActivityItmeView(label: distance, value: value.toDecimalString(0, 2), unit: "km", date: date)
            } else {
                ActivityItmeView(label: distance, value: "0.0", unit: "km", date: Date())
            }

            if let value = activeEnergyBurned.value, let date = activeEnergyBurned.date  {
                ActivityItmeView(label: EnergyBurned, value: value.toDecimalString(0, 1), unit: "kcal", date: date)
            } else {
                ActivityItmeView(label: EnergyBurned, value: "0.0", unit: "kcal", date: Date())
            }

            if let value = appleExerciseTime.value, let date = appleExerciseTime.date  {
                ActivityItmeView(label: Exercise, value: String(format: "%02d:%02d",Int(value / 60), Int(value.truncatingRemainder(dividingBy: 60))),
                                 unit: hours, date: date)
            } else {
                ActivityItmeView(label: Exercise, value: "00:00", unit: "hours", date: Date())
            }

            Spacer()
        }
    }

    private struct ActivityItmeView: View {
        var label: String
        var value: String
        var unit: String
        var date: Date
        
        var body: some View {
            VStack {
                Text(label)
                    .font(.caption2)
                    .foregroundColor(.gray)
                Text(value)
                    .font(.title3)
                Text(unit)
                    .font(.caption)
                    .foregroundColor(.gray)
                Text(date, style: .time)
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .padding()
        }
    }
}

struct HistoryView: View {
    @ObservedObject var viewModel: ViewModel
    @ObservedObject var data: ChartData
    @ObservedObject var defaults: AppDefaults
    @State var days = 1

    var body: some View {
        VStack {
            Picker("", selection: $days) {
                Text("day")
                    .tag(1)
                Text("week")
                    .tag(7)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(EdgeInsets(top: 8, leading: 16, bottom: 0, trailing: 16))
            
            if data.items.count == 0 {
                VStack {
                    ProgressView("", value: 1)
                        .progressViewStyle(CircularProgressViewStyle())
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            } else {
                if viewModel.fetchDays == 1 {
                    LineChartView(data: data, stacked: true, target: defaults.targetSteps)
                        .padding()

                } else {
                    BarChartView(data: data, target: defaults.targetSteps)
                        .padding()
                }
            }
        }
        .onChange(of: days) { newValue in
            viewModel.fetchPeriod(days: newValue)
        }
        .background(Color.gray.opacity(0.1).cornerRadius(16))
        .padding()
    }
}
