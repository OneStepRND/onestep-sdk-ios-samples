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
            Text("OneStep Sample: Motion Recorder")
                .font(.title)
                .padding(.top, 20)
                .padding(.bottom, 70)
            
            Button(action: {
                viewModel.startRecording()
            }, label: {
                Text("Start recording")
                    .font(.title)
            })
            .disabled(viewModel.recordingInProgress || viewModel.analyzingInProgress)
            .padding(.bottom, 30)
            
            
            Button(action: {
                viewModel.stopRecording()
            }, label: {
                Text("Stop recording")
                    .font(.title)
            })
            .disabled(!viewModel.recordingInProgress)
            .padding(.bottom, 30)
            
            
            Text("Timer: \(viewModel.elapsedTime)")
                .padding(.bottom, 10)
                .font(.largeTitle)
            
            Text("State: \(viewModel.uiState)")
                .padding(.bottom, 10)
                .font(.title3)
            
            Text("\(viewModel.recorderResultText)")
                .font(.title2)
                .padding(.bottom, 30)
            
            if viewModel.analyzingInProgress {
                ActivityIndicator(isAnimating: viewModel.analyzingInProgress)
                    .background(Color.black)
                    .frame(width: 50, height: 50)
            }

            Spacer()
        }
        .padding()
    }
}

