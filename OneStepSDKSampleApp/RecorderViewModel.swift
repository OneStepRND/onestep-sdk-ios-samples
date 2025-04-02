//
//  MainViewViewModel.swift
//  OneStepSDKSampleApp
//
//  Created by David Havkin on 05/08/2024.
//

import Foundation
import OneStepSDK
import Combine

class RecorderViewModel: ObservableObject {
    let recorder: OSTRecorderProtocol
    @Published var uiState = "Initial"

    // Recording Phase
    @Published var recordingInProgress: Bool = false
    @Published var elapsedTime: Int = 0
    private var recorderSubscriber: Cancellable?
    private var timerSubscriber: Cancellable?
    private let timer = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()

    // Analyzing Phase
    @Published var analyzingInProgress: Bool = false
    private var analyzerSubscriber: Cancellable?

    // Measurement Result
    @Published var recorderResultText: String = ""

    init(recorder: OSTRecorderProtocol) {
        self.recorder = recorder
        setupRecorderSubscriber()
        setupAnalyzerSubscriber()
    }

    private func setupRecorderSubscriber() {
        self.recorderSubscriber = self.recorder.recorderState.receive(on: RunLoop.main).sink(receiveValue: { recorderState in
            switch recorderState {
            case .idle:
                print("OneStep Recorder is ready for use")
                self.recordingInProgress = false
                self.uiState = "Idle"
            case .recording(let uuid):
                print("OneStep Recorder in progress - measurement id=\(uuid)")
                self.recordingInProgress = true
                self.uiState = "Recording"
            case .finishedRecording:
                print("OneStep Recorder Finished")
                self.recordingInProgress = false
                self.uiState = "Finished Recording"

                // Trigger analysis flow for immediate feedback after saving a new motion measurement.
                self.analyze()

                // reset the recorder internal state before your next recording
                self.recorder.reset()
            default:
                break
            }
        })
    }

