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

import Foundation

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

extension String {
    func lineBreakEvery(_ n: Int) -> String {
        var result = ""
        for i in 0..<self.count {
            if i % n == 0 && i != 0 {
                result += "\n"
            }
            result += String(self[self.index(self.startIndex, offsetBy: i)])
        }
        return result
    }
}
