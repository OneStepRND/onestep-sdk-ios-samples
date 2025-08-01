//
//  OneStepUIKitExampleApp.swift
//  OneStepUIKitExample
//
//  Created by Maor Duani on 26/08/2024.
//

import SwiftUI
import OneStepUIKit
import OneStepSDK

@main
struct OneStepUIKitExampleApp: App {

    @State private var connected = false
    @State private var failedToConnect = false

    var body: some Scene {
        WindowGroup {
            VStack {
                if connected {
                    ExampleViewsSelection()
                } else if failedToConnect {
                    Text("Unable to connect. Please check your internet connection or verify your API tokens.")
                        .font(.title2)
                        .padding(.top, 20)
                } else {
                    Text("Connecting... Please wait.")
                        .font(.title2)
                        .padding(.top, 20)
                }
            }
            .onAppear {
                initializeSDK()
            }
        }
    }

    /// Initialize the OneStep SDK.
    /// Retrieve your API tokens from the OneStep back-office -> Developers -> Settings.
    func initializeSDK() {
        /**
         Parameters:
         - appId: The unique identifier for your application, provided by OneStep.
         - apiKey: The API key associated with your OneStep account, required for authentication.
         - distinctId: A unique identifier that can be purely technical without containing PII. This identifier enables synchronization of the data collected by OneStep with your existing identities. It will also be included in the Platform API (BE<->BE integration) and webhooks.
         - Note: An identity can be connected to multiple devices simultaneously.
         - identityVerification: *(Optional)* Used for additional security. In production, it's recommended to retrieve this token from your server to ensure secure identity verification.
         - configuration: SDK configuration settings.
         */
        OSTSDKCore.shared.initialize(
            appId: "<YOUR-APP-ID-HERE>",
            apiKey: "<YOUR-API-KEY-HERE>",
            distinctId: "<A-UNIQUE-ID-FOR CURRENT-USER-HERE>",
            identityVerification: nil,
            configuration: OSTConfiguration(enableMonitoringFeature: true)) { connectionResult in
            if connectionResult {
                print("OneStep SDK is initialized")
                self.connected = true
                print("OneStep SDK sync")
                Task {
                    await OSTSDKCore.shared.sync()
                }
            } else {
                print("OneStep SDK could not initialized")
                self.failedToConnect = true
            }
        }
    }
}
