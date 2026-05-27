//
//  OneStepSDK_SampleApp.swift
//  OneStepSDK_SampleApp
//
//  Created by David Havkin on 01/08/2024.
//

import SwiftUI
import OneStepSDK
import UIKit
import CryptoKit

// MARK: - AppDelegate

class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Boot the SDK. Credentials are NOT passed here — they go into setPatient() below.
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

// MARK: - App

@main
struct OneStepSDK_SampleApp: App {
    @UIApplicationDelegateAdaptor private var appDelegate: AppDelegate
    @State private var connected = false
    @State private var failedToConnect = false

    private let apiKey = "<YOUR-API-KEY-HERE>"
    private let secret = "<YOUR-IDENTITY-SECRET-HERE>"
    private let customerPatientId = "<A-UNIQUE-ID-FOR-CURRENT-USER-HERE>"

    var body: some Scene {
        WindowGroup {
            VStack {
                if connected {
                    RecorderView(viewModel: RecorderViewModel())
                } else if failedToConnect {
                    Text("Unable to connect. Please check your internet connection or verify your API tokens.")
                        .font(.title2)
                        .padding(.top, 20)
                } else {
                    VStack {
                        Text("Connecting... Please wait.")
                            .font(.title2)
                            .padding(.top, 20)
                    }
                    ActivityIndicator(isAnimating: !failedToConnect && !connected)
                }
            }
            .task {
                await initializeSDK()
            }
        }
    }

    /// Identify the patient with the SDK.
    ///
    /// V2 separates boot (AppDelegate) from patient identification (here).
    /// If a patient was already identified on a previous launch, the SDK will
    /// have restored their session silently during boot — we detect that and
    /// skip calling setPatient again.
    ///
    /// Retrieve your API tokens from OneStep back-office -> Developers -> Settings.
    private func initializeSDK() async {
        guard case .success(let sdk) = OneStep.shared() else {
            failedToConnect = true
            return
        }

        // Silent restore: patient already identified from a previous launch.
        if case .identified = sdk.authStateValue {
            connected = true
            return
        }

        /*
         Parameters:
         - apiKey: The API key associated with your OneStep account.
         - customerPatientId: A unique identifier for the current user (can be a technical ID,
           does not need to contain PII). Used for BE<->BE integration and webhooks.
         - identityVerification: HMAC-SHA256 of customerPatientId signed with your secret.
           In production, retrieve this from your server.
         */
        let hmac = generateHmac(secret: secret, distinctId: customerPatientId)
        let result = await sdk.setPatient(
            apiKey: apiKey,
            customerPatientId: customerPatientId,
            identityVerification: hmac
        )

        switch result {
        case .success:
            connected = true
        case .failure(let error):
            print("OneStep setPatient failed: \(error)")
            failedToConnect = true
        }
    }

    private func generateHmac(secret: String, distinctId: String) -> String? {
        guard !secret.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
        let key = SymmetricKey(data: Data(secret.utf8))
        let code = HMAC<SHA256>.authenticationCode(for: Data(distinctId.utf8), using: key)
        return Data(code).map { String(format: "%02x", $0) }.joined()
    }
}
