//
//  AppDelegate.swift
//  BackgroundSampleApp
//
//  Created by David Havkin on 20/01/2025.
//

import UIKit
import OneStepSDK

class AppDelegate: UIResponder, UIApplicationDelegate, ObservableObject {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        //this function HAS to be called before didFinishLaunchingWithOptions ends to register background tasks according to Apple guidelines
        //Otherwise it can cause a crash of the app
        OSTSDKCore.shared.registerBGTasks()
        return true
    }
}
