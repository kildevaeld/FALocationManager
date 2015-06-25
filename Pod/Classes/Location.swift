//
//  Location.swift
//  Pods
//
//  Created by Rasmus Kildevæld   on 22/06/15.
//
//

import Foundation
import MapKit

func synchronized (lock: AnyObject, block: () -> Void) {
    objc_sync_enter(lock)
    block()
    objc_sync_exit(lock)
}

func synchronize<T>(lock: AnyObject, block: () -> T?) -> T? {
    let out : T?
    objc_sync_enter(lock)
    out = block()
    objc_sync_exit(lock)
    return out
}

func mainQueue (fn: () -> Void ) {
    mainQueue(true, fn)
}

func mainQueue (async: Bool, fn: () -> Void) {
    if async {
        dispatch_async(dispatch_get_main_queue(), fn)
    } else {
        dispatch_sync(dispatch_get_main_queue(), fn)
    }
}






var _private_queue = "falocation.event.queue"

class LocationManager : NSObject {
    
    struct idgen {
        private static let lock = NSLock()
        private static var _id : Int64 = 0
        static func get_id() -> Int64 {
            return ++self._id
        }
    }
    
    var queue : dispatch_queue_t = dispatch_queue_create(_private_queue, nil)
    var queue2 : dispatch_queue_t = dispatch_queue_create("private", nil)
    var listeners: [LocationListener] = []
    
    private var _location : CLLocation?
    private var _address : Address?
    
    var location: CLLocation? {
        get {
            var loc : CLLocation?
            dispatch_sync(self.queue2) { ()
                loc = self._location
            }
            return loc
        }
        set (loc) {
            dispatch_barrier_async(self.queue2) {
                self._location = loc
            }
        }
    }
    var address: Address? {
        get {
            var addr : Address?
            dispatch_sync(self.queue2) {
                addr = self._address
            }
            return addr
        }
        
        set (addr) {
            dispatch_barrier_async(self.queue2) {
                self._address = addr
            }
        }
    }
    
    private var error: NSError?
    
    private func listen(once: Bool, _ handler: ListenerType ) -> LocationListener? {
        let id = idgen.get_id()
        
        let listener = LocationListener(manager: self, id: id, type: handler, once: once)
        listener.listen()
        
        return listener
    }
    
    func listen(listener: LocationListener) -> Bool {
        
        var ret : Bool = false
        
        if !contains(self.listeners, listener) {
            self.listeners.append(listener)
            ret = true
        }
        
        let currentLocation = self.location
        let currentAddress = self.address
        let error : NSError?
        
        if currentLocation != nil {
            listener.emit(self.error, args: currentLocation)
        }
        
        if address != nil {
            listener.emit(self.error, args: address)
        }
        
        if self.error != nil {
            listener.emit(self.error, args: nil)
        }
        
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
        
        if listener == nil {
            self.listeners = []
            ret = true
        } else {
            if let index = find(self.listeners, listener!) {
                self.listeners.removeAtIndex(index)
                ret = true
            }
        }
        
        return ret
    }
}

extension LocationManager : CLLocationManagerDelegate {
    struct state {
        //static var addressListener : LocationListener?
        static var isResolvingAddress: Bool = false
        static var lastAddressResolving: NSTimeInterval = 0
        static var cache = AddressCache()
        static var queue = Queue()
    }
    
    var canLocate: Bool {
        let aCode = CLLocationManager.authorizationStatus()
        return (aCode == .AuthorizedAlways || aCode == .AuthorizedAlways ) && CLLocationManager.locationServicesEnabled()
    }
    
    
    /*func startUpdatingAddress() {
        var lastLocation : CLLocation?
        
        if state.addressListener != nil {
            return
        }
        
        state.addressListener = self.listen(false, location: { (error, location)  in
            
            
            if location == nil { return }
            if lastLocation != nil && lastLocation!.compare(location!, precision: 200.0) { return }
            
            self.address(location!, block: { (error, address) in
                dispatch_async(self.queue) {
                    lastLocation = location
                    let listeners = self.listeners
                    if address != nil {
                        self.address = address
                    }
                    
                    for listener in listeners {
                        listener.emit(error, args: address)
                    }
                }
                
            })
        })
    }
    
    func stopUpdatingAddress () {
        state.addressListener?.unlisten()
        state.addressListener = nil
    }*/
    
