//
//  CustomButton.swift
//  OneStepSDK_SampleApp
//
//  Created by David Havkin on 05/08/2024.
//

import SwiftUI

struct CustomButton: View {
    @Environment(\.isEnabled) var isEnabled
    let title: String
    let action: () -> Void
    let isActivated: Bool?
    let height: CGFloat
    
    init(title: String, action: @escaping () -> Void, isActivated: Bool? = nil, height: CGFloat = 50) {
        self.title = title
        self.action = action
        self.isActivated = isActivated
        self.height = height
    }
    
    var body: some View {
        Button(action: {
            action()
        }) {
            Text(title)
                .foregroundStyle(Color.white)
                .padding(15)
                .frame(minWidth: 300, minHeight: height)
                .background(isEnabled ? isActivated == true ? Color.red : Color.green : .gray)
                .cornerRadius(8)
        }
        .disabled(!isEnabled)
    }
}


