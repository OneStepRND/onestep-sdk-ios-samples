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
    
    private let sdk: OSTCoreInterface
    private let ncm = NetworkConnectionMonitor()
    @State private var connected = false
    @State private var failedToConnect = false
    
    init(){
        sdk = OSTSDKCore.shared
    }
    
    var body: some Scene {
        WindowGroup {
            VStack{
                if connected {
                    ExampleViewsSelection()
                } else if failedToConnect {
                    Text("Unable to connect. Please check your internet connection or verify your API tokens.")
                        .font(.title2)
                        .padding(.top, 20)
                } else {
                    VStack{
                        Text("Connecting... Please wait.")
                            .font(.title2)
                            .padding(.top, 20)
                    }
                }
            }
            .task {
                while !ncm.networkConnected {
                    print("Waiting for network...")
                }
                
                /*
                 Initialize the OneStep SDK. You can retrieve your API tokens from OneStep back-office -> Developers -> Settings
                 
                 Parameters:
                 - appId: The unique identifier for your application, provided by OneStep.
                 - apiKey: The API key associated with your OneStep account, required for authentication.
                 - distinctId: A unique identifier, which can be purely technical without containing PII.
                 This identifier enables synchronization of the data collected by OneStep with your existing identities.
                 It will also be included in the Platform API (BE<->BE integration) and webhooks.
                 Note: An identity can be connected to multiple devices simultaneously.
                 - identityVerification: This parameter is optional and used for additional security. In production, it's recommended to retrieve this token from your server to ensure secure identity verification.
                 - configuration: SDK configuration
                 */
                let connectionResult = await OSTSDKCore.shared.initialize(
                    appId: "<YOUR-APP-ID-HERE>",
                    apiKey: "<YOUR-API-KEY-HERE>",
                    distinctId: "<A-UNIQUE-ID-FOR CURRENT-USER-HERE>",
                    identityVerification: nil,
                    configuration: OSTConfiguration(enableMonitoringFeature: false)
                )
                if connectionResult {
                    print("OneStep SDK is initialized")
                    self.connected = true
                } else {
                    print("OneStep SDK could not initialized")
                    self.failedToConnect = true
                }
            }
        }
    }
}

import Network

class NetworkConnectionMonitor {
    var networkConnected: Bool = false
    
    init() {
        let monitor = NWPathMonitor()
        monitor.pathUpdateHandler = { path in
            self.networkConnected = !(path.status != .satisfied)
        }
        
        monitor.start(queue: DispatchQueue.global(qos: .background))
    }
}
