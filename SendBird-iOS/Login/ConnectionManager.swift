//
//  ConnectionManager.swift
//  SendBird-iOS-LocalCache-Sample-swift
//
//  Created by sendbird-young on 2018. 4. 11..
//  Copyright © 2018년 SendBird. All rights reserved.
//

import Foundation
import UIKit
import SendBirdSDK
import SendBirdCalls

let ErrorDomainConnection = "com.sendbird.sample.connection"
let ErrorDomainUser = "com.sendbird.sample.user"

protocol ConnectionManagerDelegate: NSObjectProtocol {
    func didConnect(isReconnection: Bool)
    func didDisconnect()
}


class ConnectionManager: NSObject, SBDConnectionDelegate {
    typealias LoginHandler = ((_ chatUser: SBDUser?, _ callUser: User?, _ error: Error?) -> Void)
    
    var observers: NSMapTable<NSString, AnyObject> = NSMapTable(keyOptions: .copyIn, valueOptions: .weakMemory)
    
    static let sharedInstance = ConnectionManager()
    static var stopConnectionRetry: Bool = false
    
    override init() {
        super.init()
        SBDMain.add(self as SBDConnectionDelegate, identifier: self.description)
    }
    
    deinit {
        SBDMain.removeConnectionDelegate(forIdentifier: self.description)
    }
    
    static public func startLogin(){
        login { (chatUser, callUser, error) in
            if stopConnectionRetry {
                return
            }
            if error != nil {
                return self.showAlert()
            }
            let alert = UIAlertController(title: "Login Success", message: nil, preferredStyle: .actionSheet)
            alert.addAction(UIAlertAction(title: "Okay", style: .cancel, handler: nil))
            let topVC = UIApplication.shared.keyWindow?.rootViewController
            if topVC?.presentedViewController == nil {
                topVC?.present(alert, animated: true, completion: nil)
            } else {
                topVC?.presentedViewController?.present(alert, animated: true, completion: nil)
            }
            return
        }
    }
    
