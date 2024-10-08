//
//  BackgroundSampleAppApp.swift
//  BackgroundSampleApp
//
//  Created by David Havkin on 22/08/2024.
//

import SwiftUI
import OneStepSDK

@main
struct BackgroundSampleAppApp: App {
    let sdk: OSTCoreInterface
    @State var connected = false
    @State var failedToConnect = false
    let ncm = NetworkConnectionMonitor()
    
    init(){
        sdk = OSTSDKCore.shared
    }
    
    var body: some Scene {
        WindowGroup {
            VStack{
                if connected {
                    MainView(viewModel: BackgroundViewModel())
                } else if failedToConnect {
                    Text("Unable to connect. Please check your internet connection or verify your API tokens.")
                        .font(.title2)
                        .padding(.top, 20)
                } else {
                    VStack{
                        Text("Connecting... Please wait.")
                            .font(.title2)
                            .padding(.top, 20)
                    }
                    ActivityIndicator(isAnimating: !failedToConnect && !connected)
                }
            }
            .task {
                while !ncm.networkConnected {
                    print("Waiting for network...")
                }
                
                /*
                 Initialize the OneStep SDK. You can retrieve your API tokens from OneStep back-office -> Developers -> Settings
                 
                 Parameters:
                 - appId: The unique identifier for your application, provided by OneStep.
                 - apiKey: The API key associated with your OneStep account, required for authentication.
                 - distinctId: A unique identifier, which can be purely technical without containing PII.
                 This identifier enables synchronization of the data collected by OneStep with your existing identities.
                 It will also be included in the Platform API (BE<->BE integration) and webhooks.
                 Note: An identity can be connected to multiple devices simultaneously.
                 - identityVerification: This parameter is optional and used for additional security. In production, it's recommended to retrieve this token from your server to ensure secure identity verification.
                 - configuration: SDK configuration
                 */
                OSTSDKCore.shared.initialize(
                    appId: "<YOUR-APP-ID-HERE>",
                    apiKey: "<YOUR-API-KEY-HERE>",
                    distinctId: "<A-UNIQUE-ID-FOR CURRENT-USER-HERE>",
                    identityVerification: nil,
                    configuration: OSTConfiguration(enableMonitoringFeature: true)){ connectionResult in
                        if connectionResult {
                            print("OneStep SDK is initialized")
                            self.connected = true
                        } else {
                            print("OneStep SDK could not initialized")
                            self.failedToConnect = true
                        }
                    }
            }
        }
    }
}


struct ActivityIndicator: UIViewRepresentable {
    typealias UIView = UIActivityIndicatorView
    var isAnimating: Bool
    var configuration = { (indicator: UIView) in }
    
    func makeUIView(context: UIViewRepresentableContext<Self>) -> UIView { UIView() }
    func updateUIView(_ uiView: UIView, context: UIViewRepresentableContext<Self>) {
        isAnimating ? uiView.startAnimating() : uiView.stopAnimating()
        configuration(uiView)
    }
}

import Network

class NetworkConnectionMonitor{
    var networkConnected: Bool = false
    
    init() {
        let monitor = NWPathMonitor()
        monitor.pathUpdateHandler = { path in
            self.networkConnected = !(path.status != .satisfied)
        }
        
        monitor.start(queue: DispatchQueue.global(qos: .background))
    }
}
