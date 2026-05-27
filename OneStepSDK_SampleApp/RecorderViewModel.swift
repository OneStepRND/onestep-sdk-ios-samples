//
//  RecorderViewModel.swift
//  OneStepSDK_SampleApp
//
//  Created by David Havkin on 05/08/2024.
//

import Foundation
import OneStepSDK
import Combine

class RecorderViewModel: ObservableObject {
    private let recorder: OSTRecorderProtocol

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

    init() {
        // Resolve V2 modules. preconditionFailure here means a developer
        // misuse — building this view model before OneStep.initialize().
        guard case .success(let sdk) = OneStep.shared(),
              case .success(let motionLab) = sdk.motionLab()
        else {
            preconditionFailure("RecorderViewModel constructed before OneStep.initialize()")
        }
        self.recorder = motionLab.recorder
        setupRecorderSubscriber()
        setupAnalyzerSubscriber()
    }

    private func setupRecorderSubscriber() {
        recorderSubscriber = recorder.recorderState
            .receive(on: RunLoop.main)
            .sink { [weak self] recorderState in
                guard let self else { return }
                switch recorderState {
                case .idle:
                    print("OneStep Recorder is ready for use")
                    recordingInProgress = false
                    uiState = "Idle"
                case .recording(let uuid):
                    print("OneStep Recorder in progress - measurement id=\(uuid)")
                    recordingInProgress = true
                    uiState = "Recording"
                case .finishedRecording:
                    print("OneStep Recorder Finished")
                    recordingInProgress = false
                    uiState = "Finished Recording"

                    // Trigger analysis for immediate feedback after saving a new motion measurement.
                    analyze()

                    // Reset the recorder internal state before your next recording.
                    recorder.reset()
                default:
                    break
                }
            }
    }

    private func setupAnalyzerSubscriber() {
        analyzerSubscriber = recorder.analyzerState
            .receive(on: RunLoop.main)
            .sink { [weak self] analyzerState in
                guard let self else { return }
                switch analyzerState {
                case .idle:
                    break
                case .analyzing:
                    analyzingInProgress = true
                    uiState = "Analyzing"
                case .analyzedAndSavedSuccessfully:
                    print("Analysis completed and saved successfully.")
                    analyzingInProgress = false
                    uiState = "Result Available"
                case .error(let errorType):
                    print("Error occurred during analysis: \(errorType)")
                    analyzingInProgress = false
                    uiState = "Error"
                default:
                    break
                }
            }
    }

    /// Start recording a new session: timed walk (60 seconds).
    ///
    /// Developer responsibilities:
    /// - Handle the recorder state machine (e.g., don't call `start` when already recording).
    /// - Ensure motion and location permissions are granted and usage descriptions are in the info.plist.
    ///
    /// NOTE: Recording will only start after motion & fitness permission and location permission are granted.
    func startRecording() {
        let userInputMetadata = OSTUserInputMetaData(
            note: "this is a free-text note",
            tags: ["tag1", "tag2", "tag3"],
            assistiveDevice: .cane,
            levelOfAssistance: .independent
        )

        let customMetadata: Dictionary<String, OSTMixedType> = [
            "app": .string("DemoApp"),
            "is_demo": .bool(true),
            "version": .double(1.1),
        ]

        recorder.start(
            activityType: .walk,
            // Duration in seconds. The user can manually stop before it elapses.
            // If not specified, the SDK applies a 6-minute technical limit.
            duration: 60,
            // Optional user-facing metadata: free-text note, tags, assistive device, etc.
            userInputMetadata: userInputMetadata,
            // Technical key-value properties propagated to the measurement result.
            // Supports Bool, Int, String, Double.
            customMetadata: customMetadata
        )

        startUITimer()
        resetUIState()
    }

