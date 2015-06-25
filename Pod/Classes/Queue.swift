//
//  Queue.swift
//  Pods
//
//  Created by Rasmus Kildevæld   on 25/06/15.
//
//

import Foundation
import MapKit

class QueueItem {
    let handler : AddressUpdateHandler
    var key : String?
    var location: CLLocation?
    
    init (key: String, handler: AddressUpdateHandler) {
        self.handler = handler
        self.key = key
    }
    
    init (location:CLLocation, handler: AddressUpdateHandler) {
        self.handler = handler
        self.location = location
    }
    
    func check(key: String) -> Bool {
        return self.key != nil && self.key == key
    }
    
    func check(location:CLLocation) -> Bool {
        return self.location != nil && self.location! == location
    }
}

class Queue {
    var stack : [QueueItem] = []
    func pop(location:CLLocation) -> [AddressUpdateHandler] {
        var out : [AddressUpdateHandler] = []
        
        for item in stack {
            if item.check(location) {
                out.append(item.handler)
            }
        }
        return out
    }
    
    func pop(key: String) -> [AddressUpdateHandler] {
        var out : [AddressUpdateHandler] = []
        
        for item in stack {
            if item.check(key) {
                out.append(item.handler)
            }
        }
        return out
    }
    
    func pop () -> QueueItem? {
        return self.stack.first
    }
    
    func push(key:String, handler: AddressUpdateHandler) {
        self.stack.append(QueueItem(key: key, handler: handler))
    }
    
    func push(location:CLLocation, handler: AddressUpdateHandler) {
        self.stack.append(QueueItem(location: location, handler: handler))
    }
    
    
}