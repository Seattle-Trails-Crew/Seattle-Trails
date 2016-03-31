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
    let formFields = "Full Name:\n\n\n\nEmail Address:\n\n\n\nPhone Number:\n\n\n\nIssue Description:"
    let sendTo = "ericmentele@gmail.com" // TODO: Get real email.
    
    var subject: String
    {
        return "Issue Report (\(parkName): \(issueLocation)"
    }
    
    var issueImageData: NSData?
    {
        return UIImageJPEGRepresentation(issueImage!, 0.7)
    }
    
    var issueID: String
    {
        return parkName + String(arc4random())
    }
}