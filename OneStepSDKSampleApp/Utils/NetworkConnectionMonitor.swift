//
//  NetworkConnectionMonitor.swift
//  OneStepSDKSampleApp
//
//  Created by David Havkin on 05/08/2024.
//

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
