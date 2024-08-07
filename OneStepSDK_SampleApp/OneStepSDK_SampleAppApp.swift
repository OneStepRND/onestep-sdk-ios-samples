//
//  OneStepSDK_SampleApp.swift
//  OneStepSDK_SampleApp
//
//  Created by David Havkin on 01/08/2024.
//

import SwiftUI
import OneStepSDK

@main
struct OneStepSDK_SampleApp: App {
    let sdk: OneStepSDKInterface
    @State var connected = false
    @State var failedToConnect = false
    let ncm = NetworkConnectionMonitor()
    
    //Fill in your details before you can successfully start the app.
    init(){
        sdk = OneStepSDKCore.shared
    }
    
    var body: some Scene {
        WindowGroup {
            VStack{
                if connected {
                    RecorderView(viewModel: RecorderViewModel(recorder: self.sdk.getRecorderService()))
                } else {
                    VStack{
                        Text(failedToConnect ? "Oops... Connection attempt failed... Restart app to reconnect": "Connecting to OneStep...")
                            .font(.title2)
                            .padding(.top, 20)
                        
                        ActivityIndicator(isAnimating: !failedToConnect)
                    }
                }
            }
            .task {
                while !ncm.networkConnected {
                    print("Waiting for network...")
                }
                let connectionResult = await OneStepSDKCore.shared.initialize(appId: "<YOUR-APP-ID-HERE>",
                                                                              apiKey: "<YOUR-API-KEY-HERE>",
                                                                              distinctId: "<A-UUID-FOR CURRENT-USER-HERE>",
                                                                              identityVerification: "<YOUR-IDENTITY-VERIFICATION-SECRET-HERE> // Activate this in production")
                if connectionResult {
                    self.connected = true
                } else {
                    self.failedToConnect = true
                }
            }
        }
    }
}
