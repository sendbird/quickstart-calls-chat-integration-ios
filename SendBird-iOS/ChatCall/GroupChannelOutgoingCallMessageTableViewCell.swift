//
//  GroupChannelOutgoingUserMessageTableViewCell.swift
//  SendBird-iOS
//
//  Created by Jed Gyeong on 11/6/18.
//  Copyright © 2018 SendBird. All rights reserved.
//

import UIKit
import SendBirdSDK
import SendBirdCalls

class GroupChannelOutgoingCallMessageTableViewCell: GroupChannelOutgoingMessageTableViewCell {
    
    @IBOutlet weak var textMessageLabel: UILabel!
    @IBOutlet weak var callTypeImageView: UIImageView!
    
    var callInfo: CallInfo? {
        didSet {
            guard let info = self.callInfo else { return }
            
            if info.isVideoCall {
                self.callTypeImageView.image = UIImage(named: "icCallVideoFilled")
            } else {
                self.callTypeImageView.image = UIImage(named: "icCallFilled")
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
        super.awakeFromNib()
        self.messageCellType = .call
        
        let clickMessageContainerGesture = UITapGestureRecognizer(target: self, action: #selector(clickUserMessage(_:)))
        self.messageContainerView.addGestureRecognizer(clickMessageContainerGesture)
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }
    
    override func setMessage(currMessage: SBDBaseMessage, prevMessage: SBDBaseMessage?, nextMessage: SBDBaseMessage?, failed: Bool?) {
        self.textMessageLabel.text = (currMessage as? SBDUserMessage)?.message
        super.setMessage(currMessage: currMessage, prevMessage: prevMessage, nextMessage: nextMessage, failed: failed)
    }
    
    
    @objc func clickUserMessage(_ recognizer: UITapGestureRecognizer) {
        guard let delegate = self.delegate, let callInfo = self.callInfo else { return }
        delegate.didClickCallMessage?(callInfo)
    }
}
