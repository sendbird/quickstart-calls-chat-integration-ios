//
//  File.swift
//  SendBird-iOS
//
//  Created by Jed Gyeong on 10/22/18.
//  Copyright © 2018 SendBird. All rights reserved.
//

import Foundation

extension String {
    func pathExtension() -> String {
        return (self as NSString).pathExtension
    }
    
    func convertToDictionary() -> [String: Any]? {
        if let data = self.data(using: .utf8) {
            do {
                return try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
            } catch {
                print(error.localizedDescription)
            }
        }
        return nil
    }
}
