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
import CryptoKit

// Example implementation of crypto specified by gemF_PushNotification and
// https://gematik.github.io/gem-push-notifications-concept/. It showcases the usage of the HKDF function as well as the
// usage of the AES-GCM encryption.
//
// For the sake of this example we use a static initial shared secret to check for consistency with the specification
// and reproducability in a development environment. The keys for the encryption are not persistet and must be
// regenerated on each startup of the application. A rough copy of that code is included within the push extension
// (NotificationService.swift) that is recreating those keys as well.
class ViewModel: ObservableObject {
    @Published var iss = "f2ca1bb6c7e907d06dafe4687e579fce76b37e4e93b7605022da52e6ccc26fd2"
    @Published var info = "2023-10"
    @Published var generation: [Generation] = []
    
    @Published var plaintext = "{\"eventId\": \"001\"}"
    @Published var cipher = ""
    @Published var notificationFD2Gateway = ""
    @Published var notificationGateway2FdV = ""
    @Published var decrypted = ""

    struct Generation {
        let key: String
        let secret: String
        let month: String
    }
    
    func addGeneration() {
        guard let lastGeneration = generation.first else {
            addGeneration(inputKeyMaterial: SymmetricKey(data: Data(hexEncoded: iss)), info: "2023-09")
            
            return
        }
        
        let inputKeyMaterial = SymmetricKey(data: Data(hexEncoded: lastGeneration.secret))
        let info = lastGeneration.month
        
        addGeneration(inputKeyMaterial: inputKeyMaterial, info: info)
    }
    
    func addGeneration(inputKeyMaterial: SymmetricKey, info: String) {
        // increment month
        let month = info.split(separator: "-")
        let year = Int(month[0])!
        let monthNumber = Int(month[1])!
        let nextMonth = monthNumber + 1
        let nextYear = nextMonth > 12 ? year + 1 : year
        let nextMonthNumber = nextMonth > 12 ? 1 : nextMonth
        
        // Info, fill month with leading zero
        let nextInfo = "\(nextYear)-\(String(format: "%02d", nextMonthNumber))"
        let nextInfoData = nextInfo.data(using: .utf8)! as NSData
        
        let key = HKDF<SHA256>.deriveKey(
            inputKeyMaterial: inputKeyMaterial,
            info: nextInfoData,
            outputByteCount: 64
        )
        
        let keyAsString = key.withUnsafeBytes { Data(Array($0)).hexEncodedString }
        
        let nextKey = String(keyAsString.prefix(64))
        let initialKey = String(keyAsString.suffix(64))
        
        generation.insert(
            Generation(
                key: initialKey,
                secret: nextKey,
                month: nextInfo
            ),
            at: 0
        )
    }
    
    func encrypt() {
        cipher = encryptUsingLatestKey(payload: Data(plaintext.utf8)).base64EncodedString()
        notificationFD2Gateway = """
{
    "ciphertext": "\(cipher)",
    "time_message_encrypted": "\(generation.first?.month ?? "")",
    "key_identifier": "123e4567-e89b-12d3-a456-426614174000",
    "prio": "high",
    "devices": [
        {
            "app_id": "app_id",
            "pushkey": "\(UserDefaults().string(forKey: "deviceToken") ?? "")",
            "pushkey_ts": 1634025600,
            "data": {
                "fdv_custom_key": "with_custom_value"
            }
        }
    ]    
}
"""
        notificationGateway2FdV = """
{
    "aps": {
        "alert": {
            "title":"title",
            "subtitle":"subtitle",
            "body":"body"
        },
        "mutable-content" : 1
    },
    "ciphertext":"\(cipher)",
    "time_message_encrypted":"\(generation.first?.month ?? "")",
    "key_identifier":"123e4567-e89b-12d3-a456-426614174000",
    "prio":"high"
}
"""
    }

    func decrypt() {
        let cipher = Data(base64Encoded: self.cipher)!
        
        let decryptedData = (try? decryptUsingLatestKey(cipher: cipher)) ?? "Failed".data(using: .utf8)!
        decrypted = String(data: decryptedData, encoding: .utf8)!
    }

    func encryptUsingLatestKey(payload: Data) -> Data {
        guard let latestGeneration = generation.first else {
            return Data()
        }
        let key = SymmetricKey(data: Data(hexEncoded: latestGeneration.key))
        let nonce = AES.GCM.Nonce()
        let sealedBox = try! AES.GCM.seal(payload, using: key, nonce: nonce)
        return sealedBox.combined!
    }

    func decryptUsingLatestKey(cipher: Data) throws -> Data {
        guard let latestGeneration = generation.first else {
            return Data()
        }
        let key = SymmetricKey(data: Data(hexEncoded: latestGeneration.key))
        let sealedBox = try! AES.GCM.SealedBox(combined: cipher)
        return try AES.GCM.open(sealedBox, using: key)
    }
}
