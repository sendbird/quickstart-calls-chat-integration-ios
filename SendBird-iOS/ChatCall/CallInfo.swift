//
//  CallInfo.swift
//  SendBird-iOS
//
//  Created by Minhyuk Kim on 2020/12/21.
//  Copyright © 2020 SendBird. All rights reserved.
//

import Foundation
import SendBirdCalls

@objc
class CallInfo: NSObject, Decodable {
    let callId: String
    let callType: String
    
    let isVideoCall: Bool
    
    let duration: Int64?
    let endResult: DirectCallEndResult?
    
    init?(from dictionary: [String: Any]) {
        guard let callId = dictionary["call_id"] as? String else { return nil }
        guard let callType = dictionary["call_type"] as? String else { return nil }
        guard let isVideoCall = dictionary["is_video_call"] as? Bool else { return nil }
        
        self.callId = callId
        self.callType = callType
        self.isVideoCall = isVideoCall
        
        self.duration = dictionary["duration"] as? Int64
        if let endResult = dictionary["end_result"] as? String {
            self.endResult = DirectCallEndResult(rawValue: endResult)
        } else { self.endResult = nil }
    }
    
    enum CodingKeys: String, CodingKey {
        case callId = "call_id"
        case callType = "call_type"
        case isVideoCall = "is_video_call"
        case duration
        case endResult = "end_result"
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.callId = try container.decode(String.self, forKey: .callId)
        self.callType = try container.decode(String.self, forKey: .callType)
        
        self.isVideoCall = try container.decode(Bool.self, forKey: .isVideoCall)

        self.duration = try? container.decode(Int64.self, forKey: .duration)
        self.endResult = try? container.decode(DirectCallEndResult.self, forKey: .endResult)
    }
}

extension DirectCallEndResult {
    func capitalized() -> String {
        let string = self.rawValue
        return string.prefix(1).capitalized + string.dropFirst()
    }
}
