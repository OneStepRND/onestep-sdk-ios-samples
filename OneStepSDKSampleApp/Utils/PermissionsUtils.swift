//
//  PermissionsUtils.swift
//  OneStepSDKSampleApp
//
//  Created by David Havkin on 05/08/2024.
//

import CoreLocation
import CoreMotion
import AVFoundation

public class PermissionsUtils {

    public static func allPermissionsInPlace() -> Bool {
        if !isMotionAndFitnessAuthorized() {
            requestMotionAndFitnessAuthorized()
            return false
        } else if !isLocationWhenInUseAuthorized() && !isLocationAlwaysAuthorized() {
            requestLocationAuthorization()
            return false
        } else if isLocationWhenInUseAuthorized() && !isLocationAlwaysAuthorized() {
            requestLocationAlways()
            return false
        }

        return true
    }

    private static func isMotionAndFitnessAuthorized() -> Bool {
        return CMMotionActivityManager.authorizationStatus() == CMAuthorizationStatus.authorized
    }

    private static func isLocationWhenInUseAuthorized() -> Bool {
        return CLLocationManager().authorizationStatus == CLAuthorizationStatus.authorizedWhenInUse
    }

    private static func isLocationAlwaysAuthorized() -> Bool {
        return CLLocationManager().authorizationStatus == CLAuthorizationStatus.authorizedAlways
    }

    private static func requestLocationAuthorization() {
        CLLocationManager().requestWhenInUseAuthorization()
    }

    private static func requestLocationAlways() {
        CLLocationManager().requestAlwaysAuthorization()
    }

    private static func requestMotionAndFitnessAuthorized() {
        CMMotionActivityManager().startActivityUpdates(to: .main, withHandler: { _ in

        })
    }
}
