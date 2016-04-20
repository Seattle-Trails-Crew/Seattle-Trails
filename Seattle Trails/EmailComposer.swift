//
//  EmailComposer.swift
//  Seattle Trails
//
//  Created by Eric Mentele on 4/12/16.
//  Copyright © 2016 seatrails. All rights reserved.
//

import Foundation
import MessageUI
import CoreLocation

class EmailComposer: NSObject, MFMailComposeViewControllerDelegate {
    func canSendMail() -> Bool
    {
        return MFMailComposeViewController.canSendMail()
    }
    
    /**
     Reports an issue with a park via an email populated with the following parameters.
     
     - parameter park:     A park object containing park information.
     - parameter location: The users current location.
     - parameter image:    An image of the issue to report taken from the device camera.
     */
    func reportIssue(forPark park: Park, atUserLocation location: CLLocation, withImage image: UIImage) -> MFMailComposeViewController
    {
        let issue = IssueReport(issueImage: image, issueLocation: location, parkName: park.name, pmaid: park.trails.first!.pmaid ?? 0)
        
        let emailView = MFMailComposeViewController()
        emailView.mailComposeDelegate = self
        emailView.setToRecipients([issue.sendTo])
        emailView.setSubject(issue.subject)
        emailView.setMessageBody(issue.formFields, isHTML: false)
        emailView.addAttachmentData(issue.issueImageData!, mimeType: "image/jpeg", fileName: "Issue report: \(issue.parkName)")
        
        return emailView
    }
    
    func volunteerForParks() -> MFMailComposeViewController
    {
        let volunteerEmailView = MFMailComposeViewController()
        volunteerEmailView.mailComposeDelegate = self
        volunteerEmailView.setToRecipients(["trails@seattle.gov"])
        volunteerEmailView.setSubject("Volunteering For Seattle Parks")
        volunteerEmailView.setMessageBody("Full Name:\nEmail:\nPhone:\nOne time volunteer or Trail Steward:\nPreferred Park:\n\n\n\n", isHTML: false)
        
        return volunteerEmailView
    }
    
    func mailComposeController(controller: MFMailComposeViewController, didFinishWithResult result: MFMailComposeResult, error: NSError?)
    {
        dispatch_async(dispatch_get_main_queue())
        {
            controller.dismissViewControllerAnimated(true, completion: nil)
        }
    }
}