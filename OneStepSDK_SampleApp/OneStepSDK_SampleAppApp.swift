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
                        Text("Connecting to OneStep...")
                            .font(.title2)
                        ActivityIndicator(isAnimating: true)
                        
                    }
                }
            }
            .task {
                while !ncm.networkConnected {
                    print("Waiting for network...")
                }
                
                try? await OneStepSDKCore.shared.initialize(appId: "<YOUR-APP-ID-HERE>",
                                                            apiKey: "<YOUR-API-KEY-HERE>",
                                                            distinctId: "<A-UUID-FOR CURRENT-USER-HERE>")
                self.connected = true
            }
        }
    }
}
