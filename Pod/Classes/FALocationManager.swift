//
//  FALocationManager.swift
//  Pods
//
//  Created by Rasmus Kildevæld   on 22/06/15.
//
//

import Foundation
import MapKit

public typealias LocationUpdateHandler = (error: NSError?, location: CLLocation?) -> Void
public typealias AddressUpdateHandler = (error: NSError?, address: Address?) -> Void


enum State {
    case None,Location,Significant
}

extension NSLock {
    func lock(fn:() -> Void) {
        self.lock()
        fn()
        self.unlock()
    }
    
    func lock<T>(fn:() -> T) -> T {
        let out : T
        self.lock()
        out = fn()
        self.unlock()
        return out
    }
}

public final class FALocationManager : NSObject {
    
    
    
    public static let shared = FALocationManager()
    
    let manager : LocationManager
    public let locationManager : CLLocationManager
    
    var state : State = .None
    var once : Bool = false
    
    public static var canLocate : Bool {
        let aCode = CLLocationManager.authorizationStatus()
        return (aCode == .AuthorizedAlways || aCode == .AuthorizedAlways || aCode == .NotDetermined ) && CLLocationManager.locationServicesEnabled()
    }
    
    public static var location: CLLocation? {
        return self.shared.manager.location
    }
    
    public static var address: Address? {
        return self.shared.manager.address
    }
    
    
    
    private override init () {
        
        self.locationManager = CLLocationManager()
        self.manager = LocationManager()
        
        
        super.init()
        
        self.manager.listen(false, location: { (error, location) -> Void in
            
            if self.once {
                FALocationManager.stop()
                self.once = false
            }
        })
        
        self.once = false
        self.locationManager.delegate = self.manager
        
    }
    
    /*public static func startUpdatingAddress () {
        self.shared.manager.startUpdatingAddress()
    }
    
    public static func stopUpdatingAddress () {
        self.shared.manager.stopUpdatingAddress()
    }*/
    
    public static func start () {
        let manager = self.shared.locationManager
        if self.shared.state == .None {
            manager.startUpdatingLocation()
        } else if self.shared.state == .Significant {
            self.startMonitoringSignificantLocationChanges()
            manager.startUpdatingLocation()
        }
        self.shared.state = .Location
    }
    
    public static func stop () {
        let manager = self.shared.locationManager
        if self.shared.state != .None {
            manager.stopUpdatingLocation()
            self.stopMonitoringSignificantLocationChanges()
            self.shared.state = .None
        }
    }
    
    public static func startMonitoringSignificantLocationChanges () {
        
    }
    
    public static func stopMonitoringSignificantLocationChanges () {
        
    }
    
    static public func address(location: CLLocation, block: AddressUpdateHandler) {
        self.shared.manager.address(location, block: block)
    }
    
    static public func address(block: AddressUpdateHandler) {
        if self.location != nil {
            self.address(self.location!, block: block)
            
        } else {
            self.location({ (error, location) -> Void in
                if location != nil {
                    self.address(location!, block: block)
                } else if error != nil {
                    block(error: error, address: nil)
                }
            })
        }
    }
    
    static public func address(#string: String, block: AddressUpdateHandler) {
        self.shared.manager.address(string: string, block: block)
    }
    
    static public func location(block: LocationUpdateHandler) {
        
        if self.shared.state == .None {
            self.shared.once = true
            self.start()
        }
        
        self.shared.manager.listen(true, location: block)
    }
    
    @objc static public func listen(block: LocationUpdateHandler) -> LocationListener {
        return self.shared.manager.listen(false, location:block)
    }

    @objc static public func listen(#address: AddressUpdateHandler) -> LocationListener {
        if self.address != nil {
            address(error:nil, address: self.address)
        }
        return self.shared.manager.listen(false, address: address)
    }
    
    deinit {
        self.manager.unlisten()
    }
}