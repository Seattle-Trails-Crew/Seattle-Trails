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
    class func presentErrorAlertView(sender sender: UIViewController, title: String, message: String)
    {
        let issueView = UIAlertController(title: title, message: message, preferredStyle: .Alert)
        let okButton = UIAlertAction(title: "OK", style: .Default, handler: nil)
        issueView.addAction(okButton)
        dispatch_async(dispatch_get_main_queue())
        {
            sender.presentViewController(issueView, animated: true, completion: nil)
        }
    }
    
    class func presentNotInParkAlert(sender sender: UIViewController) {
        let issueView = UIAlertController(title: "Report Issue", message: "You must be on site at a trail or park to use this feature and report an issue. Thank you for helping us document park problems for service.", preferredStyle: .Alert)
        let okButton = UIAlertAction(title: "OK", style: .Default, handler: nil)
        issueView.addAction(okButton)
        dispatch_async(dispatch_get_main_queue())
        {
            sender.presentViewController(issueView, animated: true, completion: nil)
        }
    }
	
	class func presentShareTypeAlert(sender sender: UIViewController, typeClosure:(UIImagePickerControllerSourceType)->())
	{
		let issueView = UIAlertController(title: "Take a photo?", message: "Do you want to take a photo, or share an existing one?", preferredStyle: .ActionSheet)
		
		if UIImagePickerController.isSourceTypeAvailable(.Camera)
		{
			let takeButton = UIAlertAction(title: "Take a photo", style: .Default)
			{ (action) in
				dispatch_async(dispatch_get_main_queue())
				{
					typeClosure(.Camera)
				}
			}
			issueView.addAction(takeButton)
		}
		
		let existingButton = UIAlertAction(title: "Share an existing photo", style: .Default)
		{ (action) in
			dispatch_async(dispatch_get_main_queue())
			{
				typeClosure(.PhotoLibrary)
			}
		}
		issueView.addAction(existingButton)
		
		
		let cancelButton = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
		issueView.addAction(cancelButton)
		
		dispatch_async(dispatch_get_main_queue())
		{
			sender.presentViewController(issueView, animated: true, completion: nil)
		}
	}
	
	class func presentMapKeyAlert(sender sender: UIViewController) {
		// Tell user what the different color pins mean
		let infoAlert = UIAlertController(title: "Color Key", message: "Blue Pins: Park trails that may have rought terrain. \nGreen Pins: Park trails that are easy to walk.", preferredStyle: .Alert)
		let okButton = UIAlertAction(title: "OK", style: .Default, handler: nil)
		infoAlert.addAction(okButton)
		dispatch_async(dispatch_get_main_queue())
        {
			sender.presentViewController(infoAlert, animated: true, completion: nil)
		}
	}
}