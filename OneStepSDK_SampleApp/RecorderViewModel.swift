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
    let analyzer: OneStepSimpleAnalyzerProtocol
    @Published var recordingInProgress: Bool = false
    @Published var failedToAnalyze = false
    @Published var walkScore: Int? = nil
    @Published var stepsCount: Int? = nil
    @Published var time: Int = 0
    @Published var uiState = "Initial"
    @Published var currentRecordingUUID: UUID? = nil
    @Published var recorderSubscriber: Cancellable? = nil
    @Published var analyzerSubscriber: Cancellable? = nil
    @Published var timerSubscriber: Cancellable? = nil
    @Published var isLoadingResult: Bool = false
    let timer = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()
    @Published var recorderResultText: String = ""
    
    init(recorder: OneStepSimpleRecorderProtocol, analyzer: OneStepSimpleAnalyzerProtocol){
        self.recorder = recorder
        self.analyzer = analyzer
    }
    
    /// Start recording a new session: timed walk (60 seconds - parameter set inside).
    ///
    /// Developer responsibility: handling recorder state machine (i.e not calling `start` when already recording)
    /// Developer responsibility: Making sure that motion and location permissions are granted and usage descriptions are in place in info.plist
    ///
    /// NOTE: Currently recording will start only when you give motion and fitness persmission and location always persmission when it's asked on Start recording.
    ///
    func startRecording() {
        DispatchQueue.main.async{
            self.recorderResultText = ""
            self.failedToAnalyze = false
            self.walkScore = nil
            self.stepsCount = nil
            self.time = 0
            self.recordingInProgress = true
        }
        
        self.analyzerSubscriber = self.analyzer.analyzerState.receive(on: RunLoop.main).sink(receiveValue: { analyzerState in
            self.uiState = "\(analyzerState.title)"
            switch analyzerState {
            case .idle:
                break
            case .analyzing(let analyzingState):
                //analyzingState indicated 3 stages of recording inProgress, generatingReport, preparingResult
                break
            case .analyzedAndSavedSuccessfully:
                if let uuid = self.currentRecordingUUID {
                    if let result = self.analyzer.readMotionMeasurementById(uuid: uuid) {
                        switch result.result_state {
                        case 0:
                            print("Analysis error: \(String(describing: result.error))")
                            break
                        case 1:
                            print("Parital analysis result is available")
                            break
                        case 2: // todo: migrate to enum
                            print("Full analysis result is avilable")
                            let steps = result.metadata?.steps ?? 0
                            let walkScore = result.parameters?["walk_score"]  // todo: migrate to ParamName enum
                            print("measurementId=\(result.id) - steps=\(steps) - walkScore=\(String(describing: walkScore))")
                            break
                        default:
                            print("Analysis result is not available")
                            break
                        }
                        
                        //update UI
                        if let walkScore = result.parameters?["walk_score"], let steps = result.metadata?.steps {
                            self.walkScore = Int(walkScore)
                            self.stepsCount = steps
                            self.recorderResultText = "Success! \n Walk score: \(self.walkScore!) \n Steps count: \(self.stepsCount!)"
                        } else {
                            self.walkScore = nil
                            self.stepsCount = nil
                            self.failedToAnalyze = true
                            self.recorderResultText = "Did not get either walk score or steps count. \n Perform a real walk of at least 30 seconds, please."
                        }
                    }
                    self.isLoadingResult = false
                    self.uiState = "Initial"
                }
            case .error(let errorType):
                //Do something based on error type
                break
            default:
                break
            }
        })
        
        self.recorderSubscriber = self.recorder.recorderState.receive(on: RunLoop.main).sink(receiveValue: { recorderState in
            self.uiState = "\(recorderState.title)"
            switch recorderState {
            case .idle:
                break
            case .recording(let recordingUUID):
                self.currentRecordingUUID = recordingUUID
            case .finishedRecording:
                if let uuid = self.currentRecordingUUID {
                    self.analyzer.analyze(uuid: uuid)
                }
                self.recordingInProgress = false
                self.recorder.reset()
            case .error(let errorType):
                //Do something based on error type
                break
            default:
                break
            }
        })
        
        // Optional user tagging of the activity including free-text note, tags,
        // and domain specific enums like assistive device and level of assistance.
        let userInputMetadata = MeasurementMetadataOut(locale: "IL",
                                                       seconds: 60,
                                                       steps: 55,
                                                       geoLat: nil,
                                                       geoLng: nil,
                                                       tags: ["tag1", "tag2", "tag3"],
                                                       note: "this is a free-text note",
                                                       levelOfAssistance: .independent,
                                                       assistiveDevice: .cane)
        
        // Technical key-value properties that will be propagate to the measurement result.
        // Supporting types like Bool, Int, String, Double, AnyCodable
        let customMetadata: Dictionary<String, MixedType> = ["app": .string("DemoApp") , "is_demo": .bool(true), "version": .double(1.1)]
        
        self.recorder.start(activityType: .Walk, duration: 60, userInputMetadata: userInputMetadata, customMetadata: customMetadata)
        
        startRecordingTimer()
    }
    
    //Manually stop recording before duration time is out.
    func stopInAppRecording() {
        recordingInProgress = false
        isLoadingResult = true
        recorderResultText = "Loading result..."
        
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


