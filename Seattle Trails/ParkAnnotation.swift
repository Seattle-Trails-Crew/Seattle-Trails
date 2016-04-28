//
//  ParkAnnotation.swift
//  Seattle Trails
//
//  Created by Eric Mentele on 4/28/16.
//  Copyright © 2016 seatrails. All rights reserved.
//

import Foundation
import MapKit

class ParkAnnotation: MKPointAnnotation {
    var titleLabel: String
    var subtitleLabel: NSAttributedString?
    var color: UIColor?
    
    init(titleLabel: String, subtitleLabel: NSMutableAttributedString?) {
        self.titleLabel = titleLabel
        self.subtitleLabel = subtitleLabel
    }
}