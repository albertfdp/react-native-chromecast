//
//  ChromecastManager.swift
//  ReactNativeChromecast
//
//  Created by Albert Fernández on 10/10/15.
//  Copyright © 2015 Facebook. All rights reserved.
//

import Foundation

@objc(ChromecastManager)
class ChromecastManager: NSObject, GCKDeviceScannerListener, GCKDeviceManagerDelegate, GCKMediaControlChannelDelegate {
  
  var bridge : RCTBridge!
  
  private var deviceManager : GCKDeviceManager?
  private var deviceScanner : GCKDeviceScanner
  private var mediaControlChannel: GCKMediaControlChannel?
  
  private lazy var kReceiverAppID:String = {
    return kGCKMediaDefaultReceiverApplicationID
  }()
  
  private var devices : Dictionary<String, GCKDevice> = Dictionary<String, GCKDevice>()
  
  required override init() {
    let filterCriteria = GCKFilterCriteria(forAvailableApplicationWithID: kGCKMediaDefaultReceiverApplicationID)
    deviceScanner = GCKDeviceScanner(filterCriteria: filterCriteria)
  }

  @objc func startScan() -> Void {
    dispatch_async(dispatch_get_main_queue(), { [unowned self] in
      self.deviceScanner.addListener(self)
      self.deviceScanner.startScan()
    })
  }
  
  @objc func stopScan() -> Void {
    dispatch_async(dispatch_get_main_queue(), { [unowned self] in
      self.deviceScanner.stopScan()
      self.deviceScanner.removeListener(self)
    })
  }
  
  @objc func connectToDevice(deviceName: String) -> Void {
    let selectedDevice = self.devices[deviceName]
    if (selectedDevice == nil) {
      return
    }
    print("connecting to ", selectedDevice)
    dispatch_async(dispatch_get_main_queue(), { [unowned self] in
      let identifier = NSBundle.mainBundle().infoDictionary?["CFBundleIdentifier"] as! String
      self.deviceManager = GCKDeviceManager(device: selectedDevice, clientPackageName: identifier)
      self.deviceManager!.delegate = self
      self.deviceManager!.connect()
      print("connected to ", identifier)
    })
  }
  
  @objc func disconnect() -> Void {
    if (self.deviceManager == nil) {
      return
    }
    dispatch_async(dispatch_get_main_queue(), { [unowned self] in
      self.deviceManager!.leaveApplication()
      self.deviceManager!.disconnect()
    })
  }
  
  @objc func pause() -> Void {
    self.mediaControlChannel?.pause()
  }
  
  @objc func play() -> Void {
    self.mediaControlChannel?.play()
  }
  
  @objc func castVideo(videoUrl: String, title: String, description: String, imageUrl: String) {
    print("casting video", videoUrl, title, description, imageUrl)
    if (deviceManager?.connectionState != GCKConnectionState.Connected) {
      print("not connected!")
      return
    }
    
    let metadata = GCKMediaMetadata()
    metadata.setString(title, forKey: kGCKMetadataKeyTitle)
    metadata.setString(description, forKey: kGCKMetadataKeySubtitle)
    
    let url = NSURL(string: imageUrl)
    metadata.addImage(GCKImage(URL: url, width: 480, height: 360))
    
    let mediaInformation = GCKMediaInformation(contentID: videoUrl, streamType: GCKMediaStreamType.None, contentType: "video/mp4", metadata: metadata, streamDuration: 0, mediaTracks: [], textTrackStyle: nil, customData: nil)
    
    print("casting", mediaInformation)
    dispatch_async(dispatch_get_main_queue(), { [unowned self] in
      self.mediaControlChannel!.loadMedia(mediaInformation, autoplay: true)
    })
    
  }
  
  @objc func getStreamPosition(successCallback: RCTResponseSenderBlock) -> Void {
    let position = self.mediaControlChannel?.approximateStreamPosition()
    if (position != nil) {
      let positionDouble = Double(position!)
      successCallback([positionDouble])
    }
  }
  
  func deviceManagerDidConnect(deviceManager: GCKDeviceManager!) {
    print("Connected!!")
    dispatch_async(dispatch_get_main_queue(), { [unowned self] in
      self.deviceManager!.launchApplication(self.kReceiverAppID)
    })
  }
  
  func deviceManager(deviceManager: GCKDeviceManager!, didConnectToCastApplication applicationMetadata: GCKApplicationMetadata!, sessionID: String!, launchedApplication: Bool) {
    print("Application has launched!")
    self.mediaControlChannel = GCKMediaControlChannel()
    mediaControlChannel!.delegate = self
    deviceManager.addChannel(mediaControlChannel)
    mediaControlChannel!.requestStatus()
  }
  
  func deviceDidComeOnline(device: GCKDevice!) {
    print("deviceDidComeOnline")
    devices[device.friendlyName] = device;
    emitDeviceListChanged(["devices": Array(devices.keys)])
  }
  
  func deviceDidGoOffline(device: GCKDevice!) {
    print("deviceDidGoOffline")
    devices.removeValueForKey(device.friendlyName)
    emitDeviceListChanged(["devices": Array(devices.keys)])
  }
  
  private func emitDeviceListChanged(data: AnyObject) {
    self.bridge.eventDispatcher.sendDeviceEventWithName("GoogleChromecast:DeviceListChanged", body: data)
  }
  
}