    private func startUITimer() {
        timerSubscriber = timer.map { _ in
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
        timerSubscriber?.cancel()
    }

    ///   The data analysis process involves several steps:
    ///     1. Upload raw motion data to the OneStep servers.
    ///     2. Process the data asynchronously via the analysis pipeline.
    ///     3. Retrieve the analysis results through the SDK as soon as they are available.
    ///
    ///     For a short walk, this process typically takes 5-15 seconds.
    func analyze() {
        Task {
            guard let result = await recorder.analyze() else {
                print("Analysis result is not available due to a technical issue")
                return
            }

            await MainActor.run {
                handleAnalysisResult(result)
            }

            if (result.result_state ?? .EMPTY_ANALYSIS) != .EMPTY_ANALYSIS {
                // Example: enrich parameters with metadata, norms, and insights
                await motionBusinessLogicHere(measurement: result)

                // Example: summarize recent walk history
                weeklyWalkScore()
            }
        }
    }

    /// Build your summary screen here
    private func handleAnalysisResult(_ result: OSTMotionMeasurement) {
        switch result.result_state {
        case .EMPTY_ANALYSIS:
            print("Empty Analysis")
            recorderResultText = "Empty Analysis:\nerror=\(result.error.debugDescription)"
        case .PARTIAL_ANALYSIS:
            print("Partial analysis result is available")
            let steps = result.metadata?.steps ?? 0
            let cadence = result.parameters?[OSTParamName.walkingCadence.rawValue]
            recorderResultText = "Partial Analysis:\nsteps=\(steps)\ncadence=\(cadence != nil ? String(cadence!) : "N/A")\n"
        case .FULL_ANALYSIS:
            print("Full analysis result is available")
            let steps = result.metadata?.steps ?? 0
            let walkScore = result.parameters?[OSTParamName.walkingWalkScore.rawValue]
            recorderResultText = "Full Analysis:\nsteps=\(steps)\nwalk score=\(walkScore != nil ? String(walkScore!) : "N/A")\n"
        default:
            break
        }
    }

    /// This example demonstrates how to enrich the result with motion business logic:
    /// - Metadata (display name, units, etc.)
    /// - Norms (adjusted to sex, age, etc.)
    /// - Motion Insights from the OneStep Engine (remote)
    ///
    /// - Parameter measurement: The motion measurement to be processed.
    private func motionBusinessLogicHere(measurement: OSTMotionMeasurement) async {
        guard case .success(let sdk) = OneStep.shared(),
              case .success(let insights) = sdk.insights() else { return }

        // Get the motion data service for parameter metadata, norms, and scores
        let motionService = await insights.getMotionDataService()

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

        // Query insights for this measurement
        do {
            let measurementInsights = try await insights.getInsights(for: measurement.id)
            if measurementInsights.isEmpty {
                print("Insights are not available")
            } else {
                for insight in measurementInsights.prefix(3) {
                    print("Insight: \(insight.textMarkdown) - type=\(insight.insightType) - intent=\(insight.intent) - param?=\(insight.paramName ?? "N/A")")
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
    /// - Activity history
    /// - Trends
    /// - Widgets like "today" vs "past week" vs "baseline"
    private func weeklyWalkScore() {
        guard case .success(let sdk) = OneStep.shared(),
              case .success(let motionLab) = sdk.motionLab() else { return }

        // Fetch all records (nil start/end = no time filter)
        var records = (try? motionLab.getMeasurements(request: TimeRangedDataRequest(startTime: nil, endTime: nil))) ?? []

        // Filter walks
        records = records.filter { $0.type == OSTActivityType.walk.rawValue }

        // Filter fully analyzed records
        records = records.filter { $0.result_state == .FULL_ANALYSIS }

        // Filter past 7 days
        let calendar = Calendar.current
        if let past7DaysDate = calendar.date(byAdding: .day, value: -7, to: Date()) {
            records = records.filter { $0.timestamp >= past7DaysDate }
        }

        // Calculate average walk score
        let walkScores = records.compactMap { $0.parameters?[OSTParamName.walkingWalkScore.rawValue] }
        let averageWalkScore = walkScores.isEmpty ? 0 : walkScores.reduce(0, +) / Double(walkScores.count)
        print("Your weekly walk score: \(averageWalkScore) (based on \(walkScores.count) walks)")
    }
}
