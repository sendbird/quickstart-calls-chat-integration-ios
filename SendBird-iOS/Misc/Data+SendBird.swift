//
//  Data+SendBird.swift
//  SendBird-iOS
//
//  Created by Minhyuk Kim on 2020/09/21.
//  Copyright © 2020 SendBird. All rights reserved.
//

import Foundation

extension Data {
    func toHexString() -> String {
        return self.map { String(format: "%02x", $0) }.joined()
    }
}
