//
//  ActivityIndicator.swift
//  OneStepSDK_SampleApp
//
//  Created by David Havkin on 06/08/2024.
//

import UIKit
import SwiftUI

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
