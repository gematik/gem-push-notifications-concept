// Copyright 2025 Gematik GmbH
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import SwiftUI

struct SetupView: View {
    @AppStorage("deviceToken") private var deviceToken = ""

    var body: some View {
        NavigationStack {
            Form {
                Button("Setup Push") {
                    // Request notification authorization
                    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
                        if granted {
                            print("Notification authorization granted")
                            DispatchQueue.main.async {
                                // The scene delegate will store the APNS Token within the UserSettings
                                // "deviceToken" key.
                                UIApplication.shared.registerForRemoteNotifications()
                            }
                            // You can now schedule and send notifications
                        } else {
                            print("Notification authorization denied")
                            // Handle the case where the user denied notification permissions
                        }
                    }
                }
                
                if deviceToken != "" {
                    Section("APNS Push Token") {
                        HStack {
                            Text(deviceToken.lineBreakEvery(32))
                                .font(.footnote.monospaced())
                                .multilineTextAlignment(.trailing)
                            
                            Button {
                                // copy ciphertext to clipboard
                                UIPasteboard.general.string = deviceToken
                            } label: {
                                Image(systemName: "doc.on.doc")
                            }
                        }
                    }
                }
            }
            .navigationTitle("Push Setup")
        }
    }
}
