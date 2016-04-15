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

class ViewController: ParkMapController, UITextFieldDelegate, UIPopoverPresentationControllerDelegate, ParksDataSource, PopoverViewDelegate, UIImagePickerControllerDelegate, GetsImageToShare, UINavigationControllerDelegate, UISearchBarDelegate
{
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var imageDamper: UIImageView!
	@IBOutlet weak var reportButton: UIButton!
	
    
    let imagePicker = UIImagePickerController()
    var searchController: UISearchController!
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
	
	var reportAvailable:Bool
	{
		return UIImagePickerController.isSourceTypeAvailable(.Camera) && currentPark != nil
	}
    
    // MARK: View Lifecyle Methods
    override func viewDidLoad()
    {
        super.viewDidLoad()
		self.setupAnnotationButtonClosure()
        self.fetchAndRenderTrails()
        self.setUpSearchBar()
        self.imagePicker.delegate = self
    }
	
	/**
	Sets up the ParkMapController to add buttons to the pin callouts.
	**/
	func setupAnnotationButtonClosure()
	{
		//TODO: assign custom images to these buttons using setImage
		
		self.annotationButtonClosure = { (view) in
			let driving = UIButton(type: UIButtonType.DetailDisclosure)
//			driving.setImage(<#T##image: UIImage?##UIImage?#>, forState: .Normal)
			driving.addTarget(self, action: #selector(self.drivingButtonPressed), forControlEvents: UIControlEvents.TouchUpInside)
			view.rightCalloutAccessoryView = driving
			
			let volunteering = UIButton(type: UIButtonType.ContactAdd)
//			volunteering.setImage(<#T##image: UIImage?##UIImage?#>, forState: .Normal)
			volunteering.addTarget(self, action: #selector(self.volunteeringButtonPressed), forControlEvents: UIControlEvents.TouchUpInside)
			view.leftCalloutAccessoryView = volunteering
		}
	}
	
	func drivingButtonPressed()
	{
		//TODO: show driving directions
	}
	
	func volunteeringButtonPressed()
	{
		let mailView = self.mailerView.volunteerForParks()
		dispatch_async(dispatch_get_main_queue()) {
			self.presentViewController(mailView, animated: true, completion: nil)
		}
	}
	
    // MARK: User Interaction
	
	@IBAction func reportButtonPressed(sender: UIButton)
	{
		if (reportAvailable)
		{
			//TODO: display the report issues image picker
		}
	}
	
	@IBAction func optionsButtonPressed(sender: UIButton)
	{
		let alert = UIAlertController(title: "Options", message: nil, preferredStyle: UIAlertControllerStyle.ActionSheet)
		
		let key = UIAlertAction(title: "Map Key", style: .Default)
		{ (action) in
			AlertViews.presentMapKeyAlert(sender: self)
		}
		
		let filter = UIAlertAction(title: "Filter", style: .Default)
		{ (action) in
			self.shouldFilter = !self.shouldFilter
			
			//clear all existing points and then remake them with the new filter settings
			self.clearAnnotations()
			self.annotateAllParks()
		}
		
		let satellite = UIAlertAction(title: self.mapView.mapType == MKMapType.Satellite ? "Map View" : "Satellite View", style: .Default)
		{ (action) in
			self.toggleSatteliteView()
		}
		
		let cancel = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
		alert.addAction(key)
		alert.addAction(filter)
		alert.addAction(satellite)
		alert.addAction(cancel)
		
		self.presentViewController(alert, animated: true, completion: nil)
	}
	
	
	@IBAction func shareButtonPressed(sender: UIButton)
	{
		self.performSegueWithIdentifier("showSocial", sender: self)
	}
	
    @IBAction func navButtonPressed(sender: UIButton)
    {
        self.moveMapToUserLocation()
    }
	
    @IBAction func volunteerPressed(sender: UIButton) {
        let mailView = self.mailerView.volunteerForParks()
        dispatch_async(dispatch_get_main_queue()) { 
            self.presentViewController(mailView, animated: true, completion: nil)
        }
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
    func setUpSearchBar()
    {
        // TODO: init search results view and set updater property.
        self.searchController = UISearchController(searchResultsController: nil)
        self.navigationController?.navigationBarHidden = false
        self.searchController.dimsBackgroundDuringPresentation = true
        self.searchController.searchBar.delegate = self
        self.navigationItem.titleView = self.searchController.searchBar
        self.definesPresentationContext = true
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