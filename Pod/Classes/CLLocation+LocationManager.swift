//
//  CLLocation+LocationManager.swift
//  Pods
//
//  Created by Rasmus Kildevæld   on 22/06/15.
//
//

import Foundation
import MapKit

extension CLLocation {
    public func compare(location: CLLocation) -> Bool {
        return self.compare(location, precision: 10.0)
    }
    
    public func compare(location: CLLocation, precision: CLLocationDistance) -> Bool {
        return self.distanceFromLocation(location) <= precision
    }
}


func ==(lhs: CLLocation, rhs: CLLocation) -> Bool {
    return lhs.compare(rhs, precision: 0.0)
}