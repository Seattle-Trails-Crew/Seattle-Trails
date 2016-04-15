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

class ViewController: ParkMapController, UITextFieldDelegate, UIPopoverPresentationControllerDelegate, ParksDataSource, PopoverViewDelegate, UIImagePickerControllerDelegate, GetsImageToShare, UINavigationControllerDelegate
{
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var imageDamper: UIImageView!
    
    let imagePicker = UIImagePickerController()
    let mailerView = EmailComposer()
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
	
	@IBAction func reportButtonPressed(sender: UIButton)
	{
		
	}
	
	@IBAction func optionsButtonPressed(sender: UIButton)
	{
		
	}
	
	
	@IBAction func shareButtonPressed(sender: UIButton)
	{
		
	}
    
    @IBAction func navButtonPressed(sender: UIButton)
    {
        self.moveMapToUserLocation()
    }
    
    @IBAction func satteliteViewButtonPressed(sender: UIButton)
    {
        self.toggleSatteliteView()
    }
	
	@IBAction func parkButtonPressed()
	{
        self.imagePicker.presentImagePurposeSelectionView(sender: self, inPark: self.currentPark)
	}
    
    @IBAction func volunteerPressed(sender: UIButton) {
        let mailView = self.mailerView.volunteerForParks()
        dispatch_async(dispatch_get_main_queue()) { 
            self.presentViewController(mailView, animated: true, completion: nil)
        }
    }
    
    @IBAction func filterButtonPressed() // Temporary functionality that will be deleted so no refactor performed
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
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject])
    {
        if let pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage, let park = self.parks[currentPark!], let location = self.locationManager.location where self.mailerView.canSendMail()
        {
                dispatch_async(dispatch_get_main_queue())
                {
                    self.dismissViewControllerAnimated(true, completion: {
                        let mailView = self.mailerView.reportIssue(forPark: park, atUserLocation: location, withImage: pickedImage)
                        
                        dispatch_async(dispatch_get_main_queue())
                        {
                            self.presentViewController(mailView, animated: true, completion: nil)
                        }
                    })
                }
        }
        else
        {
            dispatch_async(dispatch_get_main_queue())
            {
                self.dismissViewControllerAnimated(true, completion: { 
                    AlertViews.presentErrorAlertView(sender: self, title: "Failure", message: "Your device is currently unable to send email. Please check your email settings and network connection then try again. Thank you for helping us improve our parks.")
                })
            }
        }
    }
    
    func dismissPopover()
    {
        dispatch_async(dispatch_get_main_queue())
        {
            self.dismissViewControllerAnimated(true, completion: nil)
        }
    }
    
    /**
     Moves map to selected trail annotation.
     
     - parameter trail: The name of a given trail.
     */
    func performActionWithSelectedPark(park: String)
    {
        showPark(parkName: park)
        dispatch_async(dispatch_get_main_queue())
        {
            self.dismissViewControllerAnimated(true, completion: nil)
        }
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
    
    // MARK: Helper Methods
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
            { [unowned self] (parks) in // TODO: Check if unowned is needed.
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
        AlertViews.presentErrorAlertView(sender: self, title: "Connection Error", message: "Failed to load trail info from Socrata. Please check network connection and try again later.")
        
        //set it up to try to load again, when the app returns to focus
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ViewController.tryToLoad), name: UIApplicationWillEnterForegroundNotification, object: UIApplication.sharedApplication());
    }
    
    /**
     Blocks the main main view and starts an activity indicator when data is loading, reverts when not loading.
     */
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

    func moveMapToUserLocation()
    {
        if let location = locationManager.location
        {
            let center = location.coordinate
            let region = MKCoordinateRegionMakeWithDistance(center, 1200, 1200)
            mapView.setRegion(region, animated: true)
        }
    }
    
    func toggleSatteliteView() {
        if self.mapView.mapType == MKMapType.Satellite
        {
            self.mapView.mapType = MKMapType.Standard
        }
        else if mapView.mapType == MKMapType.Standard
        {
            self.mapView.mapType = MKMapType.Satellite
        }
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
}