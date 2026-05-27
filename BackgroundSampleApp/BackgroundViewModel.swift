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

@MainActor
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
        self.activated = sdk?.isBackgroundMonitoringActive() ?? false
        Task { await updateBgStatsUI() }
    }

    // Convenience accessor — resolves once per call, safe to call from any method.
    private var sdk: OneStep? {
        guard case .success(let s) = OneStep.shared() else { return nil }
        return s
    }

    private var monitoring: (any Monitoring)? {
        guard let sdk, case .success(let m) = sdk.monitoring() else { return nil }
        return m
    }

    /// The hosting app must explicitly opt-in for background monitoring by calling this method.
    /// The SDK will persist the latest preference, so it does not need to be called on every app launch.
    /// However, background monitoring may still be deactivated due to missing permissions or system restrictions.
    /// Always verify the current status using `isBackgroundMonitoringActive()` to ensure it is active.
    func register() {
        guard var m = monitoring else { return }
        m.enable(config: .default)
        m.optIn()
        self.activated = sdk?.isBackgroundMonitoringActive() ?? false
    }

    /// Unregisters the hosting app from background monitoring, effectively opting out of this feature.
    /// The SDK will persist this preference, so background monitoring will remain inactive until explicitly re-enabled.
    func unregister() {
        monitoring?.optOut()
        self.activated = sdk?.isBackgroundMonitoringActive() ?? false
    }

    /// Triggers a test recording for quality assurance (QA) purposes in the background.
    /// Intended for testing and validation during development — do not use in production.
    func qaTrigger() {
        guard case .success(let sdk) = OneStep.shared(),
              case .success(let motionLab) = sdk.motionLab() else { return }
        (motionLab.recorder as? OSTRecorder)?.triggerBgTask()
    }

    /// Forces an immediate synchronization of pending samples with the OneStep servers.
    /// The SDK automatically attempts to sync in the background using iOS background tasks.
    ///
    /// Use this when you or the end-user wants to force a "sync now" operation to ensure
    /// that the most up-to-date results are available.
    func syncNow() {
        syncInProgress = true
        Task {
            _ = await sdk?.sync()
            await updateBgStatsUI()
            syncInProgress = false
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

    /// Access background stats — active state and permission status.
    private func updateBgStatsUI() async {
        guard let monitoring else { return }
        self.activated = sdk?.isBackgroundMonitoringActive() ?? false
        self.permissions = monitoring.fullBackgroundPermissions()
    }

    private func isLocationWhenInUseAuthorized() -> Bool {
        CLLocationManager().authorizationStatus == .authorizedWhenInUse
    }

    private func isLocationAlwaysAuthorized() -> Bool {
        CLLocationManager().authorizationStatus == .authorizedAlways
    }
}
