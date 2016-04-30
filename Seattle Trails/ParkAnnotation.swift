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
    var titleLabelText: String
    var subtitleLabelText: NSAttributedString?
    var color: UIColor?
    
    init(titleLabelText: String, subtitleLabelText: NSMutableAttributedString?) {
        self.titleLabelText = titleLabelText
        self.subtitleLabelText = subtitleLabelText
    }
}