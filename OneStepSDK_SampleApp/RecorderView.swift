//
//  ContentView.swift
//  OneStepSDK_SampleApp
//
//  Created by David Havkin on 01/08/2024.
//

import SwiftUI
import Combine


struct RecorderView: View {
    @ObservedObject var viewModel: RecorderViewModel
    
    var body: some View {
        VStack {
            Text("OneStep Walk recorder")
                .font(.title)
                .padding(.top, 20)
                .padding(.bottom, 70)
            CustomButton(
                title: viewModel.recordingInProgress ? "Stop and analyze" : "Start recording",
                action: {
                    if viewModel.recordingInProgress {
                        viewModel.stopInAppRecordingAndUpload()
                    } else {
                        guard !PermissionsUtils.isPreciseLocationAuthorized() else {
                            PermissionsUtils.requestLocationAuthorization()
                            return
                        }
                        guard !PermissionsUtils.isLocationAlwaysAuthorized() else {
                            PermissionsUtils.requestLocationAlways()
                            return
                        }
                        viewModel.startRecording()
                    }
                },
                isActivated: viewModel.recordingInProgress, height: 100)
            .padding(.bottom, 30)
            
            Text("Timer: \(viewModel.time)")
                .padding(.bottom, 10)
                .font(.largeTitle)
            
            Text("Recorder state: \(viewModel.recorderState)")
                .padding(.bottom, 10)
                .font(.title3)
            
            if let ws = viewModel.walkScore, let st = viewModel.stepsCount {
                VStack{
                    Text("Your walk score: \(ws)")
                    Text("Your steps count: \(st)")
                }
                .font(.title)
            } else if viewModel.isLoadingResult {
                Text("Here will appear result. Please wait...")
                    .font(.title2)
                    .padding(10)
                ActivityIndicator(isAnimating: viewModel.isLoadingResult)
                    .background(Color.black)
                    .frame(width: 50, height: 50)
            } else if viewModel.failedToAnalyze {
                Text("Did not get either walk score or steps count. \n Perform a real walk of at least 30 seconds, please.")
                    .font(.title2)
            }
            Spacer()
        }
        .padding()
    }
}

struct ActivityIndicator: UIViewRepresentable {
    typealias UIView = UIActivityIndicatorView
    var isAnimating: Bool
    fileprivate var configuration = { (indicator: UIView) in }
    
    func makeUIView(context: UIViewRepresentableContext<Self>) -> UIView { UIView() }
    func updateUIView(_ uiView: UIView, context: UIViewRepresentableContext<Self>) {
        isAnimating ? uiView.startAnimating() : uiView.stopAnimating()
        configuration(uiView)
    }
}

