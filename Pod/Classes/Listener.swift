//
//  Listener.swift
//  Pods
//
//  Created by Rasmus Kildevæld   on 25/06/15.
//
//

import Foundation
import MapKit

enum ListenerType {
    case Address(AddressUpdateHandler), Location(LocationUpdateHandler)
}

enum ListenerOption {
    case None, TTL(NSTimeInterval), Once
}

let TimeoutErrorCode = 500

@objc public class LocationListener : Equatable {
    let manager: LocationManager
    let id: Int64
    let type: ListenerType
    public var once: Bool = false
    public var ttl: Double = 10.0
    public var queue : dispatch_queue_t = dispatch_get_main_queue()
    private var timer: NSTimer?
    
    init (manager: LocationManager, id: Int64, type: ListenerType, once: Bool) {
        self.id = id
        self.type = type
        self.once = once
        self.manager = manager
    }
    
    public func unlisten () {
        self.timer?.invalidate()
        self.timer = nil
        self.manager.unlisten(self)
    }
    
    public func listen () {
        self.timer?.invalidate()
        self.timer = NSTimer(timeInterval: self.ttl, target: self, selector: "onLocationTimeout:", userInfo: nil, repeats: false)
        
        NSRunLoop.mainRunLoop().addTimer(self.timer!, forMode: NSRunLoopCommonModes)
        
        self.manager.listen(self)
        
        
        
    }
    
    func emit(error: NSError?, args: AnyObject?) {
        
        
        
        dispatch_async(self.queue) {
            
            self.timer?.invalidate()
            self.timer = nil
            
            switch (self.type) {
            case let .Address(handler):
                handler(error: error, address: args as? Address)
            case let .Location(handler):
                handler(error: error, location: args as? CLLocation)
            }
            
            
            if self.once {
                self.unlisten()
            }
        }
        
        
        
    }
    
    func onLocationTimeout(timer: NSTimer) {
        let error = NSError(domain: "com.softshag.location", code: TimeoutErrorCode, userInfo: nil)
        self.emit(error, args: nil)
    }
    
    deinit {
        self.unlisten()
    }
    
    
}

public func ==(lhs:LocationListener, rhs:LocationListener) -> Bool {
    return lhs.id == rhs.id
}