    private func setupAnalyzerSubscriber() {
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

    /// Start recording a new session: timed walk (60 seconds).
    ///
    /// Developer responsibilities:
    /// - Handle the recorder state machine (e.g., don't call `start` when already recording).
    /// - Ensure motion and location permissions are granted and usage descriptions are in the info.plist.
    ///
    /// NOTE: Recording will only start after motion and fitness permission and location permission are granted.
    ///
    func startRecording() {
        let userInputMetadata = OSTUserInputMetaData(
            note: "this is a free-text note",
            tags: ["tag1", "tag2", "tag3"],
            assistiveDevice: .cane,
            levelOfAssistance: .independent
        )

        let customMetadata: [String: OSTMixedType] = [
            "app": .string("DemoApp"),
            "is_demo": .bool(true),
            "version": .double(1.1)
        ]

        self.recorder.start(
            activityType: .walk,
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

        startUITimer()
        resetUIState()
    }

    private func startUITimer() {
        self.timerSubscriber = timer.map { _ in
            self.elapsedTime += 1
        }
        .sink { _ in
            if !self.recordingInProgress {
                self.timer.upstream.connect().cancel()
            }
        }
    }

    private func resetUIState() {
        DispatchQueue.main.async {
            self.recorderResultText = ""
            self.elapsedTime = 0
        }
    }

    /// The recorder will automatically stop after the defined duration.
    /// The user can also stop it manually at any time.
    func stopRecording() {
        recorder.stop()
        self.timerSubscriber?.cancel()
    }

    ///   The data analysis process involves several steps:
    ///     1. Upload raw motion data to the OneStep servers.
    ///     2. Process the data asynchronously via the analysis pipeline.
    ///     3. Retrieve the analysis results through the SDK as soon as they are available.
    ///
    ///     For a short walk, this process typically takes 5-15 seconds.
    ///     However, in rare cases, it may take longer due to factors such as:
    ///         - Poor internet connectivity
    ///         - High server load
    ///         - Lengthy recordings
    func analyze() {
        Task {
            guard let result = await self.recorder.analyze() else {
                print("Analysis result is not available due to a technical issue")
                return
            }

            DispatchQueue.main.async { [weak self] in
                self?.handleAnalysisResult(result)
            }

            if (result.result_state ?? .EMPTY_ANALYSIS) != .EMPTY_ANALYSIS {
                // Example - enrich parameters by access OneStep business logic
                await motionBusinessLogicHere(measurement: result)

                // Example - provide more context by referring walk history
                weeklyWalkScore()
            }
        }
    }

    /// Build your summary screen here
    private func handleAnalysisResult(_ result: OSTMotionMeasurement) {
        switch result.result_state {
        case .EMPTY_ANALYSIS:
            print("Empty Analysis")
            self.recorderResultText = "Empty Analysis:\nerror=\(result.error.debugDescription)"
        case .PARTIAL_ANALYSIS:
            print("Parital analysis result is available")
            let steps = result.metadata?.steps ?? 0
            let cadence = result.parameters?[OSTParamName.walkingCadence.rawValue]
            self.recorderResultText = "Partial Analysis:\nsteps=\(steps)\ncadence=\(cadence != nil ? String(cadence!) : "N/A")\n"
        case .FULL_ANALYSIS:
            print("Full analysis result is available")
            let steps = result.metadata?.steps ?? 0
            let walkScore = result.parameters?[OSTParamName.walkingWalkScore.rawValue]
            self.recorderResultText = "Full Analysis:\nsteps=\(steps)\nwalk score=\(walkScore != nil ? String(walkScore!) : "N/A")\n"
        default:
            break
        }
    }

    /// This example demonstrates how to enrich the result with motion business logic:
    /// - Metadata (i.e. Display name, units, etc.)
    /// - Norms (adjusted to sex, age, etc.)
    /// - Motion Insights from the OneStep Engine (remote)
    ///
    /// - Parameter measurement: The motion measurement to be processed.
    private func motionBusinessLogicHere(measurement: OSTMotionMeasurement) async {
        // get reference to OneStep motion business logic service
        let motionService = await OSTSDKCore.shared.getMotionDataService()

        // You can enrich each parameter with metadata and norms
        let focusParams: [OSTParamName] = [.walkingVelocity, .walkingDoubleSupport, .walkingStrideLength]
        for param in focusParams {
            if let value = measurement.parameters?[param.rawValue] {
                if let metadata = motionService.getParameterMetadata(by: param) {
                    print("\(metadata.displayName): \(value) \(metadata.units ?? "")")
                } else {
                    print("\(param.rawValue): \(value)")
                }

                if let withinNorms = motionService.isWithinNorm(param: param, value: value) {
                    print("Within norms?: \(withinNorms ? "Yes" : "No")")
                } else {
                    print("Within norms?: N/A")
                }

                if let score = motionService.discreteScore(for: param, value: value) {
                    print("Score (red-yellow-green): \(score)")
                } else {
                    print("Score (red-yellow-green): N/A")
                }
                print("---")
            } else {
                print("Parameter \(param.rawValue) is not available")
            }
        }

        // You can query the insight service
        do {
            let insights = try await motionService.getInsightsBy(measurementID: measurement.id)
            if insights.isEmpty {
                print("Insights are not available")
            } else {
                for insight in insights.prefix(3) {
                    print("Insight: \(insight.textMarkdown) - type=\(insight.insightType) - intent=\(insight.intent) - param?=\(insight.paramName ?? "N/A")") // swiftlint:disable:this line_length
                    print("---")
                }
            }
        } catch {
            print("Failed to get insights: \(error.localizedDescription)")
        }
    }

    /// This sample demonstrates reading motion measurement records collected by the SDK.
    ///
    /// It is useful for features like:
    /// - Sync data to the server (in case you don't activate BE<->BE integration)
    /// - Activity history
    /// - Trends
    /// - Widgets like "today" vs "past week" vs "baseline"
    private func weeklyWalkScore() {
        // Fetch records
        var records = OSTSDKCore.shared.readMotionMeasurements()

        // filter walks
        records = records.filter { $0.type == OSTActivityType.walk.rawValue }

        // filter fully analyzed recoerds
        records = records.filter { $0.result_state == .FULL_ANALYSIS }

        // fitler by calendar week (in the future the SDK will offer time filtering)
        let calendar = Calendar.current
        let currentDate = Date()
        if let past7DaysDate = calendar.date(byAdding: .day, value: -7, to: currentDate) {
            records = records.filter { $0.timestamp >= past7DaysDate }
        }

        // Access parameters and calculate logic
        let walkScores = records.compactMap { $0.parameters?[OSTParamName.walkingWalkScore.rawValue] }
        let averageWalkScore = walkScores.reduce(0, +) / Double(walkScores.count)
        print("Your weekly walk score: \(averageWalkScore) (based on \(walkScores.count) walks)")
    }

}
