//
//  ParkAnnotation.swift
//  Seattle Trails
//
//  Created by Eric Mentele on 4/28/16.
//  Copyright © 2016 seatrails. All rights reserved.
//

import MapKit

class ParkAnnotation: NSObject, MKAnnotation {
    var coordinate: CLLocationCoordinate2D
    var titleLabelText: String?
    var subtitleLabelText: NSAttributedString?
    var color: UIColor?
    
    init(coordinate: CLLocationCoordinate2D) {
        self.coordinate = coordinate
    }
}