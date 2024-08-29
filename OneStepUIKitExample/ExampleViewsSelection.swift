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
    private var theme = OneStepTheme()
    
    init() {
        // Changing brand color will effect all CTA buttons, and other main
        // components which aim to focus the user's attention.
        // Set it once and pass as EnvironmentValue to all subviews.
        theme.brandColor = .purple
    }
    
    var body: some View {
        NavigationStack {
            VStack { 
                List(ExampleItem.allCases) { item in
                    Button(action: {
                        selectedItem = item
                    }, label: {
                        Label(
                            item.title,
                            systemImage: item.systemImage
                        )
                    })
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
    
    @ViewBuilder
    private func view(for item: ExampleItem) -> some View {
        switch item {
        case .shortWalk:
            let config = RecordingFlowConfiguration(
                measurementDuration: 60,
                askForPhonePlacement: false,
                countdownPreperation: nil,
                voiceOverActive: true,
                instructions: .default
            )
            RecordingFlow(config: config)
        case .sixMinutesRecording:
            
            
            RecordingFlow(
                config: .init(
                    measurementDuration: 360,
                    askForPhonePlacement: true,
                    countdownPreperation: .fiveSeconds,
                    voiceOverActive: false,
                    instructions: .init(
                        title: "6 Minute Walk Test",
                        instructions: [
                            "The object of this test is to walk as far as possible for 6 minutes",
                            "You will walk back and forth in this hallway.",
                            "You are permitted to slow down, to stop, and to rest as necessary"
                        ],
                        hints: [
                            "You may lean against the wall while resting"
                        ],
                        resource: sixMinVisualResource
                    )
                )
            )
        case .carelog:
            let config = RecordingFlowConfiguration(
                measurementDuration: 60,
                askForPhonePlacement: false,
                countdownPreperation: nil,
                voiceOverActive: true,
                instructions: .default
            )
            OSTCarelogScreen(config: config)
        case .measurementSummary:
            if let measurementID = OSTSDKCore.shared.readMotionMeasurements().first?.id {
                measurementScreen(withID: measurementID)
            } else {
                noWalksView
            }
        }
    }
    
    private var sixMinVisualResource: VisualResource? {
        guard let url = URL(string: "https://thoracicandsleep.com.au/wp-content/uploads/2022/11/IDEA-LG-COPD-Monitoring-Model-Offers-Potential-Alternative-to-6-Minute-Walk-Test-image-1.jpg") else {
            return nil
        }
        return VisualResource(mediaType: .image, urlType: .url(url))
    }
    
    private func measurementScreen(withID uuid: UUID) -> some View {
        MeasurementSummaryScreen(
            measurementUUID: uuid,
            output: .init(onDeletion: {
                selectedItem = nil
            }, onQuitFlow: {
                selectedItem = nil
            })
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
        case shortWalk
        case sixMinutesRecording
        case carelog
        case measurementSummary
        
        var title: String {
            switch self {
            case .shortWalk:
                "Recording flow"
            case .sixMinutesRecording:
                "6 minutes recording"
            case .carelog:
                "Carelog"
            case .measurementSummary:
                "Summary"
            }
        }
        
        var systemImage: String {
            switch self {
            case .shortWalk:
                "figure.walk"
            case .sixMinutesRecording:
                "6.circle"
            case .carelog:
                "list.clipboard"
            case .measurementSummary:
                "gauge.open.with.lines.needle.33percent"
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

