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
			{
                if MKMapRectContainsPoint(park.mapRect, userCoordinates)
                {
                    return name
                }
			}
		}
		
		return nil
	}
	
	var reportAvailable:Bool
	{
		return UIImagePickerController.isSourceTypeAvailable(.camera) && currentPark != nil
	}
	
	// MARK: View Lifecyle Methods
	override func viewDidLoad()
	{
		super.viewDidLoad()
		self.fetchAndRenderTrails()
		self.setUpSearchBar()
		self.setupTableView()
		self.imagePicker.delegate = self
		
		NotificationCenter.default.addObserver(self, selector: #selector(keyboardWasShown), name: NSNotification.Name.UIKeyboardDidShow, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(keyboardWasShown), name: NSNotification.Name.UIKeyboardDidChangeFrame, object: nil)
	}
	
	// MARK: User Interaction
	
	
	@IBAction func optionsButtonPressed(_ sender: UIButton)
	{
		let alert = UIAlertController(title: "Options", message: nil, preferredStyle: UIAlertControllerStyle.actionSheet)
		
		let key = UIAlertAction(title: "Key", style: .default)
		{ (action) in
			AlertViews.presentMapKeyAlert(sender: self)
		}
		
		let filter = UIAlertAction(title: "Filter", style: .default)
		{ (action) in
			self.shouldFilter = !self.shouldFilter
			
			//clear all existing points and then remake them with the new filter settings
			self.clearAnnotations()
			self.clearOverlays()
			self.annotateAllParks()
		}
		
		let satellite = UIAlertAction(title: self.mapView.mapType == MKMapType.satellite ? "Map View" : "Satellite View", style: .default)
		{ (action) in
			self.toggleSatteliteView()
		}
		
		let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
		alert.addAction(key)
		alert.addAction(filter)
		alert.addAction(satellite)
		alert.addAction(cancel)
		
		self.present(alert, animated: true, completion: nil)
	}
	
	@IBAction func shareButtonPressed(_ sender: UIBarButtonItem)
	{
        
        let actionController = UIAlertController(title: "Actions", message: "", preferredStyle: .actionSheet)
        let actionReport = UIAlertAction(title: "Report Problem", style: .default) { (action) in
            if self.reportAvailable
            {
                self.forReport = true
                self.dismiss(animated: true, completion: nil)
                self.imagePicker.presentImagePickerWithSourceTypeForViewController(self, sourceType: .camera, forIssue: true)
            } else {
                self.dismiss(animated: true, completion: nil)
                AlertViews.presentNotInParkAlert(sender: self)
            }
        }
        let actionShare = UIAlertAction(title: "Share Photo", style: .default) { (action) in
            self.forReport = false
            self.dismiss(animated: true, completion: nil)
            self.imagePicker.presentCameraOrImageSourceSelectionView(sender: self)
        }
        let actionCancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
       
		actionController.addAction(actionReport)
        actionController.addAction(actionShare)
        actionController.addAction(actionCancel)
        self.present(actionController, animated: true, completion: nil)
	}
	
	@IBAction func cityCenterPressed(_ sender: UIButton) {
		//clear anything you have open
		self.clearAnnotationCallouts()
		self.clearOverlays()
		
		//de-select all annotations, so the pin isn't still thought of as selected
		for annotation in self.mapView.annotations
		{
			self.mapView.deselectAnnotation(annotation, animated: false)
		}
		
		self.setMapViewPosition()
	}
	
	@IBAction func navButtonPressed(_ sender: UIButton)
	{
		self.moveMapToUserLocation()
        if currentPark != nil
        {
            self.performActionWithSelectedPark(self.currentPark!)
        }
    }
	
	@IBAction func volunteerPressed(_ sender: UIButton)
	{
		let mailView = self.mailerView.volunteerForParks()
		DispatchQueue.main.async {
			self.present(mailView, animated: true, completion: nil)
		}
	}
	
	// MARK: Delegate Methods
	
	override func hitSelector(_ sender: ParkAnnotationView)
	{
		let actionsView = UIAlertController(title: "Park Actions", message: nil, preferredStyle: .actionSheet)
		
		let volunteer = UIAlertAction(title: "Volunteer", style: .default) {(action) in
			self.volunteeringButtonPressed()
		}
		
		let drive = UIAlertAction(title: "Driving Directions", style: .default) {(action) in
			if let pin = sender.superview as? ParkPinView, let annotation = pin.annotation
			{
				let placemark = MKPlacemark(coordinate: annotation.coordinate, addressDictionary: nil)
				let mapItem = MKMapItem(placemark: placemark)
				let launchOptions = [MKLaunchOptionsDirectionsModeKey : MKLaunchOptionsDirectionsModeDriving]
				mapItem.openInMaps(launchOptions: launchOptions)
			}
			
		}
        
		let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
		
		actionsView.addAction(drive)
		actionsView.addAction(volunteer)
		actionsView.addAction(cancel)
		
		DispatchQueue.main.async {
			self.present(actionsView, animated: true, completion: nil)
		}
	}
	
	
	func updateSearchResults(for searchController: UISearchController)
	{
		
	}
	
	func searchBarTextDidBeginEditing(_ searchBar: UISearchBar)
	{
		// Moved these here, rather than just upon typing
		self.tableView.isHidden = false
		self.tableView.filterTrails("") // Display All Trails
		self.tableView.reloadData()
	}
	
	func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String)
	{
		self.tableView.isHidden = false  // Just In Case They Dismiss, But Are Still Typing
		self.tableView.filterTrails(searchText)
		self.tableView.reloadData()
	}
	
	func searchBarCancelButtonClicked(_ searchBar: UISearchBar)
	{
		self.tableView.isHidden = true
	}
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
	{
		return self.tableView.visibleParks.count
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
	{
		let cell = tableView.dequeueReusableCell(withIdentifier: "cell")!
		cell.textLabel?.text = self.tableView.visibleParks[indexPath.row]
		return cell
	}
	
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
	{
		let park = self.tableView.visibleParks[indexPath.row]
		self.searchController.isActive = false
		self.performActionWithSelectedPark(park)
	}
	
	func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView?
	{
		// Header Acts To Push TableView Down From NavBar
		return UIView()
	}
	
	override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool
	{
		//you shouldn't be able to segue when you don't have any pins
		return parks.count > 0
	}
	
	func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any])
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
				
				
				DispatchQueue.main.async
				{
					self.dismiss(animated: true, completion: {
						DispatchQueue.main.async
						{
							self.present(avc, animated: true, completion: {
								self.isLoading(true)
							})
						}
					})
				}
			}
			return
		}
		
		//try to send an issue report email
		if let pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage, let park = self.parks[currentPark!], let location = self.locationManager.location, self.mailerView.canSendMail
		{
			DispatchQueue.main.async
			{
				self.dismiss(animated: true, completion: {
					let mailView = self.mailerView.reportIssue(forPark: park, atUserLocation: location, withImage: pickedImage)
					
					DispatchQueue.main.async
					{
						self.present(mailView, animated: true, completion: nil)
					}
				})
			}
		}
		else
		{
			DispatchQueue.main.async
			{
				self.dismiss(animated: true, completion: {
					AlertViews.presentErrorAlertView(sender: self, title: "Failure", message: "Your device is currently unable to send email. Please check your email settings and network connection then try again. Thank you for helping us improve our parks.")
				})
			}
		}
	}
	
	func dismissPopover()
	{
		DispatchQueue.main.async
		{
			self.dismiss(animated: true, completion: nil)
		}
	}
	
	/**
	Moves map to selected trail annotation.
	
	- parameter trail: The name of a given trail.
	*/
	func performActionWithSelectedPark(_ park: String)
	{
		showPark(parkName: park, withAnnotation: true)
		self.tableView.isHidden = true
	}
	
	
	func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle
	{
		return UIModalPresentationStyle.none
	}
	
	func textFieldShouldReturn(_ textField: UITextField) -> Bool
	{
		view.endEditing(true)
		
		if let search = textField.text
		{
			searchParks(parkName: search)
		}
		
		return false
	}
	
	// MARK: Helper Methods
	
	override func didRotate(from fromInterfaceOrientation: UIInterfaceOrientation) {
		self.tableView.reloadData()
	}
	
    @objc func keyboardWasShown(_ note:Notification)
	{
		let info = note.userInfo as! [String : AnyObject]
		let sizeValue = info[UIKeyboardFrameBeginUserInfoKey] as! NSValue
		let footerHeight = sizeValue.cgRectValue.size.height
		
		let insets = UIEdgeInsetsMake(0, 0, footerHeight, 0)
		self.tableView.contentInset = insets
		self.tableView.scrollIndicatorInsets = insets
		
	}
	
	func volunteeringButtonPressed()
	{
		let mailer = self.mailerView
		let mailerView = mailer.volunteerForParks()
		DispatchQueue.main.async {
			self.present(mailerView, animated: true, completion: nil)
		}
	}
	
	
	func setUpSearchBar()
	{
		// TODO: init search results view and set updater property.
		self.searchController = UISearchController(searchResultsController: nil)
		self.navigationController?.isNavigationBarHidden = false
		self.searchController.hidesNavigationBarDuringPresentation = false
		self.searchController.dimsBackgroundDuringPresentation = false
		self.searchController.definesPresentationContext = true
		self.searchController.searchBar.delegate = self
		self.searchController.searchResultsUpdater = self
		self.navigationItem.titleView = self.searchController.searchBar
	}
	
	func setupTableView()
	{
		self.tableView = PopoverViewController(frame: UIScreen.main.bounds, style: UITableViewStyle.plain)
		self.tableView.translatesAutoresizingMaskIntoConstraints = false
		self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
		self.view.addSubview(self.tableView)
		self.tableView.parksDataSource = self
		self.tableView.dataSource = self
		self.tableView.delegate = self
		self.tableView.isHidden = true
		self.tableView.autoresizingMask = UIViewAutoresizing.flexibleWidth.union(UIViewAutoresizing.flexibleHeight)
		
		let navbarHeight = searchController.searchBar.frame.height + UIApplication.shared.statusBarFrame.height
		self.tableView.sectionHeaderHeight = navbarHeight  // Push TableView Down Below NavBar
	}
	
	// MARK: Map Data Fetching Methods
    @objc func tryToLoad()
	{
		if self.parks.count == 0 && !self.loading
		{
			self.fetchAndRenderTrails()
		}
	}
	
	fileprivate func fetchAndRenderTrails()
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
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.tryToLoad), name: NSNotification.Name.UIApplicationWillEnterForeground, object: UIApplication.shared);
	}
	
	/**
	Blocks the main main view and starts an activity indicator when data is loading, reverts when not loading.
	*/
	func isLoading(_ loading: Bool)
	{
		if loading
		{
			self.activityIndicator.startAnimating()
		}
		else
		{
			self.activityIndicator.stopAnimating()
		}
		
		self.imageDamper.isUserInteractionEnabled = loading
		self.imageDamper.isHidden = !loading
		self.shareButton.isEnabled = !loading
		
		self.loading = loading
	}
	
	func moveMapToUserLocation()
	{
		if let location = locationManager.location
		{
			let center = location.coordinate
			let region = MKCoordinateRegionMakeWithDistance(center, 1200, 1200)
			
			DispatchQueue.main.async(execute: {
				self.mapView.setRegion(region, animated: true)
			})
			
		}
	}
	
	func toggleSatteliteView() {
		DispatchQueue.main.async(execute: {
			if self.mapView.mapType == MKMapType.satellite
			{
				self.mapView.mapType = MKMapType.standard
			}
			else if self.mapView.mapType == MKMapType.standard
			{
				self.mapView.mapType = MKMapType.satellite
			}
		})
		
	}
	
	func searchParks(parkName name: String)
	{
		print("SEARCHING PARK")
		for park in parks {
			if (name.caseInsensitiveCompare(park.0) == .orderedSame)
			{
				defer
				{
					DispatchQueue.main.async(execute: {
						self.showPark(parkName: park.0, withAnnotation: true)
					})
				}
				return
			}
		}
	}
}
