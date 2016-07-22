//
//  MultiplayerServiceManager.swift
//  BlueBreak
//
//  Created by Student on 7/20/16.
//  Copyright © 2016 Student. All rights reserved.
//

import UIKit
import MultipeerConnectivity

protocol MultiplayerServiceDelegate {
    //func foundPeer()
    
    //func lostPeer()
    
    //func invitationWasReceived(fromPeer: String)
    
    //func connectedWithPeer(peerID: MCPeerID)
    
    func receiveBall(xPos: CGFloat, xV: CGFloat, yV: CGFloat)
}

class MultiplayerServiceManager: NSObject {
    private let ServiceType = "bluebreak-svc"
    
    private let myPeerId = MCPeerID(displayName: UIDevice.currentDevice().name)
    let serviceAdvertiser : MCNearbyServiceAdvertiser
    
    let serviceBrowser : MCNearbyServiceBrowser
    
    var delegate : MultiplayerServiceDelegate?
    
    override init() {
        self.serviceAdvertiser = MCNearbyServiceAdvertiser(peer: myPeerId, discoveryInfo: nil, serviceType: ServiceType)
        self.serviceBrowser = MCNearbyServiceBrowser(peer: myPeerId, serviceType: ServiceType)
        
        super.init()
        
        self.serviceAdvertiser.delegate = self
        self.serviceBrowser.delegate = self
        
        self.serviceAdvertiser.startAdvertisingPeer()
        self.serviceBrowser.startBrowsingForPeers()
        
    }
    
    deinit {
        self.serviceAdvertiser.stopAdvertisingPeer()
    }
    
    lazy var session : MCSession = {
        let session = MCSession(peer: self.myPeerId, securityIdentity: nil, encryptionPreference: MCEncryptionPreference.Required)
        session.delegate = self
        return session
    }()
    
    func sendBallDataToPeers(xPos: CGFloat, xV: CGFloat, yV: CGFloat) {
        let stringData = "\(xPos) \(xV) \(yV)".dataUsingEncoding(NSUTF8StringEncoding)
        
        do {
            try self.session.sendData(stringData!, toPeers: self.session.connectedPeers, withMode: MCSessionSendDataMode.Reliable)
        }
        catch {
            NSLog("ERROR SENDING DATA")
        }
    }
}

extension MultiplayerServiceManager: MCNearbyServiceAdvertiserDelegate {
    
    func advertiser(advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: NSError) {
        NSLog("%@", "didNotStartAdvertisingPeer: \(error)")
    }
    
    func advertiser(advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: NSData?, invitationHandler: (Bool, MCSession) -> Void) {
        NSLog("%@", "didReceiveInvitationFromPeer \(peerID)")

        invitationHandler(true, self.session)
    }
}

extension MultiplayerServiceManager: MCNearbyServiceBrowserDelegate {
    func browser(browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: NSError) {
        NSLog("%@", "didNotStartBrowsingForPeers: \(error)")
    }
    
    func browser(browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        NSLog("%@", "foundPeer: \(peerID)")
        
        NSLog("%@", "invitePeer: \(peerID)")
        
        browser.invitePeer(peerID, toSession: self.session, withContext: nil, timeout: 10)
    }
    
    func browser(browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        NSLog("%@", "lostPeer: \(peerID)")
    }
}

extension MCSessionState {
    func stringValue() -> String {
        switch(self) {
        case .NotConnected: return "NotConnected"
        case .Connecting: return "Connecting"
        case .Connected: return "Connected"
        }
    }
}

extension MultiplayerServiceManager : MCSessionDelegate {
    
    func session(session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, atURL localURL: NSURL, withError error: NSError?) {
        /*let documentsPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]
         let photoDestinationURL = NSURL.fileURLWithPath(documentsPath + "/photo.jpg")
         //        let videoDestinationURL = NSURL.fileURLWithPath(documentsPath + "/movie.mov")
         
         do {
         let fileHandle : NSFileHandle = try NSFileHandle(forReadingFromURL: localURL)
         let data : NSData = fileHandle.readDataToEndOfFile()
         let image = UIImage(data: data)
         UIImageWriteToSavedPhotosAlbum(image!, nil, nil, nil)
         self.delegate?.didFinishReceivingData(self, url: photoDestinationURL)
         }
         catch {
         print("PROBLEM IN CameraServiceManager extension > didFinishReceivingResourceWithName")
         }*/
    }
    
    func session(session: MCSession, didReceiveData data: NSData, fromPeer peerID: MCPeerID) {
        let received = NSString(data: data, encoding: NSUTF8StringEncoding) as! String
        
        let values: [String] = received.characters.split{$0 == " "}.map(String.init)
        var convertedValues: [CGFloat] = [CGFloat]()
        
        print(values)
        
        for value in values {
            convertedValues.append(CGFloat((value as NSString).doubleValue))
        }
        
        self.delegate?.receiveBall(convertedValues[0], xV: convertedValues[1], yV: convertedValues[2])
        
        /*NSLog("%@", "didReceiveData: \(data)")
         let dataString = NSString(data: data, encoding: NSUTF8StringEncoding)
         
         // CHECK DATA STRING AND ACT ACCORDINGLY
         if (dataString == "toggleFlash") {
         self.delegate?.toggleFlash(self)
         } else {
         // CREATE VARIABLE REPRESENTING WHETHER OR NOT TO SEND PHOTO BACK TO CONTROLLER
         if (dataString == "true" || dataString  == "false") {
         let sendPhoto : Bool?
         if (dataString == "true") {
         sendPhoto = true
         } else {
         sendPhoto = false
         }
         
         self.delegate?.shutterButtonTapped(self, sendPhoto!)
         }
         }*/
    }
    
    func session(session: MCSession, didReceiveStream stream: NSInputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
    }
    
    func session(session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, withProgress progress: NSProgress) {
        //self.delegate?.didStartReceivingData(self, withName: resourceName,  withProgress: progress)
    }
    
    func session(session: MCSession, peer peerID: MCPeerID, didChangeState state: MCSessionState) {
        NSLog("%@", "peer \(peerID) didChangeState: \(state.stringValue())")
        //self.delegate!.connectedDevicesChanged(self, state: state, connectedDevices:
        //session.connectedPeers.map({$0.displayName}))
    }
}


