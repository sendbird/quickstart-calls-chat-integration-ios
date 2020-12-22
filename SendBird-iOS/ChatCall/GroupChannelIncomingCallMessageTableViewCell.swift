//
//  GroupChannelIncomingUserMessageTableViewCell.swift
//  SendBird-iOS
//
//  Created by Jed Gyeong on 11/6/18.
//  Copyright © 2018 SendBird. All rights reserved.
//

import UIKit
import SendBirdSDK
import SendBirdCalls

class GroupChannelIncomingCallMessageTableViewCell: GroupChannelIncomingMessageTableViewCell {
    
    @IBOutlet weak var callTypeImageView: UIImageView!
    @IBOutlet weak var textMessageLabel: UILabel!
    
    var callInfo: CallInfo? {
        didSet {
            guard let info = self.callInfo else { return }
            
                if info.isVideoCall {
                    self.callTypeImageView.image = UIImage(named: "icCallVideoFilled_Incoming")
                } else {
                    self.callTypeImageView.image = UIImage(named: "icCallFilled_Incoming")
                }

            
            if let duration = info.duration,
                let reason = info.endResult {
                switch reason {
                case .completed:
                    self.textMessageLabel.text = "\(duration.timerText())"
                case .unknown, .none:
                    self.textMessageLabel.text = "Unknown Error"
                default:
                    self.textMessageLabel.text = reason.capitalized().replacingOccurrences(of: "_", with: " ")
                }
            } else {
                self.textMessageLabel.text = "\(info.isVideoCall ? "Video" : "Voice") calling..."
            }
        }
    }
    
    override func awakeFromNib() {
        self.messageCellType = .call
        
        super.awakeFromNib()
        
        let clickMessageContainerGesture = UITapGestureRecognizer(target: self, action: #selector(clickMessage(_:)))
        self.messageContainerView.addGestureRecognizer(clickMessageContainerGesture)
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
    override func setMessage(currMessage: SBDBaseMessage, prevMessage: SBDBaseMessage?, nextMessage: SBDBaseMessage?) {
        
        guard let message = (currMessage as? SBDUserMessage) else { return }
        self.textMessageLabel.text = message.message
        
        super.setMessage(currMessage: currMessage, prevMessage: prevMessage, nextMessage: nextMessage)
    }
    
    @objc func clickMessage(_ recognizer: UITapGestureRecognizer) {
        guard let delegate = self.delegate, let callInfo = self.callInfo else { return }
        delegate.didClickCallMessage?(callInfo)
    }
}

extension Int64 {
    func timerText() -> String {
        let duration = self
        
        let convertedTime = Int(duration / 1000)
        let hour = Int(convertedTime / 3600)
        let minute = Int(convertedTime / 60) % 60
        let second = Int(convertedTime % 60)
        
        // update UI
        var timeText = [String]()
        
        if hour > 0 {
            timeText.append(String(hour))
            timeText.append(String(format: "%02d", minute))
        } else {
            timeText.append(String(format: "%02d", minute))
            timeText.append(String(format: "%02d", second))
        }
        //        if minute > 0 { timeText.append(String(format: "%02d", minute) + "m") }
        //        timeText.append(String(format: "%02d", second) + "s")
        
        return timeText.joined(separator: ":")
    }
}
