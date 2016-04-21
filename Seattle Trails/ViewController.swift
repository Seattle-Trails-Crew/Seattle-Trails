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

class ViewController: ParkMapController, UITextFieldDelegate, UIPopoverPresentationControllerDelegate, ParksDataSource, PopoverViewDelegate, UIImagePickerControllerDelegate, GetsImageToShare, UINavigationControllerDelegate, UISearchBarDelegate, UISearchResultsUpdating, UITableViewDelegate, UITableViewDataSource
{
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var imageDamper: UIImageView!
    @IBOutlet weak var reportButton: UIBarButtonItem!
    @IBOutlet weak var shareButton: UIBarButtonItem!
    
    let imagePicker = UIImagePickerController()
    var searchController: UISearchController!
    let mailerView = EmailComposer()
    var tableView: PopoverViewController!
	
	var forReport = false
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
        self.fetchAndRenderTrails()
        self.setUpSearchBar()
        self.setupTableView()
        self.imagePicker.delegate = self
    }
	
	    // MARK: User Interaction
    @IBAction func reportButtonPressed(sender: UIBarButtonItem)
    {
         // Check to see if user is in a park before reporting an issue.
        if reportAvailable
		{
			forReport = true
            self.imagePicker.presentImagePickerWithSourceTypeForViewController(self, sourceType: .Camera, forIssue: true)
		}
    }
	
	@IBAction func optionsButtonPressed(sender: UIButton)
	{
		let alert = UIAlertController(title: "Options", message: nil, preferredStyle: UIAlertControllerStyle.ActionSheet)
		
		let key = UIAlertAction(title: "Key", style: .Default)
		{ (action) in
			AlertViews.presentMapKeyAlert(sender: self)
		}
		
		let filter = UIAlertAction(title: "Filter", style: .Default)
		{ (action) in
			self.shouldFilter = !self.shouldFilter
			
			//clear all existing points and then remake them with the new filter settings
			self.clearAnnotations()
			self.clearOverlays()
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
	
    @IBAction func shareButtonPressed(sender: UIBarButtonItem)
    {
			self.forReport = false
			self.imagePicker.presentCameraOrImageSourceSelectionView(sender: self)
	}
    @IBAction func cityCenterPressed(sender: UIButton) {
    }
	
    @IBAction func navButtonPressed(sender: UIButton)
    {
        self.moveMapToUserLocation()
    }
	
    @IBAction func volunteerPressed(sender: UIButton)
    {
        let mailView = self.mailerView.volunteerForParks()
        dispatch_async(dispatch_get_main_queue()) { 
            self.presentViewController(mailView, animated: true, completion: nil)
        }
    }
	
    // MARK: Popover View, Mail View, Image Picker & Segue Delegate Methods
    func updateSearchResultsForSearchController(searchController: UISearchController)
    {
        
    }
    
    func searchBarTextDidBeginEditing(searchBar: UISearchBar)
    {
        // Moved these here, rather than just upon typing
        self.tableView.hidden = false
        self.tableView.filterTrails("") // Display All Trails
        self.tableView.reloadData()
    }
    
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String)
    {
        self.tableView.hidden = false  // Just In Case They Dismiss, But Are Still Typing
        self.tableView.filterTrails(searchText)
        self.tableView.reloadData()
    }
    
    func searchBarCancelButtonClicked(searchBar: UISearchBar)
    {
        self.tableView.hidden = true
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return self.tableView.visibleParks.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCellWithIdentifier("cell")!
        cell.textLabel?.text = self.tableView.visibleParks[indexPath.row]
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath)
    {
        let park = self.tableView.visibleParks[indexPath.row]
        self.searchController.active = false
        self.performActionWithSelectedPark(park)
    }
    
    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView?
    {
        // Header Acts To Push TableView Down From NavBar
        return UIView()
    }
    
	override func shouldPerformSegueWithIdentifier(identifier: String, sender: AnyObject?) -> Bool
    {
		//you shouldn't be able to segue when you don't have any pins
		return parks.count > 0
	}
	
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject])
    {
		if (!forReport)
		{
			//try to share socially
			if let pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage
			{
				let activityItems:[AnyObject] = [pickedImage as AnyObject, "#SeaTrails" as AnyObject]
				let avc = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
                avc.completionWithItemsHandler = { (_, completed, _, activityError) in self.isLoading(false)}
				
				//set the subject field of email
				avc.setValue("My photo of \(self.currentPark ?? "a Seattle Park")", forKey: "subject")
				
				
				dispatch_async(dispatch_get_main_queue())
				{
					self.dismissViewControllerAnimated(true, completion: {
						dispatch_async(dispatch_get_main_queue())
						{
							self.presentViewController(avc, animated: true, completion: { 
                                self.isLoading(true)
                            })
						}
					})
				}
			}
			return
		}
		
		//try to send an issue report email
        if let pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage, let park = self.parks[currentPark!], let location = self.locationManager.location where self.mailerView.canSendMail
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
        showPark(parkName: park, withAnnotation: true)
        self.tableView.hidden = true
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
    // TODO: Refactor into computed properties?
    func setUpSearchBar()
    {
        // TODO: init search results view and set updater property.
        self.searchController = UISearchController(searchResultsController: nil)
        self.navigationController?.navigationBarHidden = false
        self.searchController.hidesNavigationBarDuringPresentation = false
        self.searchController.dimsBackgroundDuringPresentation = false
        self.searchController.definesPresentationContext = true
        self.searchController.searchBar.delegate = self
        self.searchController.searchResultsUpdater = self
        self.navigationItem.titleView = self.searchController.searchBar
    }
    
    func setupTableView()
    {
        self.tableView = PopoverViewController(frame: UIScreen.mainScreen().bounds, style: UITableViewStyle.Plain)
        self.tableView.translatesAutoresizingMaskIntoConstraints = false
        self.tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "cell")
        self.view.addSubview(self.tableView)
        self.tableView.parksDataSource = self
        self.tableView.dataSource = self
        self.tableView.delegate = self
        self.tableView.hidden = true
        let navbarHeight = searchController.searchBar.frame.height + UIApplication.sharedApplication().statusBarFrame.height
        self.tableView.sectionHeaderHeight = navbarHeight  // Push TableView Down Below NavBar
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
        self.reportButton.enabled = !loading
        self.shareButton.enabled = !loading
        
        self.loading = loading
    }

    func moveMapToUserLocation()
    {
        if let location = locationManager.location
        {
            let center = location.coordinate
            let region = MKCoordinateRegionMakeWithDistance(center, 1200, 1200)
            
            dispatch_async(dispatch_get_main_queue(), { 
                self.mapView.setRegion(region, animated: true)
            })
            
        }
    }
    
    func toggleSatteliteView() {
        dispatch_async(dispatch_get_main_queue(), {
            if self.mapView.mapType == MKMapType.Satellite
            {
                self.mapView.mapType = MKMapType.Standard
            }
            else if self.mapView.mapType == MKMapType.Standard
            {
                self.mapView.mapType = MKMapType.Satellite
            }
        })
        
    }
    
    func searchParks(parkName name: String)
    {
		print("SEARCHING PARK")
        for park in parks {
            if (name.caseInsensitiveCompare(park.0) == .OrderedSame)
            {
                defer
                {
                    dispatch_async(dispatch_get_main_queue(), {
						self.showPark(parkName: park.0, withAnnotation: true)
                    })
                }
                return
            }
        }
    }
}