//
//  ContentView.swift
//  OneStepUIKitExample
//
//  Created by Maor Duani on 26/08/2024.
//

import SwiftUI
import OneStepUIKit
import OneStepSDK

struct ExampleViewsSelection: View {

    @State private var selectedItem: ExampleItem?
    private var theme = OSTTheme()

    init() {
        // Use your brand pirmary color here.
        // Set it once and pass as EnvironmentValue to all subviews.
        theme.primaryColor = .purple
    }

    var body: some View {
        NavigationStack {
            List(ExampleItem.allCases) { item in
                Button {
                    selectedItem = item
                } label: {
                    Label(item.title, systemImage: item.systemImage)
                        .padding(.vertical)
                }
            }
            .navigationTitle("UIKit Examples")
        }
        .fullScreenCover(item: $selectedItem) { item in
            view(for: item)
        }
        .oneStepTheme(theme)
    }
}

// MARK: - Private helpers
extension ExampleViewsSelection {

    /// Returns a view corresponding to the selected `ExampleItem`.
    @ViewBuilder
    private func view(for item: ExampleItem) -> some View {
        switch item {
        case .defaultWalk:
            defaultWalkRecordingView()
        case .sixMinutesRecording:
            sixMinutesRecordingView()
        case .carelog:
            carelogView()
        case .measurementSummary:
            if let measurementID = OSTSDKCore.shared.readMotionMeasurements().last?.id {
                /// Summary screen for your latest measurement
                OSTMeasurementSummaryScreen(measurementID: measurementID, origin: .carelog) {
                    selectedItem = nil
                } onExit: {
                    selectedItem = nil
                }
            } else {
                noWalksView
            }
        }
    }

    /// Recording flow with default settings
    private func defaultWalkRecordingView() -> some View {
        OSTRecordingFlow(config: OSTRecordingConfiguration())
    }

    /// Presents a customized recording flow for the 6-Minute Walk Test (6MWT).
    /// This function demonstrates how to configure the recording flow and customize instructions to implement this standard test.
    ///
    /// Media supports images, GIFs, and videos loaded either from local resources or remote URLs.
    ///
    /// Attaches custom metadata with additional context to the created measurement, which is accessible via the Platform API or webhooks.
    private func sixMinutesRecordingView() -> some View {
        let imageURL = "https://thoracicandsleep.com.au/wp-content/uploads/2022/11/IDEA-LG-COPD-Monitoring-Model-Offers-Potential-Alternative-to-6-Minute-Walk-Test-image-1.jpg"

        let config = OSTRecordingConfiguration(
            activityType: .walk,
            duration: 360,
            isCountingDown: true,
            showPhonePositionScreen: false,
            prepareScreenDuration: .tenSeconds,
            playVoiceOver: true,
            instructions: .init(
                activityDisplayName: "6 Minute Walk Test",
                instructions: [
                    "The object of this test is to walk as far as possible for 6 minutes",
                    "You will walk back and forth in this hallway.",
                    "You are permitted to slow down, to stop, and to rest as necessary"
                ],
                hints: [
                    "You may lean against the wall while resting"
                ],
                media: OSTVisualResource(
                    mediaType: .image,
                    location: .url(URL(string: imageURL)!)
                )
            ),
            preRecordingQuestions: [
                OSTPreRecordingQuestion(
                    title: "Demo Question",
                    options: ["tag1", "tag2"],
                    isMultiSelect: false
                )
            ]
        )
        return OSTRecordingFlow(
            config: config,
            customMetadata: ["custom_activity": .string("6mwt")]
        )
    }

    /// Presents the Carelog screen, displaying a history of active measurements and daily aggregated background data.
    ///
    /// The Carelog screen allows users to review their recorded activities and background metrics.
    /// You can pass a custom `OSTRecordingConfiguration` to be used in the empty state call-to-action.
    private func carelogView() -> some View {
        return OSTCarelogScreen(
            recordingConfiguration: OSTRecordingConfiguration(),
            includeBackgroundData: true
        )
    }

    private var noWalksView: some View {
        VStack(spacing: 30) {
            Text("No walks found")
                .font(.title)
            Button("Close") {
                selectedItem = nil
            }
            .buttonStyle(.borderedProminent)
        }
    }

}

// MARK: - Model
extension ExampleViewsSelection {

    private enum ExampleItem: Identifiable, CaseIterable {
        case defaultWalk
        case sixMinutesRecording
        case carelog
        case measurementSummary

        var title: String {
            switch self {
            case .defaultWalk:
                return "Recording flow: default"
            case .sixMinutesRecording:
                return "Recording flow: 6MWT"
            case .carelog:
                return "Carelog"
            case .measurementSummary:
                return "Summary"
            }
        }

        var systemImage: String {
            switch self {
            case .defaultWalk:
                return "figure.walk"
            case .sixMinutesRecording:
                return "6.circle"
            case .carelog:
                return "list.clipboard"
            case .measurementSummary:
                return "gauge.open.with.lines.needle.33percent"
            }
        }

        var id: String {
            title
        }
    }
}

#Preview {
    ExampleViewsSelection()
}
