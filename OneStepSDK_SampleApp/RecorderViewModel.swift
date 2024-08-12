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
    let recorder: OSTRecorderProtocol
    private var recorderSubscriber: Cancellable? = nil
    private var analyzerSubscriber: Cancellable? = nil
    @Published var uiState = "Initial"
    
    // Recording Phase
    @Published var recordingInProgress: Bool = false
    @Published var time: Int = 0
    var timerSubscriber: Cancellable? = nil
    let timer = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()

    // Analyzing Phase
    @Published var analyzingInProgress: Bool = false
    
    // Measurement Result
    @Published var recorderResultText: String = ""
    
    init(recorder: OSTRecorderProtocol){
        self.recorder = recorder
        
        self.recorderSubscriber = self.recorder.recorderState.receive(on: RunLoop.main).sink(receiveValue: { recorderState in
            switch recorderState {
            case .idle:
                print("OneStep Recorder is ready for use")
                self.recordingInProgress = false
                self.uiState = "Idle"
            case .recording(let uuid):
                print("OneStep Recorder in progress - recording_Id=\(uuid)")
                self.recordingInProgress = true
                self.uiState = "Recording"
            case .finishedRecording:
                print("OneStep Recorder Finished")
                self.recordingInProgress = false
                self.uiState = "Finished Recording"
                
                // new motion measurement saved. Trigger the analysis flow for immediate feedback.
                self.analyze()
                
                // reset the recorder internal state before your next recording
                self.recorder.reset()
            default:
                break
            }
        })
        
        self.analyzerSubscriber = self.recorder.analyzerState.receive(on: RunLoop.main).sink(receiveValue: { analyzerState in
            switch analyzerState {
            case .idle:
                break
            case .analyzing(let analyzingState):
                print("Analysis in progress: \(analyzingState)")
                self.analyzingInProgress = true
                self.uiState = "Analyzing"
            case .analyzedAndSavedSuccessfully:
                print("Analysis completed and saved successfully.")
                self.analyzingInProgress = false
                self.uiState = "Result Available"
            case .error(let errorType):
                print("Error occurred during analysis: \(errorType)")
                self.analyzingInProgress = false
                self.uiState = "Error"
            default:
                break
            }
        })
    }
    
    /// Start recording a new session: timed walk (60 seconds - parameter set inside).
    ///
    /// Developer responsibility: handling recorder state machine (i.e not calling `start` when already recording)
    /// Developer responsibility: Making sure that motion and location permissions are granted and usage descriptions are in place in info.plist
    ///
    /// NOTE: Currently recording will start only when you give motion and fitness persmission and location always persmission when it's asked on Start recording.
    ///
    func startRecording() {
        let userInputMetadata = UserInputMetaData(
            note: "this is a free-text note",
            tags: ["tag1", "tag2", "tag3"],
            assistiveDevice: .cane,
            levelOfAssistance: .independent
        )
        let customMetadata: Dictionary<String, MixedType> = [
            "app": .string("DemoApp"),
            "is_demo": .bool(true),
            "version": .double(1.1),
        ]
        self.recorder.start(
            activityType: .Walk,
            // Duration represents the length of the recording session in milliseconds.
            // The user can manually stop the recording at any time.
            // If the duration is not specified, the recording will have a technical limit of 6 minutes.
            duration: 60,
            // Optional user tagging of the activity, including a free-text note, tags,
            // and domain-specific enums such as assistive device and level of assistance.
            userInputMetadata: userInputMetadata,
            // Technical key-value properties that will be propagate to the measurement result.
            // Supporting primitive types: Bool, Int, String, Double.
            customMetadata: customMetadata
        )
                
        // Start UI timer
        self.timerSubscriber = timer.map({ (date) -> Void in
            self.time += 1
        })
        .sink { _ in
            if !self.recordingInProgress {
                self.timer.upstream.connect().cancel()
            }
        }
        
        // Clean old UI state
        DispatchQueue.main.async{
            self.recorderResultText = ""
            self.time = 0
        }
    }
    
    func stopRecording() {
        recorder.stop()
        self.timerSubscriber?.cancel()
    }
    
    /*
      The data analysis process is a multi-step transaction:
      1. Upload raw motion data to the OneStep servers.
      2. The data analysis pipeline processes the data asynchronously.
      3. The SDK retrieves the analysis results when they become available.
     
      For a short walk, the process typically takes 5-15 seconds.
      In rare cases, it may take much longer due to:
        - Poor internet connectivity
        - High server load
        - Lengthy recordings
     */
    func analyze() {
        Task {
            let result = await self.recorder.analyze()
            if let result {
                // Build Your sumary screen here
                DispatchQueue.main.async{
                    switch result.result_state {
                    case 0:
                        print("Empty Analysis: \(result.error.debugDescription)")
                        self.recorderResultText = "Empty Analysis:\n error=\(result.error.debugDescription)"
                    case 1:
                        print("Parital analysis result is available")
                        let steps = result.metadata?.steps ?? 0
                        let cadence = result.parameters?[ParamName.walkingCadence.rawValue]
                        self.recorderResultText = "Partial Analysis:\n steps=\(steps)\n cadence=\(cadence != nil ? String(cadence!) : "N/A")\n"
                    case 2:
                        print("Full analysis result is available")
                        let steps = result.metadata?.steps ?? 0
                        let walkScore = result.parameters?[ParamName.walkingWalkScore.rawValue]
                        self.recorderResultText = "Full Analysis:\n steps=\(steps)\n walk score=\(walkScore != nil ? String(walkScore!) : "N/A")\n"
                    default:
                        print("Analysis result is not available")
                    }
                }
            } else {
                print("Analysis result is not available due to technical reason")
            }
        }
    }
    
}


