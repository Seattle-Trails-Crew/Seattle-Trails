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
    var issuePict: UIImage
    var issueLocation: CLLocation
    var trailID: String
    var formFields:[String:String?] = ["name":nil,"email":nil,"phone":nil]
    let sendTo = "issues@seattle.gov" // TODO: Get real email.
    
    var issueID: String {
        guard let phone = formFields["phone"], idNumber = phone?.substringToIndex(phone!.endIndex.advancedBy(-4)) else {
            return "Failure To Generate ID"
        }
        
        return phone! + idNumber
    }
}