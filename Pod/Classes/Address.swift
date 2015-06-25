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
    var _address: Address?
    
    dynamic public let name: String
    dynamic public let country: Country
    dynamic public var address: Address? {
        return _address
    }
    public override var hashValue : Int {
        return self.name.hashValue ^ self.country.hashValue
    }
    
    public init (_ name: String, country: Country) {
        self.name = name
        self.country = country
    }
    
    
    public func location(handler:LocationUpdateHandler) {
        if self._address != nil {
            handler(error: nil, location: _address!.location)
        } else {
            self.resolveAddress({ (error, address) -> Void in
                handler(error: error, location: address?.location)
            })
        }
    }
    
    public func resolveAddress(handler:AddressUpdateHandler) {
        if _address != nil {
            handler(error: nil, address: _address)
            return;
        }
        FALocationManager.shared.manager.address(city: self, block: { (error, address) in
            self._address = address
            handler(error: error, address: address)
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

@objc public class Address : NSObject, MKAnnotation, NSCoding {
    
    struct AddressCoding {
        static let City = "city", Country = "country", Iso = "isoCode", ZipCode = "zipCode", Street = "street",
        Latitude = "latitude", Longitude = "longitude"
    }
    
    public required init(coder aDecoder: NSCoder) {
        let cityName  = aDecoder.decodeObjectForKey(AddressCoding.City) as? String
        let countryName = aDecoder.decodeObjectForKey(AddressCoding.Country) as? String
        let isoCode  = aDecoder.decodeObjectForKey(AddressCoding.Iso) as? String
        let zipCode  = aDecoder.decodeObjectForKey(AddressCoding.ZipCode) as? String
        let latitude = aDecoder.decodeDoubleForKey(AddressCoding.Latitude)
        let longitude = aDecoder.decodeDoubleForKey(AddressCoding.Longitude) as Double
        let street = aDecoder.decodeObjectForKey(AddressCoding.Street) as? String
        
        let country = Country(isoCode!, name: countryName!)
        let city = City(cityName!, country: country)
        
        let location = CLLocationCoordinate2DMake(latitude, longitude)
        
        //self.init(city: city, street: street, zipCode: zipCode, coordinate: location)
        self.city = city
        self.country = country
        self.street = street
        self.zipCode = zipCode
        self.coordinate = location
        
    }
    
    public func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(self.city.name, forKey: AddressCoding.City)
        aCoder.encodeObject(self.country.name, forKey: AddressCoding.Country)
        aCoder.encodeObject(self.country.iso, forKey: AddressCoding.Iso)
        aCoder.encodeObject(self.street, forKey: AddressCoding.Street)
        aCoder.encodeObject(self.zipCode, forKey: AddressCoding.ZipCode)
        aCoder.encodeDouble(self.coordinate.latitude, forKey: AddressCoding.Latitude)
        aCoder.encodeDouble(self.coordinate.longitude, forKey: AddressCoding.Longitude)
    }

    
    
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




