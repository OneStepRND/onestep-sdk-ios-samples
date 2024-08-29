# OneStepSDK Sample App

## Versioning

![API](https://img.shields.io/badge/API-16%2B-brightgreen.svg)
![Alpha Version](https://img.shields.io/badge/alpha-0.4.0-red.svg)

This repository contains a sample iOS application demonstrating the integration and usage of the OneStep SDK. The app showcases how to record motion data, analyze it, and display results.

## Features

- Real-time motion data recording and analysis
- Data enrichment with metadata, norms, and insights
- Calculation and display of weekly walk scores

## Getting Started

To include OneStepSDK in your iOS project, clone this repository and configure your API credentials in `OneStepSDK_SampleApp.swift`.

### Setup

```swift
let connectionResult = await OneStepSDKCore.shared.initialize(
    appId: "<YOUR-APP-ID-HERE>",
    apiKey: "<YOUR-API-KEY-HERE>",
    distinctId: "<A-UNIQUE-ID-FOR-CURRENT-USER-HERE>",
    identityVerification: nil
)
```

## Support

For support, additional information, or to report issues, contact `shahar@onestep.co`.
