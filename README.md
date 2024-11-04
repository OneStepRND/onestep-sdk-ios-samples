# OneStepSDK Sample Apps

This repository contains sample iOS applications demonstrating how to integrate and use the OneStep SDK for motion analysis. The apps showcase how to record motion data, analyze it, and display the results within your own application.

## Features

- Real-time motion recording and analysis
- Data enrichment with metadata, norms, and insights
- Background monitoring
- Customizable UI components (UIKit)

## Getting Started

The OneStep SDK is currently available exclusively to our customers. We provide API keys and technical documentation through our developer portals. If you're a OneStep customer, please reach out to your account representative or access your developer portal for the necessary resources and detailed instructions.

Clone this repository and configure your API credentials in `OneStepSDK_SampleApp.swift`.

```swift
let connectionResult = await OneStepSDKCore.shared.initialize(
    appId: "<YOUR-APP-ID-HERE>",
    apiKey: "<YOUR-API-KEY-HERE>",
    distinctId: "<A-UNIQUE-ID-FOR-CURRENT-USER-HERE>",
    identityVerification: nil
)
```

## Support

For support, additional information, or to report issues, contact `support@onestep.co`.
