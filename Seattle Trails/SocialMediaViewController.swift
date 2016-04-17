//
//  SocialMediaViewController.swift
//  Seattle Trails
//
//  Created by Theodore Abshire on 3/28/16.
//  Copyright © 2016 seatrails. All rights reserved.
//

import UIKit
import Social

class SocialMediaViewController: UIViewController, PopoverViewDelegate, ParksDataSource, UIPopoverPresentationControllerDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate, GetsImageToShare,  UIGestureRecognizerDelegate {
	
	//MARK: outlets
	@IBOutlet weak var imageBacker: UIView!
	@IBOutlet weak var imageView: UIImageView!
	@IBOutlet weak var trailButton: UIButton!
	@IBOutlet weak var shareButton: UIButton!
	
	//MARK: data to be set by view controller during transition
	var parks = [String:Park]()
	var atPark:String?
	let imagePicker: UIImagePickerController = UIImagePickerController()

    override func viewDidLoad()
	{
        super.viewDidLoad()

        imageBacker.layer.cornerRadius = 10
		trailButton.setTitle(atPark ?? "PICK A PARK", forState: .Normal)
		self.setButtonHiddenness()
        self.imagePicker.delegate = self
    }
	
//	override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
//		if let popoverViewController = segue.destinationViewController as? PopoverViewController
//		{
//			popoverViewController.popoverPresentationController?.delegate = self
//			popoverViewController.parksDataSource = self
//			popoverViewController.delegate = self
//		}
//	}
	
	func setButtonHiddenness()
	{
		//this determines if the social media buttons should be hidden or not
		shareButton.hidden = (atPark == nil || imageView.image == nil) //TODO: if we add a default image image to the imageview, the image != nil check should be changed
	}
	
	
	@IBAction func pressShare()
	{
		let actionSheet = UIAlertController(title: "Share your photo", message: "What platform do you want to share on?", preferredStyle: .ActionSheet)
		
		let tweet = UIAlertAction(title: "Twitter", style: .Default)
		{ (action) in
			self.finishSocial(SLServiceTypeTwitter, serviceName: "Twitter")
		}
		actionSheet.addAction(tweet)
		
		let book = UIAlertAction(title: "Facebook", style: .Default)
		{ (action) in
			self.finishSocial(SLServiceTypeFacebook, serviceName: "Facebook")
		}
		actionSheet.addAction(book)
		
		let nevermind = UIAlertAction(title: "Cancel", style: .Cancel)
		{ (action) in
		}
		actionSheet.addAction(nevermind)
		
        dispatch_async(dispatch_get_main_queue())
        {
            self.presentViewController(actionSheet, animated: true, completion: nil)
        }
    }
	
	func finishSocial(serviceType:String, serviceName:String)
	{
		if (SLComposeViewController.isAvailableForServiceType(serviceType))
		{
			let composer = SLComposeViewController(forServiceType: serviceType)
//			composer.setInitialText("#Seatrails Photo of \(atPark!). ")
			composer.setInitialText("#TESTHASHTAG Photo of \(atPark!). ")
			composer.addImage(imageView.image)
			
            dispatch_async(dispatch_get_main_queue(), { 
                self.presentViewController(composer, animated: true, completion: nil)
            })
		}
		else
		{
            dispatch_async(dispatch_get_main_queue(), { 
                AlertViews.presentErrorAlertView(sender: self, title: "Log in", message: "You must log in to \(serviceName) first! Go to settings and log in.")
            })
		}
	}
	
	
	@IBAction func pressPicture()
	{
        //self.imagePicker.presentImageSourceView(sender: self)
    }
	
	//MARK: text field delegate
	func textFieldShouldEndEditing(textField: UITextField) -> Bool
	{
		textField.resignFirstResponder()
		return true
	}
    
	func textFieldShouldReturn(textField: UITextField) -> Bool
	{
		print("typed \(textField.text)");
		return true
	}

	//MARK: popover view delegate
	func dismissPopover()
	{
        dispatch_async(dispatch_get_main_queue())
        {
            self.dismissViewControllerAnimated(true, completion: nil)
        }
	}
	
	//MARK: trails datasource
	func performActionWithSelectedPark(park: String)
	{
        dispatch_async(dispatch_get_main_queue())
        {
            self.dismissViewControllerAnimated(true, completion: nil)
        }
        
		atPark = park
		trailButton.setTitle(park, forState: .Normal)
		self.setButtonHiddenness()
	}
	
	//MARK: image picker view controller
	func imagePickerController(picker: UIImagePickerController, didFinishPickingImage image: UIImage, editingInfo: [String : AnyObject]?)
	{
		imageView.image = image
		setButtonHiddenness()
        
        dispatch_async(dispatch_get_main_queue())
        {
            self.dismissViewControllerAnimated(true, completion: nil)
        }
	}
}
