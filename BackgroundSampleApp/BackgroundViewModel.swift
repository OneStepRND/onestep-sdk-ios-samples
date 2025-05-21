//
//  BackgroundViewModel.swift
//  BackgroundSampleApp
//
//  Created by David Havkin on 22/08/2024.
//

import Foundation
import OneStepSDK
import Combine
import CoreMotion
import CoreLocation

class BackgroundViewModel: ObservableObject {
    
    @Published var activated = false
    @Published var permissions = false
    @Published var lastSample: Date? = nil
    @Published var lastSync: Date? = nil
    @Published var dailyWalkScore: Double? = nil
    @Published var syncInProgress = false
    
    private let motionManager = CMMotionActivityManager()
    private let locationManager = CLLocationManager()
    
    init() {
        self.activated = OSTSDKCore.shared.isBackgroundMonitoringActive()
        updateBgStatsUI()
    }
    
    /// The hosting app must explicitly opt-in for background monitoring by calling this method.
    /// The SDK will persist the latest preference, so it does not need to be called on every app launch.
    /// However, background monitoring may still be deactivated due to missing permissions or system restrictions.
    /// Always verify the current status using `isBackgroundMonitoringActive()` to ensure it is active.
    func register() {
        OSTSDKCore.shared.registerBackgroundMonitoring()
        self.activated = OSTSDKCore.shared.isBackgroundMonitoringActive()
    }
    
    /// Unregisters the hosting app from background monitoring, effectively opting out of this feature.
    /// The SDK will persist this preference, so background monitoring will remain inactive until explicitly re-enabled.
    func unregister() {
        OSTSDKCore.shared.unregisterBackgroundMonitoring()
        self.activated = OSTSDKCore.shared.isBackgroundMonitoringActive()
    }
    
    /// Triggers a test recording for quality assurance (QA) purposes in the background.
    /// This method simulates the background recording process, allowing developers to verify that the featuer is functioning correctly within the app.
    /// It is intended for testing and validation during development and should not be used in production.
    func qaTrigger() {
        OSTSDKCore.shared.testBackgroundRecording()
    }
    
    /// Forces an immediate synchronization of pending samples with the OneStep servers.
    /// The SDK automatically attempts to sync in the background using iOS background tasks.
    /// You can query the last sync time using `OSTSDKCore.shared.backgroundMonitoringStats()`.
    ///
    /// This method is useful when you or the end-user wants to force a "sync now" operation to ensure that the most up-to-date results are available.
    func syncNow() {
        self.syncInProgress = true
        Task {
            await OSTSDKCore.shared.sync()
            DispatchQueue.main.async {
                self.updateBgStatsUI()
                self.syncInProgress = false
            }
        }
    }
    
    func askForPermissions() {
        if CMMotionActivityManager.authorizationStatus() != .authorized {
            motionManager.startActivityUpdates(to: .main) { _ in }
        } else if !isLocationWhenInUseAuthorized() && !isLocationAlwaysAuthorized() {
            locationManager.requestWhenInUseAuthorization()
        } else if isLocationWhenInUseAuthorized() && !isLocationAlwaysAuthorized() {
            locationManager.requestAlwaysAuthorization()
        } else {
            permissions = true
        }
    }
    
    /// Access background stats like status, permission status, last collected sample, last upload time,  last pull result time, etc..
    private func updateBgStatsUI() {
        let stats = OSTSDKCore.shared.backgroundMonitoringStats()
        self.activated = stats.activated
        self.permissions = stats.hasBackgroundPermissions
        self.lastSample = stats.lastSampleCollected
        self.lastSync = stats.lastUploadSync
    }
    
    private func updateDailyWalkScore() {
        // todo: implement
    }
    
    private func isLocationWhenInUseAuthorized() -> Bool {
        return CLLocationManager().authorizationStatus == CLAuthorizationStatus.authorizedWhenInUse
    }
    
    private func isLocationAlwaysAuthorized() -> Bool {
        return CLLocationManager().authorizationStatus == CLAuthorizationStatus.authorizedAlways
    }
    
}
