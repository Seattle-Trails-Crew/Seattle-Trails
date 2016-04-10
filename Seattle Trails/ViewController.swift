//
//  ViewController.swift
//  Seattle Trails
//
//  Created by Eric Mentele on 3/18/16.
//  Copyright © 2016 seatrails. All rights reserved.
// Test change for demo

import UIKit
import MapKit
import MessageUI

class ViewController: ParkMapController, UITextFieldDelegate, UIPopoverPresentationControllerDelegate, ParksDataSource, PopoverViewDelegate, MFMailComposeViewControllerDelegate, UIImagePickerControllerDelegate, GetsImageToShare, UINavigationControllerDelegate
{
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var imageDamper: UIImageView!
    
    var imagePicker = UIImagePickerController()
    var loading = false
    
    var currentPark:String?
    {
        if let location = locationManager.location
        {
            let userCoordinates = MKMapPointForCoordinate(location.coordinate)
            
            for (name, park) in self.parks
            { // TODO: Uncomment code and after testing complete
                //if MKMapRectContainsPoint(park.mapRect, userCoordinates) {
                return name
                //}
            }
        }
        
        return nil
    }
    
    // MARK: View Lifecyle Methods
    override func viewDidLoad()
    {
        super.viewDidLoad()
        self.fetchAndRenderTrails()
        self.imagePicker.delegate = self
    }
    
    // MARK: User Interaction
    @IBAction func infoButtonPressed(sender: UIButton)
    {
        AlertViews.presentMapKeyAlert(sender: self)
    }
    
    @IBAction func navButtonPressed(sender: UIButton)
    {
        if let location = locationManager.location
        {
            let center = location.coordinate
            let region = MKCoordinateRegionMakeWithDistance(center, 1200, 1200)
            mapView.setRegion(region, animated: true)
        }
    }
    
    @IBAction func satteliteViewButtonPressed(sender: UIButton)
    {
        if self.mapView.mapType == MKMapType.Satellite
        {
            self.mapView.mapType = MKMapType.Standard
        }
        else if mapView.mapType == MKMapType.Standard
        {
            self.mapView.mapType = MKMapType.Satellite
        }
    }
	
	@IBAction func parkButtonPressed()
	{
		let alert = UIAlertController(title: "Park Actions", message: nil, preferredStyle: UIAlertControllerStyle.ActionSheet)
		
		let sharePhoto = UIAlertAction(title: "Share Photo", style: .Default)
		{ (action) in
			self.performSegueWithIdentifier("showSocial", sender: self)
		}
		alert.addAction(sharePhoto)
		
		
		if let _ = self.currentPark
		{
			let report = UIAlertAction(title: "Report Issue", style: .Default)
			{ (action) in
                self.imagePicker.getPictureFor(sender: self)
			}
			alert.addAction(report)
		}
		
		let cancel = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
		alert.addAction(cancel)
		
		self.presentViewController(alert, animated: true, completion: nil)
	}
    
	@IBAction func filterButtonPressed()
	{
		shouldFilter = !shouldFilter
		
		//clear all existing points and such
		self.mapView.removeAnnotations(self.mapView.annotations)
		self.mapView.removeOverlays(self.mapView.overlays)
        
		for (_, park) in self.parks
		{
			for trail in park.trails
			{
				trail.isDrawn = false
			}
		}
		
		self.annotateAllParks()
	}
	
    
    // MARK: Map Data Fetching Methods
    func tryToLoad()
    {
        if self.parks.count == 0 && !self.loading
        {
            self.fetchAndRenderTrails()
        }
    }
    
    private func fetchAndRenderTrails()
    {
        self.isLoading(true)
        
        SocrataService.getAllTrails()
            { [unowned self] (parks) in
                //get rid of the spinner
                self.isLoading(false)
                
                guard let parks = parks else
                {
                    self.loadDataFailed()
                    //TODO: also detect if they turn airplane mode off while in-app
                    return
                }
                
                self.parks = parks
                self.annotateAllParks()
        }
    }

    func loadDataFailed() {
        //display an error
        AlertViews.presentNotConnectedAlert(sender: self)
        
        //set it up to try to load again, when the app returns to focus
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ViewController.tryToLoad), name: UIApplicationWillEnterForegroundNotification, object: UIApplication.sharedApplication());
    }

    
    func isLoading(loading: Bool)
    {
        if loading
        {
            self.activityIndicator.startAnimating()
        }
        else
        {
            self.activityIndicator.stopAnimating()
        }
        
        self.imageDamper.userInteractionEnabled = loading
        self.imageDamper.hidden = !loading
        
        self.loading = loading
    }
    
    // MARK: Popover View, Mail View, Image Picker & Segue Delegate Methods
	override func shouldPerformSegueWithIdentifier(identifier: String, sender: AnyObject?) -> Bool
    {
		//you shouldn't be able to segue when you don't have any pins
		return parks.count > 0
	}
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?)
    {
        if let popoverViewController = segue.destinationViewController as? PopoverViewController
		{
            popoverViewController.popoverPresentationController?.delegate = self
            popoverViewController.parksDataSource = self
            popoverViewController.delegate = self
        }
		else if let smvc = segue.destinationViewController as? SocialMediaViewController
		{
            smvc.atPark = self.currentPark
            smvc.parks = parks //attach a list of all parks, for use in the search
        }
    }
    
    func dismissPopover()
    {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    /**
     Moves map to selected trail annotation.
     
     - parameter trail: The name of a given trail.
     */
    func performActionWithSelectedPark(park: String)
    {
        showPark(parkName: park)
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    
    func adaptivePresentationStyleForPresentationController(controller: UIPresentationController) -> UIModalPresentationStyle
    {
        return UIModalPresentationStyle.None
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool
    {
        view.endEditing(true)
        
        if let search = textField.text
        {
            searchParks(parkName: search)
        }
        
        return false
    }
    
    func searchParks(parkName name: String)
    {
        for park in parks {
            if (name.caseInsensitiveCompare(park.0) == .OrderedSame)
            {
                defer
                {
                    dispatch_async(dispatch_get_main_queue(), {
                        self.showPark(parkName: park.0)
                    })
                }
                return
            }
        }
    }
    
    // TODO: Refactor
    func mailComposeController(controller: MFMailComposeViewController, didFinishWithResult result: MFMailComposeResult, error: NSError?)
    {
        controller.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject])
    {
        if let pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage, let park = self.currentPark
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
    
        
    // MARK: Helper Methods
    func getConfiguredIssueReportForPark(parkToParse: String, imageForIssue: UIImage?)
    {
        if let currentPark = self.parks[parkToParse], issueLocation = self.locationManager.location
        {
            let parkIssueReport = IssueReport(issueImage: imageForIssue, issueLocation: issueLocation, parkName: currentPark.name)
            
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

