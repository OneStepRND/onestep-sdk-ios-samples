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
            
            Button(action: {
                //Currently recording will start only when you give motion and fitness persmission and location always persmission
                if PermissionsUtils.allPermissionsInPlace() {
                    viewModel.startRecording()
                }
            }, label: {
                Text("Start recording")
                    .font(.title)
            })
            .disabled(viewModel.recordingInProgress || viewModel.isLoadingResult)
            .padding(.bottom, 30)
            
            
            Button(action: {
                viewModel.stopInAppRecording()
            }, label: {
                Text("Stop recording")
                    .font(.title)
            })
            .disabled(!viewModel.recordingInProgress)
            .padding(.bottom, 30)
            
            
            Text("Timer: \(viewModel.time)")
                .padding(.bottom, 10)
                .font(.largeTitle)
            
            Text("Recorder state: \(viewModel.uiState)")
                .padding(.bottom, 10)
                .font(.title3)
            
            Text("\(viewModel.recorderResultText)")
                .font(.title2)
                .padding(.bottom, 30)
            
            if viewModel.isLoadingResult {
                ActivityIndicator(isAnimating: viewModel.isLoadingResult)
                    .background(Color.black)
                    .frame(width: 50, height: 50)
            }

            Spacer()
        }
        .padding()
    }
}