    func address(location: CLLocation, block: AddressUpdateHandler) {
        
        if !NSThread.currentThread().isMainThread {
            mainQueue {
                self.address(location, block: block)
            }
            return
        }
        
        if let address = state.cache.get(location) {
            block(error: nil, address: address)
            return
        }
        
        if !addressCheck() {
            block(error: nil, address: nil)
            return
        }
        
        
        
        state.isResolvingAddress = true
        state.lastAddressResolving = NSDate().timeIntervalSince1970
        
        let geocoder = CLGeocoder()
        
        geocoder.reverseGeocodeLocation(location, completionHandler: { (placemarks, error) in
            
            self.handle_geocode(placemarks, error: error, block:block)
            state.cache.save()
        })
    }
    
    func address(#string: String, block: AddressUpdateHandler) {
        
        if !NSThread.currentThread().isMainThread {
            mainQueue {
                self.address(string: string, block: block)
            }
            return
        }
        
        if let address = state.cache.get(string) {
            block(error: nil, address: address)
            return
        }
        
        if state.isResolvingAddress {
            state.queue.push(string, handler: block)
            //block(error: nil, address: nil)
            return
        } /*else if (NSDate().timeIntervalSince1970 - state.lastAddressResolving) < 10 {
            state.queue.push(string, handler: block)
        }*/
        
        state.isResolvingAddress = true
        state.lastAddressResolving = NSDate().timeIntervalSince1970
        
        let geocoder = CLGeocoder()
        
        geocoder.geocodeAddressString(string, completionHandler: { (placemarks, error) in
    
            self.handle_geocode(placemarks, error: error, block: { (error, address) in
                
                if address != nil {
                    state.cache.set(string, address:address!)
                    state.cache.save()
                }
                
                block(error: error, address: address)
                
                var handlers: [AddressUpdateHandler] = []
                
                handlers = state.queue.pop(string)
                if address != nil {
                    handlers += state.queue.pop(address!.location)
                }
                
                for handler in handlers {
                    handler(error:error, address:address)
                }
             
                if let item = state.queue.pop() {
                    if item.key != nil {
                        self.address(string: item.key!, block: item.handler)
                    } else {
                        self.address(item.location!, block: item.handler)
                    }
                }
                
            })
            
        })
    }
    
    func address(#city: City, block: AddressUpdateHandler) {
        
        self.address(string: "\(city.name), \(city.country.name)", block: block)
    }
    
    func addressCheck() -> Bool {
        
        let now = NSDate().timeIntervalSince1970
        if state.isResolvingAddress {
            println("already resolving address")
            return false
        } else if now - state.lastAddressResolving < 10 {
            println("can only get address every 20th sec \(now - state.lastAddressResolving)")
            return false
        }
        
        return true
    }
    
    private func handle_geocode (placemarks: [AnyObject]!, error: NSError?, block: AddressUpdateHandler) {
        
        state.isResolvingAddress = false
        
        
        if placemarks == nil {
            return
        }
        
        var err : NSError? = error
        var address : Address? = nil
        if placemarks.count == 0 {
            err = NSError(domain: "LocationManagerError", code: 100, userInfo: nil)
        } else {
            let placemark = placemarks.first as? CLPlacemark
            if placemark != nil {
                if placemark!.country != nil && placemark!.ISOcountryCode != nil {
                    address = Address(placemark: placemark!)
                }
            }
            
        }
        
        if address != nil {
            state.cache.set(address!)
        }
        
        block(error: err, address: address)
        
    
    }

    func locationManager(manager: CLLocationManager!, didUpdateToLocation newLocation: CLLocation!, fromLocation oldLocation: CLLocation!) {
        
        if (oldLocation != nil && oldLocation == newLocation) {
            return
        }
        
        dispatch_async(queue){
            
            self.location = newLocation
            self.error = nil
            
            let listeners = self.listeners
            
            for listener in listeners {
                listener.emit(nil, args: newLocation)
            }
        }
        
        

        
        
    }
    
    func locationManager(manager: CLLocationManager!, didFailWithError error: NSError!) {
        
        let listeners = self.listeners
        
        self.error = error
        self.location = nil
        self.address = nil
        
        for listener in listeners {
            listener.emit(error, args: nil)
        }
    }
    
}