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

import UserNotifications

struct Message: Codable {
    let eventId: String
}

class NotificationService: UNNotificationServiceExtension {

    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?

    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        self.contentHandler = contentHandler
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)
        
        let payload = request.content.userInfo
        guard let timeMessageEncrypted = payload["time_message_encrypted"] as? String,
              let ciphertextBase64 = payload["ciphertext"] as? String,
              let ciphertext = Data(base64Encoded: ciphertextBase64) else {
            let content = UNMutableNotificationContent()
            content.title = "Neue Nachricht"
            content.body = "Beim Laden der Nachricht ist ein Fehler aufgetreten, bitte öffen Sie die App."
            contentHandler(content)
            return
        }

        let decryptionService = DecryptionService()

        do {
            let decrypted = try decryptionService.decryptUsingLatestKey(
                cipher: ciphertext,
                timeMessageEncrypted: timeMessageEncrypted
            )
            let message = try JSONDecoder().decode(Message.self, from: decrypted)

            let content = UNMutableNotificationContent()
            content.title = "Neue Nachricht"
            content.body = "EventId: '\(message.eventId)'"
            content.categoryIdentifier = "myCategory"
            contentHandler(content)
        } catch {
            let content = UNMutableNotificationContent()
            content.title = "Neue Nachricht"
            content.body = "Beim Laden der Nachricht ist ein Fehler aufgetreten, bitte öffen Sie die App."
            contentHandler(content)
            return
        }
    }
    
    override func serviceExtensionTimeWillExpire() {
        // Called just before the extension will be terminated by the system.
        // Use this as an opportunity to deliver your "best attempt" at modified content, otherwise the original push payload will be used.
        if let contentHandler = contentHandler, let bestAttemptContent =  bestAttemptContent {
            contentHandler(bestAttemptContent)
        }
    }

}
