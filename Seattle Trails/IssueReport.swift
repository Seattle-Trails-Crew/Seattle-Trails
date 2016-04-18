//
//  IssueReport.swift
//  Seattle Trails
//
//  Created by Eric Mentele on 3/29/16.
//  Copyright © 2016 seatrails. All rights reserved.
//

import Foundation
import MapKit

struct IssueReport {
    var issueImage: UIImage?
    var issueLocation: CLLocation
    var parkName: String
    var pmaid: String
    let formFields = "Full Name:\n\n\n\nEmail:\n\n\n\nPhone:\n\n\n\nIssue Description:"
    let sendTo = "trails@seattle.gov"
    
    var subject: String
    {
        return "Issue Report (\(parkName): \(issueLocation.description)"
    }
    
    var issueImageData: NSData?
    {
        return UIImageJPEGRepresentation(issueImage!, 0.7)
    }
    
    var issueID: String
    {
        return pmaid + NSDate
    }
}