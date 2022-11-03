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
                CircularCapacityView(value: viewModel.stepCount.value,
                                     total: defaults.targetSteps)
                    .frame(width: 200, height: 200)
                    .background {
                        VStack {
                            Text((viewModel.stepCount.value / defaults.targetSteps), format: .percent.precision(.fractionLength(0)))
                                .font(.headline)
                                .foregroundColor(.gray)
                            Text(viewModel.stepCount.value, format: .number.precision(.fractionLength(0)))
                                .font(.largeTitle)
                            Text("目標: ")
                                .font(.caption)
                                .foregroundColor(.gray)
                            + Text(defaults.targetSteps, format: .number.precision(.fractionLength(0)))
                                .font(.caption)
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
            .navigationBarTitle(Text("歩数"), displayMode: .inline)
            .navigationBarItems(trailing:
                                    NavigationLink(destination: AppDefaultsView(defaults: defaults)
                                        .navigationTitle("設定")
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
    }
}

struct StepCountView: View {
    @ObservedObject var stepCount: Statistics
    let total: Int
    
    var body: some View {
        if (stepCount.value > 0) {
            RingProgressView(title: "歩数", label: "目標", total: Double(total), value: stepCount.value, date: stepCount.date)
        } else {
            RingProgressView(title: "歩数", label: "目標", total: Double(total), value: 0, date: Date())
        }
    }
}

struct ActivityView: View {
    @ObservedObject var distanceWalkingRunning: Statistics
    @ObservedObject var activeEnergyBurned: Statistics
    @ObservedObject var appleExerciseTime: Statistics

    var body: some View {
        HStack {
            Spacer()
            
            if let value = distanceWalkingRunning.value, let date = distanceWalkingRunning.date  {
                ActivityItmeView(label: "移動距離", value: value.toDecimalString(0, 2), unit: "km", date: date)
            } else {
                ActivityItmeView(label: "移動距離", value: "0.0", unit: "km", date: Date())
            }

            if let value = activeEnergyBurned.value, let date = activeEnergyBurned.date  {
                ActivityItmeView(label: "消費カロリー", value: value.toDecimalString(0, 1), unit: "kcal", date: date)
            } else {
                ActivityItmeView(label: "消費カロリー", value: "0.0", unit: "kcal", date: Date())
            }

            if let value = appleExerciseTime.value, let date = appleExerciseTime.date  {
                ActivityItmeView(label: "エクササイズ", value: String(format: "%02d:%02d",Int(value / 60), Int(value.truncatingRemainder(dividingBy: 60))),
                                 unit: "時間", date: date)
            } else {
                ActivityItmeView(label: "エクササイズ", value: "00:00", unit: "時間", date: Date())
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
                Text("日")
                    .tag(1)
                Text("週")
                    .tag(7)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(EdgeInsets(top: 8, leading: 16, bottom: 0, trailing: 16))
            
            if data.items.count == 0 {
                VStack {
                    ProgressView("wait…", value: 1)
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
