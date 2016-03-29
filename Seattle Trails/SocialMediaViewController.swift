//
//  SocialMediaViewController.swift
//  Seattle Trails
//
//  Created by Theodore Abshire on 3/28/16.
//  Copyright © 2016 seatrails. All rights reserved.
//

import UIKit
import Social

class SocialMediaViewController: UIViewController, PopoverViewDelegate, TrailsDataSource, UIPopoverPresentationControllerDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate, UIGestureRecognizerDelegate {
	
	//MARK: outlets
	@IBOutlet weak var imageBacker: UIView!
	@IBOutlet weak var imageView: UIImageView!
	@IBOutlet weak var trailButton: UIButton!
	@IBOutlet weak var shareButton: UIButton!
	
	
	
	//MARK: inner data
	private var picker:UIImagePickerController?
	
	
	//MARK: data to be set by view controller during transition
	var parkNames = [String]()
	var trails = [String:[Trail]]()
	var atPark:String?
	

    override func viewDidLoad()
	{
        super.viewDidLoad()

        imageBacker.layer.cornerRadius = 10
		trailButton.setTitle(atPark ?? "PICK A PARK", forState: .Normal)
		self.setButtonHiddenness()
    }
	
	override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
		if let popoverViewController = segue.destinationViewController as? PopoverViewController
		{
			popoverViewController.popoverPresentationController?.delegate = self
			popoverViewController.trailsDataSource = self
			popoverViewController.delegate = self
		}
	}
	
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
		
		//TODO: instagram support; looks like it's not built into the social framework
//		let gram = UIAlertAction(title: "Instagram", style: .Default)
//		{ (action) in
//		}
//		actionSheet.addAction(gram)
		
		let nevermind = UIAlertAction(title: "Cancel", style: .Cancel)
		{ (action) in
		}
		actionSheet.addAction(nevermind)
		
		presentViewController(actionSheet, animated: true, completion: nil)
	}
	
	func finishSocial(serviceType:String, serviceName:String)
	{
		if (SLComposeViewController.isAvailableForServiceType(serviceType))
		{
			let composer = SLComposeViewController(forServiceType: serviceType)
//			composer.setInitialText("#Seatrails Photo of \(atPark!). ")
			composer.setInitialText("#TESTHASHTAG Photo of \(atPark!). ")
			composer.addImage(imageView.image)
			
			presentViewController(composer, animated: true, completion: nil)
		}
		else
		{
			let alert = UIAlertController(title: "Log in", message: "You must log in to \(serviceName) first! Go to settings and log in.", preferredStyle: UIAlertControllerStyle.Alert)
			
			let cancel = UIAlertAction(title: "Okay", style: .Cancel, handler: nil)
			alert.addAction(cancel)
			
			presentViewController(alert, animated: true, completion: nil)
		}
	}
	
	
	@IBAction func pressPicture()
	{
		if picker == nil //don't want to have multiple simultaneous pickers
		{
			picker = UIImagePickerController()
			picker!.delegate = self
			if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.Camera)
			{
				//open a dialogue to finish this
				let actionSheet = UIAlertController(title: "Where from?", message: "Should your use the camera, or the photo library?", preferredStyle: UIAlertControllerStyle.ActionSheet)
				
				let cameraAction = UIAlertAction(title: "Camera", style: UIAlertActionStyle.Default)
				{ (action) in
					self.finishPicker(UIImagePickerControllerSourceType.Camera)
				}
				actionSheet.addAction(cameraAction)
				
				let libraryAction = UIAlertAction(title: "Photo Library", style: UIAlertActionStyle.Default)
				{ (action) in
					self.finishPicker(UIImagePickerControllerSourceType.PhotoLibrary)
				}
				actionSheet.addAction(libraryAction)
				
				let cancelAction = UIAlertAction(title: "Nevermind", style: UIAlertActionStyle.Cancel)
				{ (action) in
					
				}
				actionSheet.addAction(cancelAction)
				
				presentViewController(actionSheet, animated: true, completion: nil)
			}
			else
			{
				//just use the library
				finishPicker(UIImagePickerControllerSourceType.PhotoLibrary)
			}
		}
	}
	
	private func finishPicker(sourceType: UIImagePickerControllerSourceType)
	{
		picker!.sourceType = sourceType
		presentViewController(picker!, animated: true, completion: nil)
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
		dismissViewControllerAnimated(true, completion: nil)
	}
	
	//MARK: trails datasource
	func performActionWithSelectedTrail(trail: String)
	{
		dismissViewControllerAnimated(true, completion: nil)
		atPark = trail
		trailButton.setTitle(trail, forState: .Normal)
		self.setButtonHiddenness()
	}
	
	//MARK: image picker view controller
	func imagePickerController(picker: UIImagePickerController, didFinishPickingImage image: UIImage, editingInfo: [String : AnyObject]?)
	{
		imageView.image = image
		setButtonHiddenness()
		picker.dismissViewControllerAnimated(true)
		{
			self.picker = nil
		}
	}
	func imagePickerControllerDidCancel(picker: UIImagePickerController)
	{
		picker.dismissViewControllerAnimated(true)
		{
			self.picker = nil
		}
	}
}
