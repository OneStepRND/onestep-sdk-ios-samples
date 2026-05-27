//
//  AppDelegate.swift
//  BackgroundSampleApp
//
//  Created by David Havkin on 20/01/2025.
//

import UIKit
import OneStepSDK

class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Must be called before didFinishLaunchingWithOptions returns (Apple requirement)
        OneStep.registerBGTasks()

        // Boot the SDK. Credentials are NOT passed here — they go into setPatient() in the App.
        // On subsequent launches the SDK silently restores the previously identified patient
        // from Keychain automatically.
        _ = OneStep.initialize(
            onAuthLost: { error in
                print("OneStep auth lost: \(error)")
            }
        )
        return true
    }
}
