//
//  MainViewViewModel.swift
//  OneStepSDK_SampleApp
//
//  Created by David Havkin on 05/08/2024.
//

import Foundation
import OneStepSDK
import Combine

class RecorderViewModel: ObservableObject {
    let recorder: OneStepSimpleRecorderProtocol
    @Published var recordingInProgress: Bool = false
    @Published var failedToAnalyze = false
    @Published var walkScore: Int? = nil
    @Published var stepsCount: Int? = nil
    @Published var time: Int = 0
    @Published var recorderState = "Initial"
    @Published var currentRecordingUUID: UUID? = nil
    @Published var recorderSubscriber: Cancellable? = nil
    @Published var timerSubscriber: Cancellable? = nil
    @Published var isLoadingResult: Bool = false
    let timer = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()
    
    init(recorder: OneStepSimpleRecorderProtocol){
        self.recorder = recorder
    }
    
    /// Start recording a new session: timed walk (60 seconds - parameter set inside).
    ///
    /// Developer responsibility: handling recorder state machine (i.e not calling `start` when already recording)
    /// Developer responsibility: Making sure that motion and location permissions are granted and usage descriptions are in place in info.plist
    ///
    /// NOTE: Currently recording will start only when you give motion and fitness persmission and location always persmission when it's asked on Start recording.
    ///
    func startRecording() {
        recorderSubscriber?.cancel()
        failedToAnalyze = false
        walkScore = nil
        stepsCount = nil
        time = 0
        recordingInProgress = true
        self.recorder.start(activityType: .Walk, duration: 60, userInputMetadata: nil, customMetadata: nil)
        startRecordingTimer()
        
        self.recorderSubscriber = self.recorder.recorderState.receive(on: RunLoop.main).sink(receiveValue: { recorderState in
            self.recorderState = "\(recorderState)"
            switch recorderState {
            case .idle:
                break
            case .recording(let recordingUUID):
                self.currentRecordingUUID = recordingUUID
            case .finishedRecording:
                if let uuid = self.currentRecordingUUID {
                    self.recorder.analyze(uuid: uuid)
                }
                self.recordingInProgress = false
                self.recorder.reset()
            case .analyzing(let analyzingState):
                //analyzingState indicated 3 stages of recording inProgress, generatingReport, preparingResult
                break
            case .analyzedAndSavedSuccessfully:
                if let uuid = self.currentRecordingUUID {
                    if let result = self.recorder.getSummaryForMeasurement(uuid: uuid) {
                        switch result.result_state {
                        case 0:
                            print("Analysis error: \(result.error)")
                            break
                        case 1:
                            print("Parital analysis result is available")
                            break
                        case 2: // todo: migrate to enum
                            print("Full analysis result is avilable")
                            let steps = result.metadata?.steps ?? 0
                            let walkScore = result.parameters?["walk_score"]  // todo: migrate to ParamName enum
                            print("measurementId=\(result.id) - steps=\(steps) - walkScore=\(walkScore)")
                            break
                        default:
                            print("Analysis result is not available")
                            break
                        }
                        
                        //update UI
                        if let walkScore = result.parameters?["walk_score"], let steps = result.metadata?.steps {
                            self.walkScore = Int(walkScore)
                            self.stepsCount = steps
                        } else {
                            self.failedToAnalyze = true
                        }
                    }
                    self.isLoadingResult = false
                    self.recorderSubscriber?.cancel()
                    self.recorderState = "Initial"
                }
            case .error(let errorType):
                //Do something based on error type
                break
            default:
                break
            }
        })
    }
    
    //Manually stop recording before duration time is out.
    func stopInAppRecordingAndUpload() {
        recordingInProgress = false
        isLoadingResult = true
        
        recorder.stop()
        self.timerSubscriber?.cancel()
    }
    
    private func startRecordingTimer() {
        self.timerSubscriber = timer.map({ (date) -> Void in
            self.time += 1
        })
        .sink { _ in
            if !self.recordingInProgress {
                self.timer.upstream.connect().cancel()
            }
        }
    }
}


