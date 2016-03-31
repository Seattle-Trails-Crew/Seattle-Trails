//
//  AlertViewsController.swift
//  Seattle Trails
//
//  Created by Eric Mentele on 3/31/16.
//  Copyright © 2016 seatrails. All rights reserved.
//

import Foundation
import UIKit

class AlertViews {
    
    // MARK: Alert Views
    static func presentNotInParkAlert(sender sender: UIViewController) {
        let issueView = UIAlertController(title: "Report Issue", message: "You must be on site at a trail or park to use this feature and report an issue. Thank you for helping us document park problems for service.", preferredStyle: .Alert)
        let okButton = UIAlertAction(title: "OK", style: .Default, handler: nil)
        issueView.addAction(okButton)
        dispatch_async(dispatch_get_main_queue()) {
            sender.presentViewController(issueView, animated: true, completion: nil)
        }
    }
    
    static func presentComposeViewErrorAlert(sender sender: UIViewController) {
        let issueErrorView = UIAlertController(title: "Report Failure", message: "Your device is currently unable to send email. Please check your email settings and network connection then try again. Thank you.", preferredStyle: .Alert)
        let okButton = UIAlertAction(title: "OK", style: .Default, handler: nil)
        issueErrorView.addAction(okButton)
        dispatch_async(dispatch_get_main_queue()) {
            sender.presentViewController(issueErrorView, animated: true, completion: nil)
        }
    }
    
    // MARK: Option Alert Views
    static func presentImageSourceSelectionView (sender sender: ViewController) {
        // Present image picker options.
        let actionSheet = UIAlertController(title: "Image Source", message: nil, preferredStyle: UIAlertControllerStyle.ActionSheet)
        
        let cameraAction = UIAlertAction(title: "Camera", style: UIAlertActionStyle.Default)
        { (action) in
            dispatch_async(dispatch_get_main_queue(), {
                sender.presentIssueImagePickerWithSourceType(UIImagePickerControllerSourceType.Camera)
            })
        }
        
        let libraryAction = UIAlertAction(title: "Photo Library", style: UIAlertActionStyle.Default)
        { (action) in
            dispatch_async(dispatch_get_main_queue(), {
                sender.presentIssueImagePickerWithSourceType(UIImagePickerControllerSourceType.PhotoLibrary)
            })
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
        
        actionSheet.addAction(cameraAction)
        actionSheet.addAction(libraryAction)
        actionSheet.addAction(cancelAction)
        
        dispatch_async(dispatch_get_main_queue(), {
            sender.presentViewController(actionSheet, animated: true, completion: nil)
        })
    }
    
    static func presentIssueReportImageOptionView(sender sender: ViewController, parkName: String) {
        let fileIssueView = UIAlertController(title: "Send Issue Report", message: "Would you like to include a photo of the issue?.", preferredStyle: .Alert)
        
        let yesButton = UIAlertAction(title: "YES", style: .Default) { (yesAction) in
            sender.getImageForParkIssue()
        }
        
        let noButton = UIAlertAction(title: "NO", style: .Default) { (noAction) in
            sender.getConfiguredIssueReportForPark(parkName, imageForIssue: nil)
        }
        
        let cancelButton = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
        
        fileIssueView.addAction(yesButton)
        fileIssueView.addAction(noButton)
        fileIssueView.addAction(cancelButton)
        
        dispatch_async(dispatch_get_main_queue()) {
            sender.presentViewController(fileIssueView, animated: true, completion: nil)
        }
    }


}