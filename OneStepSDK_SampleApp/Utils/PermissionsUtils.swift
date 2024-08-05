//
//  PermissionsUtils.swift
//  OneStepSDK_SampleApp
//
//  Created by David Havkin on 05/08/2024.
//

import CoreLocation
import CoreMotion
import AVFoundation

class PermissionsUtils {
    static func isMotionAndFitnessAuthorized() -> Bool {
        return CMMotionActivityManager.authorizationStatus() == CMAuthorizationStatus.authorized
    }
    
    static func isLocationAlwaysAuthorized() -> Bool {
        return CLLocationManager().authorizationStatus == CLAuthorizationStatus.authorizedAlways
    }
    
    static func isPreciseLocationAuthorized() -> Bool {
        return CLLocationManager().accuracyAuthorization == CLAccuracyAuthorization.fullAccuracy
    }
    
    static func requestLocationAuthorization(){
        CLLocationManager().requestWhenInUseAuthorization()
    }
    
    static func requestLocationAlways() {
        CLLocationManager().requestAlwaysAuthorization()
    }    
}
