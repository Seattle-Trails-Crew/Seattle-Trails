//
//  CommController.swift
//  Seattle Trails
//
//  Created by Eric Mentele on 4/4/16.
//  Copyright © 2016 seatrails. All rights reserved.
//

import Foundation
import MessageUI
import CoreLocation

class CommController: MFMailComposeViewController, MFMailComposeViewControllerDelegate, UIImagePickerControllerDelegate, GetsImageToShare {
    
    let imagePicker: UIImagePickerController = UIImagePickerController()
    var parkForIssue: Park? = nil
    var issueLocation: CLLocation? = nil
    
    
    // MARK: Delegate Methods
    func reportIssue(forPark: Park?, atUserLocation: CLLocation)
    {
        if let park = forPark {
            self.parkForIssue = park
            self.issueLocation = atUserLocation
            self.imagePicker.getPictureFor(sender: self)
        }
    }
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject])
    {
        if let pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage, let park = self.parkForIssue
        {
            dismissViewControllerAnimated(true, completion: {
                self.getConfiguredIssueReportForPark(park, imageForIssue: pickedImage)
            })
        }
        else
        {
            dismissViewControllerAnimated(true, completion: nil)
        }
    }
    
    func mailComposeController(controller: MFMailComposeViewController, didFinishWithResult result: MFMailComposeResult, error: NSError?)
    {
        controller.dismissViewControllerAnimated(true, completion: nil)
    }
    
    // MARK: Issue Reporting Methods
    func getConfiguredIssueReportForPark(parkToParse: Park, imageForIssue: UIImage?)
    {
        if let issueLocation = issueLocation
        {
            let parkIssueReport = IssueReport(issueImage: imageForIssue, issueLocation: issueLocation, parkName: parkToParse.name)
            
            self.presentIssueReportViewControllerForIssue(parkIssueReport)
        }
    }
    
    func presentIssueReportViewControllerForIssue(issue: IssueReport)
    {
        if MFMailComposeViewController.canSendMail()
        {
            let issueReportVC = MFMailComposeViewController()
            issueReportVC.mailComposeDelegate = self
            issueReportVC.setToRecipients([issue.sendTo])
            issueReportVC.setSubject(issue.subject)
            issueReportVC.setMessageBody(issue.formFields, isHTML: false)
            issueReportVC.addAttachmentData(issue.issueImageData!, mimeType: "image/jpeg", fileName: "Issue report: \(issue.parkName)")
            
            dispatch_async(dispatch_get_main_queue(), {
                self.presentViewController(issueReportVC, animated: true, completion: nil)
            })
        } else {
            dispatch_async(dispatch_get_main_queue(), {
                AlertViews.presentComposeViewErrorAlert(sender: self)
            })
        }
    }
    
}


