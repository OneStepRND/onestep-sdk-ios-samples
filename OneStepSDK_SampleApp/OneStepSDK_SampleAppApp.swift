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
    
    //Fill in your details before you can successfully start the app.
    init(){
        Task{
            try? await OneStepSDKCore.shared.initialize(appId: "<YOUR-APP-ID-HERE>",
                                              apiKey: "<YOUR-API-KEY-HERE>",
                                              distinctId: "<A-UUID-FOR CURRENT-USER-HERE>")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            MainView(viewModel: MainViewViewModel())
        }
    }
}
