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
    // Issue Reporting Methods
    /**
     Reports an issue with a park via an email populated with the following parameters.
     
     - parameter park:     A park object containing park information.
     - parameter location: The users current location.
     - parameter image:    An image of the issue to report taken from the device camera.
     */
    func reportIssue(forPark park: Park, atUserLocation location: CLLocation, withImage image: UIImage)
    {
        let parkIssueReport = IssueReport(issueImage: image, issueLocation: location, parkName: park.name)
        
        self.presentIssueReportViewControllerForIssue(parkIssueReport)
    }
    
    func presentIssueReportViewControllerForIssue(issue: IssueReport)
    {
        if MFMailComposeViewController.canSendMail()
        {
            let emailView = MFMailComposeViewController()
            emailView.mailComposeDelegate = self
            emailView.setToRecipients([issue.sendTo])
            emailView.setSubject(issue.subject)
            emailView.setMessageBody(issue.formFields, isHTML: false)
            emailView.addAttachmentData(issue.issueImageData!, mimeType: "image/jpeg", fileName: "Issue report: \(issue.parkName)")
            
            dispatch_async(dispatch_get_main_queue(), {
                self.presentViewController(emailView, animated: true, completion: nil)
            })
        } else {
            dispatch_async(dispatch_get_main_queue(), {
                AlertViews.presentErrorAlertView(sender: self, title: "Failure", message: "Your device is currently unable to send email. Please check your email settings and network connection then try again. Thank you for helping us improve our parks.")
            })
        }
    }
    
    func mailComposeController(controller: MFMailComposeViewController, didFinishWithResult result: MFMailComposeResult, error: NSError?)
    {
        dispatch_async(dispatch_get_main_queue())
        {
            controller.dismissViewControllerAnimated(true, completion: nil)
        }
    }
}