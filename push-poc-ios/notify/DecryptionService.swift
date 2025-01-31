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

import CryptoKit
import Foundation

class DecryptionService {
    var iss = "f2ca1bb6c7e907d06dafe4687e579fce76b37e4e93b7605022da52e6ccc26fd2"
    var info = "2023-10"
    var generation: [Generation] = []

    struct Generation {
        let key: String
        let secret: String
        let month: String
    }
    
    func addGeneration() {
        guard let lastGeneration = generation.first else {
            // [AFO:gemF_Notification:A_27176] static info "2023-09" for the sake of demonstration
            addGeneration(inputKeyMaterial: SymmetricKey(data: Data(hexEncoded: iss)), timeGeneration: "2023-09")

            return
        }
        
        let inputKeyMaterial = SymmetricKey(data: Data(hexEncoded: lastGeneration.secret))
        let info = lastGeneration.month

        addGeneration(inputKeyMaterial: inputKeyMaterial, timeGeneration: info)
    }
    
    func addGeneration(inputKeyMaterial: SymmetricKey, timeGeneration: String) {
        // increment month
        let month = timeGeneration.split(separator: "-")
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

    func decryptUsingLatestKey(cipher: Data, timeMessageEncrypted: String) throws -> Data {
        if self.generation.isEmpty {
            self.addGeneration() // 2023-10
        }
        // bailout for missconfigured notification payload
        var maxGenerations = 100

        while generation.first?.month != timeMessageEncrypted && maxGenerations > 0 {
            addGeneration()
            maxGenerations -= 1
        }
        guard maxGenerations > 0 else {
            throw DecryptionError.tooManyGenerations
        }

        let latestGeneration = generation.first!
        let key = SymmetricKey(data: Data(hexEncoded: latestGeneration.key))
        let sealedBox = try AES.GCM.SealedBox(combined: cipher)
        return try AES.GCM.open(sealedBox, using: key)
    }
    
    enum DecryptionError: Error {
        case tooManyGenerations
    }
}

extension Data {
    init(hexEncoded string: String) {
        self.init(Array<UInt8>(hexEncoded: string))
    }
    
    var hexEncodedString: String {
        return map { String(format: "%02x", $0) }.joined()
    }
}

extension Array where Element == UInt8 {
    init(hexEncoded string: String) {
        self.init()
        var startIndex = string.startIndex
        while startIndex < string.endIndex {
            let endIndex = string.index(startIndex, offsetBy: 2)
            let hex = string[startIndex..<endIndex]
            self.append(UInt8(hex, radix: 16)!)
            startIndex = endIndex
        }
    }
}
