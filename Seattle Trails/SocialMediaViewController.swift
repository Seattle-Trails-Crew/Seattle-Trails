//
//  SocialMediaViewController.swift
//  Seattle Trails
//
//  Created by Theodore Abshire on 3/28/16.
//  Copyright © 2016 seatrails. All rights reserved.
//

import UIKit

class SocialMediaViewController: UIViewController, UITextFieldDelegate, PopoverViewDelegate, TrailsDataSource, UIPopoverPresentationControllerDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate, UIGestureRecognizerDelegate {
	
	//MARK: outlets
	@IBOutlet weak var imageBacker: UIView!
	@IBOutlet weak var imageView: UIImageView!
	@IBOutlet weak var trailButton: UIButton!
	@IBOutlet weak var messageField: UITextField!
	@IBOutlet weak var twitterButton: UIButton!
	@IBOutlet weak var facebookButton: UIButton!
	@IBOutlet weak var instagramButton: UIButton!
	
	
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
		messageField.delegate = self
		trailButton.setTitle(atPark ?? "PICK A PARK", forState: .Normal)
		self.setButtonHiddenness()
		
		//TODO: message field should have a maximum text size to make sure it fits into twitter (be sure to account for the #Seatrails hashtag, etc)
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
		if (atPark != nil && imageView.image != nil) //TODO: if we add a default image image to the imageview, the image != nil check should be changed
		{
			twitterButton.hidden = false
			instagramButton.hidden = false
			facebookButton.hidden = false
		}
		else
		{
			twitterButton.hidden = true
			instagramButton.hidden = true
			facebookButton.hidden = true
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