    static public func showAlert() {
        let alert = UIAlertController(title: "Login Failure", message: "Login Again?", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Retry", style: .default, handler: { (action) in
            self.startLogin()
        }))
        alert.addAction(UIAlertAction(title: "Retry in 5 sec", style: .default, handler: { (action) in
            DispatchQueue.main.asyncAfter(deadline: .now() + 5, execute: {
                self.startLogin()
            })
        }))
        
        let topVC = UIApplication.shared.keyWindow?.rootViewController
        if topVC?.presentedViewController == nil {
            topVC?.present(alert, animated: true, completion: nil)
        } else {
            topVC?.presentedViewController?.present(alert, animated: true, completion: nil)
        }
    }
    
    static public func login(completionHandler: LoginHandler?) {
        let userDefault = UserDefaults.standard
        
        guard let userId = userDefault.value(forKey: "sendbird_user_id") as? String,
              let userNickname = userDefault.value(forKey: "sendbird_user_nickname") as? String else {
            
            let error = NSError(domain: ErrorDomainConnection, code: -1, userInfo: [NSLocalizedDescriptionKey:"User id or user nickname is nil.",NSLocalizedFailureReasonErrorKey:"Saved user data does not exist."])
            completionHandler?(nil, nil, error)
            return
        }
        
        self.login(userId: userId, nickname: userNickname, completionHandler: completionHandler)
    }
    
    static public func login(userId: String, nickname: String, completionHandler: LoginHandler?) {
        self.sharedInstance.login(userId: userId, nickname: nickname, completionHandler: completionHandler)
    }
    
    private func login(userId: String, nickname: String, completionHandler: LoginHandler?) {
        var loginError: Error?
        var chatUser: SBDUser?
        var callUser: User?
        
        let group = DispatchGroup()
        
        group.enter()
        SendBirdCall.authenticate(with: AuthenticateParams(userId: userId)) { (user, error) in
            guard error == nil else {
                loginError = error
                group.leave()
                return
            }
            callUser = user
            
            if let pushToken = UserDefaults.standard.value(forKey: "sendbird.calls.voip_push") as? Data {
                SendBirdCall.registerVoIPPush(token: pushToken) { error in
                    print("VoIP Push Token Registered with error: \(String(describing: error))")
                    group.leave()
                }
            } else { group.leave() }
        }
        
        group.enter()
        
        DispatchQueue.main.async {
            SBDMain.connect(withUserId: userId, accessToken: nil) { (user, error) in
                let userDefault = UserDefaults.standard
                guard error == nil else {
                    loginError = error
                    group.leave()
                    return
                }
                
                chatUser = user
                
                if let pushToken = SBDMain.getPendingPushToken() {
                    SBDMain.registerDevicePushToken(pushToken, unique: true, completionHandler: { (status, error) in
                        guard let _: SBDError = error else {
                            print("APNS registration failed.")
                            return
                        }
                        
                        if status == .pending {
                            print("Push registration is pending.")
                        }
                        else {
                            print("APNS Token is registered.")
                        }
                    })
                }
                
                self.broadcastConnection(isReconnection: false)
                
                SBDMain.getDoNotDisturb { (isDoNotDisturbOn, startHour, startMin, endHour, endMin, timezone, error) in
                    UserDefaults.standard.set(startHour, forKey: "sendbird_dnd_start_hour")
                    UserDefaults.standard.set(startMin, forKey: "sendbird_dnd_start_min")
                    UserDefaults.standard.set(endHour, forKey: "sendbird_dnd_end_hour")
                    UserDefaults.standard.set(endMin, forKey: "sendbird_dnd_end_min")
                    UserDefaults.standard.set(isDoNotDisturbOn, forKey: "sendbird_dnd_on")
                    UserDefaults.standard.synchronize()
                }
                
                if nickname != SBDMain.getCurrentUser()?.nickname {
                    SBDMain.updateCurrentUserInfo(withNickname: nickname, profileUrl: nil, completionHandler: { (error) in
                        group.leave()
                    })
                } else {
                    group.leave()
                }
                
                userDefault.setValue(SBDMain.getCurrentUser()?.userId, forKey: "sendbird_user_id")
                userDefault.setValue(SBDMain.getCurrentUser()?.nickname, forKey: "sendbird_user_nickname")
                userDefault.setValue(true, forKey: "sendbird_auto_login")
            }
        }
        group.notify(queue: DispatchQueue.main) {
            guard let chatUser = chatUser, let callUser = callUser else {
                completionHandler?(nil, nil, loginError)
                return
            }
            
            completionHandler?(chatUser, callUser, nil)
        }
    }
    
    static public func logout(completionHandler: (() -> Void)?) {
        self.sharedInstance.logout(completionHandler: completionHandler)
    }
    
    private func logout(completionHandler: (() -> Void)?) {
        let group = DispatchGroup()
        
        group.enter()
        SBDMain.disconnect {
            self.broadcastDisconnection()
            
            let userDefault = UserDefaults.standard            
            userDefault.setValue(false, forKey: "sendbird_auto_login")
            userDefault.removeObject(forKey: "sendbird_dnd_start_hour")
            userDefault.removeObject(forKey: "sendbird_dnd_start_min")
            userDefault.removeObject(forKey: "sendbird_dnd_end_hour")
            userDefault.removeObject(forKey: "sendbird_dnd_end_min")
            userDefault.removeObject(forKey: "sendbird_dnd_on")
            userDefault.synchronize()
            
            UIApplication.shared.applicationIconBadgeNumber = 0
            
            group.leave()
        }
        
        group.enter()
        let deauthenticate: ((SBCError?) -> Void) = { _ in
            SendBirdCall.deauthenticate { error in
                group.leave()
            }
        }
        if let voipPushToken = UserDefaults.standard.value(forKey: "sendbird.calls.voip_push") as? Data {
            SendBirdCall.unregisterVoIPPush(token: voipPushToken, completionHandler: deauthenticate)
        } else { deauthenticate(nil) }
        
        group.notify(queue: DispatchQueue.main) {
            completionHandler?()
        }
    }
    
    static public func add(connectionObserver: ConnectionManagerDelegate) {
        self.sharedInstance.observers.setObject(connectionObserver as AnyObject, forKey:self.instanceIdentifier(instance: connectionObserver))
        if SBDMain.getConnectState() == .open {
            connectionObserver.didConnect(isReconnection: false)
        }
        else if SBDMain.getConnectState() == .closed {
            self.login(completionHandler: nil)
        }
    }
    
    static public func remove(connectionObserver: ConnectionManagerDelegate) {
        let observerIdentifier: NSString = self.instanceIdentifier(instance: connectionObserver)
        self.sharedInstance.observers.removeObject(forKey: observerIdentifier)
    }
    
    private func broadcastConnection(isReconnection: Bool) {
        let enumerator: NSEnumerator? = self.observers.objectEnumerator()
        while let observer = enumerator?.nextObject() as! ConnectionManagerDelegate? {
            observer.didConnect(isReconnection: isReconnection)
        }
    }
    
    private func broadcastDisconnection() {
        let enumerator: NSEnumerator? = self.observers.objectEnumerator()
        while let observer = enumerator?.nextObject() as! ConnectionManagerDelegate? {
            observer.didDisconnect()
        }
    }
    
    static private func instanceIdentifier(instance: Any) -> NSString {
        return NSString(format: "%zd", self.hash())
    }
    
    func didStartReconnection() {
        self.broadcastDisconnection()
    }
    
    func didSucceedReconnection() {
        self.broadcastConnection(isReconnection: true)
    }
    
    func didFailReconnection() {
        //
    }
    
    func didCancelReconnection() {
        //
    }
}
