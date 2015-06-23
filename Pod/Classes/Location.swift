//
//  Location.swift
//  Pods
//
//  Created by Rasmus Kildevæld   on 22/06/15.
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


public class LocationListener : Equatable {
    var manager: LocationManager?
    let id: Int64
    let type: ListenerType
    var once: Bool = false
    
    init (id: Int64, type: ListenerType, once: Bool) {
        self.id = id
        self.type = type
        self.once = once
    }
    
    public func unlisten () {
        self.manager?.unlisten(self)
    }
    
    public func listen () {
       self.manager?.listen(self)
    }
    
    deinit {
        self.unlisten()
    }
}

public func ==(lhs:LocationListener, rhs:LocationListener) -> Bool {
    return lhs.id == rhs.id
}


class LocationManager : NSObject {
    
    struct idgen {
        private static let lock = NSLock()
        private static var _id : Int64 = 0
        static func get_id() -> Int64 {
            let id : Int64
            self.lock.lock()
            id = ++_id
            self.lock.unlock()
            return id
        }
    }
    
    
    var lock : NSLock = NSLock()
    var listeners: [LocationListener] = []
    
    
    private func listen(once: Bool, _ handler: ListenerType ) -> LocationListener? {
        let id = idgen.get_id()
        
        let listener = LocationListener(id: id, type: handler, once: once)
        self.listen(listener)
        
        return listener
    }
    
    func listen(listener: LocationListener) -> Bool {
        
        var ret : Bool = false
        
        if listener.manager != nil && listener.manager! !== self {
            listener.unlisten()
        }
        
        listener.manager = self
        
        self.lock.lock()
        if !contains(self.listeners, listener) {
            self.listeners.append(listener)
            ret = true
        }
        self.lock.unlock()
        
        return ret
    }
    
    func listen(once: Bool, location: LocationUpdateHandler) -> LocationListener {
        return self.listen(once, .Location(location))!
    }

    func listen(once: Bool, address: AddressUpdateHandler) -> LocationListener {
        return self.listen(once, .Address(address))!
    }
    
    func unlisten(_ listener: LocationListener? = nil) -> Bool {
        
        var ret: Bool = false
        self.lock.lock()
        
        if listener == nil {
            self.listeners = []
            ret = true
        } else {
            if let index = find(self.listeners, listener!) {
                self.listeners.removeAtIndex(index)
                ret = true
            }
        }
        
        self.lock.unlock()
        return ret
    }
}

extension LocationManager : CLLocationManagerDelegate {
    struct state {
        static var addressListener : LocationListener?
    }
    
    
    
    var canLocate: Bool {
        let aCode = CLLocationManager.authorizationStatus()
        return (aCode == .AuthorizedAlways || aCode == .AuthorizedAlways ) && CLLocationManager.locationServicesEnabled()
    }
    
    
    func startUpdatingAddress() {
        var lastLocation : CLLocation?
        
        if state.addressListener != nil {
            return
        }
        
        state.addressListener = self.listen(false, location: { (error, location)  in
            
            if location == nil { return }
            if lastLocation != nil && lastLocation!.compare(location!, precision: 200.0) { return }
            
            self.address(location!, block: { (error, address) in
                lastLocation = location
                let listeners = self.listeners
                
                for listener in listeners {
                    switch (listener.type) {
                    case let .Address(handler):
                        handler(error: error, address: address)
                    default:
                        continue
                    }
                    if listener.once {
                        self.unlisten(listener)
                    }
                }
            })
        })
    }
    
    func stopUpdatingAddress () {
        state.addressListener?.unlisten()
        state.addressListener = nil
    }
    
    func address(location: CLLocation, block: AddressUpdateHandler) {
        let geocoder = CLGeocoder()
        
        geocoder.reverseGeocodeLocation(location, completionHandler: { (placemarks, error) in
            self.handle_geocode(placemarks, error: error, block: block)
        })
    }
    
    func address(#string: String, block: AddressUpdateHandler) {
        let geocoder = CLGeocoder()
        
        geocoder.geocodeAddressString(string, completionHandler: { (placemarks, error) in
            self.handle_geocode(placemarks, error: error, block: block)
        })
        
    }
    
    private func handle_geocode (placemarks: [AnyObject]!, error: NSError?, block: AddressUpdateHandler) {
        var err : NSError? = error
        var address : Address? = nil
        if placemarks.count == 0 {
            err = NSError(domain: "LocationManagerError", code: 100, userInfo: nil)
        } else {
            let placemark = placemarks.first as? CLPlacemark
            if placemark != nil {
                address = Address(placemark: placemark!)
            }
            
            
        }
        block(error: err, address: address)
    }

    func locationManager(manager: CLLocationManager!, didUpdateToLocation newLocation: CLLocation!, fromLocation oldLocation: CLLocation!) {
        
        if (oldLocation != nil && oldLocation == newLocation) {
            return
        }
        
        let listeners = self.listeners
        
        for listener in listeners {
            switch (listener.type) {
            case let .Location(handler):
                handler(error: nil, location: newLocation)
            default:
                continue
            }
            
            if listener.once {
                let i = find(self.listeners, listener)
                self.unlisten(listener)
            }
            
        }
        

        
        
    }
    
    func locationManager(manager: CLLocationManager!, didFailWithError error: NSError!) {
        
        let listeners = self.listeners
        
        for listener in listeners {
            switch (listener.type) {
            case let .Location(handler):
                handler(error: error, location: nil)
            default:
                continue
            }
            
            if listener.once {
                let i = find(self.listeners, listener)
                self.unlisten(listener)
            }
            
        }
    }
    
}