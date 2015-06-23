//
//  Address.swift
//  Pods
//
//  Created by Rasmus Kildevæld   on 22/06/15.
//
//

import Foundation
import MapKit
import AddressBook

@objc public class City : NSObject, Hashable, Printable {
    dynamic public let name: String
    dynamic public let country: Country
    
    public override var hashValue : Int {
        return self.name.hashValue ^ self.country.hashValue
    }
    
    public init (_ name: String, country: Country) {
        self.name = name
        self.country = country
    }
    
    public func location(handler:LocationUpdateHandler) {
        FALocationManager.shared.manager.address(string: "\(self.name), \(self.country.name)", block: { (error, address) in
            handler(error: error, location: address?.location)
        })
    }
    
    
}

public func ==(lhs: City, rhs: City) -> Bool {
    return lhs.name == rhs.name && lhs.country == rhs.country
}

@objc public class Country : NSObject, Hashable, Printable {
    public let name: String
    public let iso: String

    public override var hashValue : Int {
        return self.iso.hashValue
    }
    
    public init (_ iso: String, name: String) {
        self.name = name
        self.iso = iso
        
        
        //super.init()
    }
    
//    public var description: String {
//        return "[Country name:\(self.name), iso:\(self.iso)]"
//    }
}

public func ==(lhs: Country, rhs: Country) -> Bool {
    return lhs.iso == rhs.iso
}

@objc public class Address : NSObject, MKAnnotation {
    public var title: String?
    
    public var coordinate: CLLocationCoordinate2D
    
    public var location: CLLocation {
        return CLLocation(latitude: self.coordinate.latitude, longitude: self.coordinate.longitude)
    }
    
    public var placemark: MKPlacemark {
        
        let dict = [
            kABPersonAddressCityKey as String:self.city.name,
            kABPersonAddressStreetKey as String: self.street!,
            kABPersonAddressZIPKey as String: self.zipCode!,
            kABPersonAddressCountryCodeKey as String: self.country.iso,
            kABPersonAddressCountryKey as String: self.country.name
            
        ]
        
        let placemark = MKPlacemark(coordinate: self.coordinate, addressDictionary: dict)
        
        return placemark
    }
    
    public let city: City
    public let country: Country
    
    public let street: String?
    public let zipCode: String?
    
    public init(city: City, street: String?, zipCode: String?, coordinate: CLLocationCoordinate2D) {
        
        self.city = city
        self.country = city.country
        self.street = street
        self.coordinate = coordinate
        self.zipCode = zipCode
        
    }
    
    public convenience init(placemark:CLPlacemark) {
        
        let country = Country(placemark.ISOcountryCode, name: placemark.country)
        let city = City(placemark.locality, country:country)
        var street = placemark.subThoroughfare != nil ? placemark.thoroughfare + " " + placemark.subThoroughfare : placemark.thoroughfare
        self.init(city:city, street: street, zipCode:placemark.postalCode, coordinate: placemark.location.coordinate)
        
    }
    
    
}



