//
// Copyright (Change Date see Readme), gematik GmbH
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
//
// *******
//
// For additional notes and disclaimer from gematik and in case of changes by gematik find details in the "Readme" file.
//

import SwiftUI

@main
struct push_poc_iosApp: App {
    @UIApplicationDelegateAdaptor private var appDelegate: MyAppDelegate

    var body: some Scene {
        WindowGroup {
            TabContainerView()
        }
    }
}

class MyAppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        print("didRegisterForRemoteNotificationsWithDeviceToken: \(deviceToken.hexEncodedString)")
        
        UserDefaults.standard.set(deviceToken.hexEncodedString, forKey: "deviceToken")
    }

    let notificationCenterDelegate = NotificationDelegate()
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = notificationCenterDelegate
        
        UNUserNotificationCenter.current().setNotificationCategories([
            UNNotificationCategory(identifier: "myCategory", actions: [], intentIdentifiers: [], hiddenPreviewsBodyPlaceholder: "...", options: [])
        ])
        return true
    }
}

class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound, .badge])
    }
}
