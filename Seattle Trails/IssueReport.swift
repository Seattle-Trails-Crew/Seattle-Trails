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
	let sendTo = "trails@seattle.gov"
	
	var formFields: String
	{
		return "Full Name:\nEmail:\nPhone:\nIssue Description:\n\n\n\nYour issue number is: \(issueID)"
	}
	
	var issueID: String
	{
		let date = Date()
		let format = DateFormatter()
		format.dateFormat = "yyyy-MM-dd-HH-mm-ss"
		return "\(pmaid)-\(format.string(from: date))"
	}
	
	var subject: String
	{
		return "Issue Report \(issueID) for \(parkName) (\(issueLocation.coordinate.latitude), \(issueLocation.coordinate.longitude))"
	}
	
	var issueImageData: Data?
	{
		return UIImageJPEGRepresentation(issueImage!, 0.7)
	}
}
