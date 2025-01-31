# Push POC iOS

This project demonstrates a proof of concept for implementing push notifications in an iOS application.

## Table of Contents

- [Push POC iOS](#push-poc-ios)
  - [Table of Contents](#table-of-contents)
  - [Introduction](#introduction)
  - [Features](#features)
  - [Requirements](#requirements)
  - [Installation](#installation)
  - [Usage](#usage)
  - [License](#license)

## Introduction

This project is a simple iOS application that showcases how to integrate push notifications using Apple's Push Notification service (APNS) in combination with the gemF_Notification specification and the corresponding concept of this files parent directory.

## Features

- Registering for push notifications
- Creating an `iss`, a corresponding secret and following generations of that key.
- Encryption of a demo payload with corresponding example payloads to send to be send from the Fachdienst to the Push Gatway and from the Push Gateway to the FdV.

## Requirements

- Xcode 16.0 or later
- iOS 18.0 or later
- An Apple Developer account

## Installation

1. Clone the repository:
    ```sh
    git clone https://github.com/gematik/gem-push-notifications-concept.git
    ```
2. Open the project in Xcode:
    ```sh
    cd push-poc-ios
    open push-poc-ios.xcodeproj
    ```

3. Configure your project bundle identifier within `base.xcconfig` (create a bundle identifier within apple developer center with push notification entitlement).

## Usage

1. Build and run the application on a physical iOS device or the Simulator.
2. Within the first tab of the application use the "Setup Push" button
3. Allow the app to receive push notifications when prompted.
4. Copy the push token and save it for later
5. Within the second tab, create an initial encryption key and as many generations as you like.
6. Within the third tab, adjust the payload to your needs and hit "Encrypt".
7. Copy the value of "Payload example `Push Gateway -> FdV`" by hitting "copy to clipboard" below it.
8. Send a test push notification e.g. by using apples icloud developer tools https://icloud.developer.apple.com/dashboard/notifications/teams/<YOUR_TEAM_ID>/app/<YOUR_BUNDLE_IDENTIFIER>/notifications .

Example:

https://gematik.github.io/gem-push-notifications-concept/push_poc.mp4

## License

This project is licensed under the Apache License. See the [LICENSE](../LICENSE) file for details.
