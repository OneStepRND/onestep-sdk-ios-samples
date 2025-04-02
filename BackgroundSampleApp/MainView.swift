//
//  MainView.swift
//  BackgroundSampleApp
//
//  Created by David Havkin on 22/08/2024.
//

import SwiftUI

struct MainView: View {
    @ObservedObject var viewModel: BackgroundViewModel

    var body: some View {
        VStack {
            Text("OneStep Sample: Background")
                .font(.title)
                .padding(.top, 20)

            Divider()

            Text("All Permissions: \(viewModel.permissions ? "Granted" : "Not Granted")")
                .padding(.bottom, 10)
                .font(.title3)

            Button(action: viewModel.askForPermissions) {
                Text("Ask Permissions")
                    .font(.title)
            }
            .disabled(viewModel.permissions)

            Divider()

            Text("Background Monitoring: \(viewModel.activated ? "Activated" : "Not Activated")")
                .padding(.bottom, 10)
                .font(.title3)

            Button(action: viewModel.register) {
                Text("Register")
                    .font(.title)
            }
            .padding(.bottom, 10)
            .disabled(viewModel.activated)

            Button(action: viewModel.unregister) {
                Text("Unregister")
                    .font(.title)
            }
            .padding(.bottom, 30)
            .disabled(!viewModel.activated)

            Button(action: viewModel.qaTrigger) {
                Text("QA Trigger")
                    .font(.title)
            }
            .padding(.bottom, 30)

            Divider()

            Text("Last Sample: \(viewModel.lastSample?.ISO8601Format() ?? "N/A")")
                .padding(.bottom, 10)
                .font(.title3)
            Text("Last Sync: \(viewModel.lastSync?.ISO8601Format() ?? "N/A")")
                .padding(.bottom, 10)
                .font(.title3)

            Button(action: viewModel.syncNow) {
                Text("Sync Now")
                    .font(.title)
            }
            .disabled(viewModel.syncInProgress)

            Divider()

            Text("Daily Walk Score: \(viewModel.dailyWalkScore != nil ? String(viewModel.dailyWalkScore!) : "N/A")")
                .padding(.bottom, 10)
                .font(.title3)

            Spacer()
        }
        .padding()
    }
}

#Preview {
    MainView(viewModel: BackgroundViewModel())
}
