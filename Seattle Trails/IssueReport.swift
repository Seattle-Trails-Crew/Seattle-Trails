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
    var pmaid: Int
    let formFields = "Full Name:\nEmail:\nPhone:\nIssue Description:\n\n\n\n"
    let sendTo = "trails@seattle.gov"
    
    var issueID: String
    {
        let date = NSDate()
        let format = NSDateFormatter()
        format.dateStyle = .ShortStyle
        format.timeStyle = .FullStyle
        let current = format.stringFromDate(date)
        return "\(pmaid)" + current
    }
    
    var subject: String
    {
        return "Issue Report (\(parkName): \(issueLocation.coordinate) \(issueLocation.timestamp) \(pmaid)"
    }
    
    var issueImageData: NSData?
    {
        return UIImageJPEGRepresentation(issueImage!, 0.7)
    }
    
    
}