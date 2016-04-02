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

protocol ParksDataSource
{
    var parks: [String: Park] { get }
    func performActionWithSelectedPark(park: String)
}

class ViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate, UITextFieldDelegate, UIPopoverPresentationControllerDelegate, ParksDataSource, PopoverViewDelegate, MFMailComposeViewControllerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate
{
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var imageDamper: UIImageView!
    
    var locationManager = CLLocationManager()
    lazy var issueImagePicker = UIImagePickerController()
    var currentPark: String?
    var parks = [String:Park]()
    var loaded = false
    var loading = false
    //TODO: temporary filter stuff
    var shouldFilter = false
    
    // MARK: View Lifecyle Methods
    override func viewDidLoad()
    {
        super.viewDidLoad()
        self.fetchAndRenderTrails()
		self.configureMapViewSettings()
        self.showUserLocation()
        self.setMapViewPosition()
    }
    
    // MARK: User Interaction
    @IBAction func infoButtonPressed(sender: UIButton) {
        // Tell user what the different color pins mean
        let infoAlert = UIAlertController(title: "Color Key", message: "Blue Pins: Park trails that may have rought terrain. \nGreen Pins: Park trails that are easy to walk.", preferredStyle: .Alert)
        let okButton = UIAlertAction(title: "OK", style: .Default, handler: nil)
        infoAlert.addAction(okButton)
        
        self.presentViewController(infoAlert, animated: true, completion: nil)
    }
    
    @IBAction func navButtonPressed(sender: UIButton)
    {
        if let location = locationManager.location {
            let center = location.coordinate
            let region = MKCoordinateRegionMakeWithDistance(center, 1200, 1200)
            mapView.setRegion(region, animated: true)
        }
    }
    
    @IBAction func satteliteViewButtonPressed(sender: UIButton)
    {
        if self.mapView.mapType == MKMapType.Satellite {
            self.mapView.mapType = MKMapType.Standard
        } else if mapView.mapType == MKMapType.Standard {
            self.mapView.mapType = MKMapType.Satellite
        }
    }
	
    @IBAction func reportIssuePressed(sender: UIButton)
    {
        // If the user is in a park. Ask for optional image then file report.
        if let parkName = isUserInPark() {
            self.presentIssueImageOptionView(parkName)
        } else {
            self.fireNotInParkAlert()
        }
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
	
    
    // MARK: Data Fetching Methods
    func tryToLoad()
    {
        if !self.loaded && !self.loading
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
                    return
                }
				
				//stop monitoring reachability changes
				AFNetworkReachabilityManager.sharedManager().stopMonitoring()
                
                self.parks = parks
                self.annotateAllParks()
                self.loaded = true
        }
    }

    func loadDataFailed() {
        //display an error
        let failAlert = UIAlertController(title: "Error", message: "Failed to load trail info from Socrata. Please check network connection and try agian later.", preferredStyle: .Alert)
        let okButton = UIAlertAction(title: "OK", style: .Default, handler: nil)
        failAlert.addAction(okButton)
        self.presentViewController(failAlert, animated: true, completion: nil)
        
        //set it up to try to load again, when the app returns to focus
//        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ViewController.tryToLoad), name: UIApplicationWillEnterForegroundNotification, object: UIApplication.sharedApplication());
		
		//set it up to also try to load again when reachability changes
		AFNetworkReachabilityManager.sharedManager().setReachabilityStatusChangeBlock()
		{ (status) in
			if (status == AFNetworkReachabilityStatus.ReachableViaWiFi)
			{
				self.tryToLoad()
			}
		}
		
		AFNetworkReachabilityManager.sharedManager().startMonitoring()
    }

    
    func isLoading(loading: Bool)
    {
        if loading {
            self.activityIndicator.startAnimating()
        } else {
            self.activityIndicator.stopAnimating()
        }
        
        self.imageDamper.userInteractionEnabled = loading
        self.imageDamper.hidden = !loading
        
        self.loading = loading
    }


    // MARK: Map View Methods
    func setMapViewPosition()
    {
        //set map view position
        let coordinate = CLLocationCoordinate2D(latitude: 47.6190648, longitude: -122.3391903)
        let region = MKCoordinateRegionMakeWithDistance(coordinate, 25000, 25000)
        mapView.setRegion(region, animated: true)
    }
    
    func configureMapViewSettings()
    {
        //configure map view
        mapView.delegate = self
        mapView.showsBuildings = false
        mapView.showsTraffic = false
    }
    
    func showUserLocation()
    {
        //set up location manager
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        mapView.showsUserLocation = true
    }
    
    func canReportIssues() {
        // Activate issue button
    }
    
    func annotateAllParks()
    {
        // Go through trails/parks and get their trail objects.
        for (name, park) in parks
        {
			//TODO: remove this if statement once we remove filtering
			if (!shouldFilter || park.hasOfficial)
			{
				annotatePark(park.region.center, text: name, difficulty: park.easyPark ? "Accessible" : "")
			}
        }
    }
    
    /**
     Annotates map with trail/park name in the middle of it's bounds.
     
     - parameter point:      The overall center point of the trail/park.
     - parameter text:       The trail/park name.
     - parameter difficulty: The overall difficulty rating of the trail.
     */
    func annotatePark(point: CLLocationCoordinate2D, text: String, difficulty: String)
    {
        // Annotation
        let annotation = MKPointAnnotation()
        annotation.coordinate = point
        annotation.title = text
        annotation.subtitle = difficulty
        
        mapView.addAnnotation(annotation)
    }
    
    
    // MARK: Map View Delegate Methods
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView?
    {
        if let _ = annotation as? MKUserLocation {
            return nil
        }
        
        // Set the annotation pin color based on overall trail difficulty.
        let view = MKPinAnnotationView(annotation: annotation, reuseIdentifier: nil)
        if let subtitle = annotation.subtitle {
            if subtitle == "Accessible" {
                view.pinTintColor = UIColor(red: 0, green: 0.5, blue: 0, alpha: 1)
            } else {
                view.pinTintColor = UIColor(red: 0.1, green: 0.2, blue: 1, alpha: 1)
            }
        } else {
            return nil
        }
        
        view.canShowCallout = true
        return view
    }
    
    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView)
    {
        if let _ = view.annotation as? MKUserLocation {
            return
        }
        
        if let title = view.annotation!.title {
            showPark(parkName: title!)
        }
    }
    
    func mapView(mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        let rect = mapView.visibleMapRect
        _ = CLLocationCoordinate2D(latitude: MKMapRectGetMinX(rect), longitude: MKMapRectGetMaxY(rect))
        _ = CLLocationCoordinate2D(latitude: MKMapRectGetMaxX(rect), longitude: MKMapRectGetMinY(rect))
        //        let distance = MKMetersBetweenMapPoints(eastPoint, westPoint)
        //        print("Distance: \(distance)")
        //        polyLineRenderer?.lineWidth = CGFloat(distance * 0.001)
        // let center = mapView.center
        // Do query, $where=within_box(..., center.lat, center.long, distance)
        
        // Removes all Annotations
        //        let annotationsToRemove = mapView.annotations.filter { $0 !== mapView.userLocation }
        //        mapView.removeAnnotations( annotationsToRemove )
        //
        //        print("Hit Here")
        //        socrataService.getTrailsInArea(upLeft, lowerRight: downRight)
        //            { (trails) in
        //                if let trails = trails
        //                {
        //                    self.plotAllLines(trails)
        //                }
        //                else
        //                {
        //                    print("Something Bad Happened")
        //                }
        //        }
        
    }
    
    func mapView(mapView: MKMapView, rendererForOverlay overlay: MKOverlay) -> MKOverlayRenderer
    {
        // Setting For Line Style
        let polyLineRenderer = MKPolylineRenderer(overlay: overlay)
        if let color = overlay.title {
            if color == "blue" {
                polyLineRenderer.strokeColor = UIColor(red: 0.1, green: 0.2, blue: 1, alpha: 1)
            } else if color == "green" {
                polyLineRenderer.strokeColor = UIColor(red: 0, green: 0.5, blue: 0, alpha: 1)
            }
        }
        
        polyLineRenderer.lineWidth = 2
        return polyLineRenderer
    }
    
    // MARK: Popover View, Mail View, Image Picker & Segue Delegate Methods
	override func shouldPerformSegueWithIdentifier(identifier: String, sender: AnyObject?) -> Bool {
		//you shouldn't be able to segue while still loading points
		return !loading
	}
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let popoverViewController = segue.destinationViewController as? PopoverViewController
		{
            popoverViewController.popoverPresentationController?.delegate = self
            popoverViewController.parksDataSource = self
            popoverViewController.delegate = self
        }
		else if let smvc = segue.destinationViewController as? SocialMediaViewController
		{
            smvc.atPark = self.isUserInPark()
            smvc.parks = parks // TODO: Do you need all parks or just parks[self.currentPark]. currentPark is set by isUserInPark()
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
        
        if let search = textField.text {
            searchParks(parkName: search)
        }
        
        return false
    }
    
    func searchParks(parkName name: String)
    {
        for park in parks {
            if (name.caseInsensitiveCompare(park.0) == .OrderedSame) {
                defer {
                    dispatch_async(dispatch_get_main_queue(), {
                        self.showPark(parkName: park.0)
                    })
                }
                return
            }
        }
    }
    
    func mailComposeController(controller: MFMailComposeViewController, didFinishWithResult result: MFMailComposeResult, error: NSError?) {
        controller.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        if let pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage, let park = self.currentPark{
            dismissViewControllerAnimated(true, completion: { 
                self.getConfiguredIssueReportForPark("Discovery Park", imageForIssue: pickedImage)
            })
        }else{
            dismissViewControllerAnimated(true, completion: nil)
        }
    }
    
    // MARK: Option Alert Views
    func presentImageSourceSelectionView() {
        // Present image picker options.
        let actionSheet = UIAlertController(title: "Image Source", message: nil, preferredStyle: UIAlertControllerStyle.ActionSheet)
        
        let cameraAction = UIAlertAction(title: "Camera", style: UIAlertActionStyle.Default)
        { (action) in
            dispatch_async(dispatch_get_main_queue(), {
                self.presentIssueImagePickerWithSourceType(UIImagePickerControllerSourceType.Camera)
            })
        }
        
        let libraryAction = UIAlertAction(title: "Photo Library", style: UIAlertActionStyle.Default)
        { (action) in
            dispatch_async(dispatch_get_main_queue(), {
                self.presentIssueImagePickerWithSourceType(UIImagePickerControllerSourceType.PhotoLibrary)
            })
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
        
        actionSheet.addAction(cameraAction)
        actionSheet.addAction(libraryAction)
        actionSheet.addAction(cancelAction)
        
        dispatch_async(dispatch_get_main_queue(), {
            self.presentViewController(actionSheet, animated: true, completion: nil)
        })
    }
    
    func presentIssueImageOptionView(parkName: String) {
        let fileIssueView = UIAlertController(title: "Send Issue Report", message: "Would you like to include a photo of the issue?.", preferredStyle: .Alert)
        
        let yesButton = UIAlertAction(title: "YES", style: .Default) { (yesAction) in
            self.getImageForParkIssue()
        }
        
        let noButton = UIAlertAction(title: "NO", style: .Default) { (noAction) in
            self.getConfiguredIssueReportForPark(parkName, imageForIssue: nil)
        }
        
        let cancelButton = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
        
        fileIssueView.addAction(yesButton)
        fileIssueView.addAction(noButton)
        fileIssueView.addAction(cancelButton)
        
        dispatch_async(dispatch_get_main_queue()) {
            self.presentViewController(fileIssueView, animated: true, completion: nil)
        }
    }
    
    // MARK: Helper Methods
    func getImageForParkIssue() {
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.Camera)
        {
            self.presentImageSourceSelectionView()
        }
        else
        {
            presentIssueImagePickerWithSourceType(UIImagePickerControllerSourceType.PhotoLibrary)
        }
        
    }
    
    private func presentIssueImagePickerWithSourceType(sourceType: UIImagePickerControllerSourceType)
    {
        self.issueImagePicker.delegate = self
        self.issueImagePicker.sourceType = sourceType
        dispatch_async(dispatch_get_main_queue()) { 
            self.presentViewController(self.issueImagePicker, animated: true, completion: nil)
        }
    }
    
    func getConfiguredIssueReportForPark(parkToParse: String, imageForIssue: UIImage?) {
        if let currentPark = self.parks[parkToParse], issueLocation = self.locationManager.location {
            let parkIssueReport = IssueReport(issueImage: imageForIssue, issueLocation: issueLocation, parkName: currentPark.name)
            
            self.presentIssueReportViewControllerForIssue(parkIssueReport)
        }
    }
    
    func presentIssueReportViewControllerForIssue(issue: IssueReport) {
        let issueReportVC = MFMailComposeViewController()
        issueReportVC.mailComposeDelegate = self
        issueReportVC.setToRecipients([issue.sendTo])
        issueReportVC.setSubject(issue.subject)
        issueReportVC.setMessageBody(issue.formFields, isHTML: false)
        issueReportVC.addAttachmentData(issue.issueImageData!, mimeType: "image/jpeg", fileName: "Issue report: \(issue.parkName)")
        
        dispatch_async(dispatch_get_main_queue(), {
            self.presentViewController(issueReportVC, animated: true, completion: nil)
        })
    }
    
    
    
    /**
     Given a park this will move the map view to it and draw all it's lines.
     
     - parameter name: The name of the trail to view and draw.
     */
    func showPark(parkName name: String)
    {
        // Check that park name exists in list of parks and get the map view scale.
        if let park = self.parks[name]
        {
            for trail in park.trails {
                if (!trail.isDrawn && (!shouldFilter || trail.official)) { //TODO: remove the filter/official stuff once we remove filter
                    plotTrailLine(trail)
                }
            }
            
            mapView.setRegion(park.region, animated: true)
        }
    }
    
    /**
     Draws the path line for a given trail with color representing difficulty.
     
     - parameter trail: The Trail object to draw.
     */
    func plotTrailLine(trail: Trail)
    {
        // Plot All Trail Lines
        let line = MKPolyline(coordinates: &trail.points, count: trail.points.count)
        
        // Example How To Alter Colors
        if trail.easyTrail {
            line.title = "green"
        } else {
            line.title = "blue"
        }
        
        trail.isDrawn = true
        mapView.addOverlay(line)
    }
    
    /**
     Checks all park map rects against user's location and returns the name of the park they are in or nil. Also sets currentPark class property with park name.
     - returns: Current park name or nil.
     */
    func isUserInPark() -> String? {
        if let location = locationManager.location {
            let userCooridinates = MKMapPointForCoordinate(location.coordinate)
            
            for (name, park) in self.parks { // TODO: Uncomment code and after testing complete
                //if MKMapRectContainsPoint(park.mapRect, userCooridinates) {
                self.currentPark = name
                return name
                //}
            }
        }
        
        return nil
    }
    
    // MARK: Alert Views
    func fireNotInParkAlert() {
        let issueView = UIAlertController(title: "Report Issue", message: "You must be on site at a trail or park to use this feature and report an issue. Thank you for helping us document park problems for service.", preferredStyle: .Alert)
        let okButton = UIAlertAction(title: "OK", style: .Default, handler: nil)
        issueView.addAction(okButton)
        dispatch_async(dispatch_get_main_queue()) {
            self.presentViewController(issueView, animated: true, completion: nil)
        }
    }
    
    func fireComposeViewErrorAlert() {
        let issueErrorView = UIAlertController(title: "Report Failure", message: "Your device is currently unable to send email in app. Please check your email settings and network connection then try again. Thank you.", preferredStyle: .Alert)
        let okButton = UIAlertAction(title: "OK", style: .Default, handler: nil)
        issueErrorView.addAction(okButton)
        dispatch_async(dispatch_get_main_queue()) {
            self.presentViewController(issueErrorView, animated: true, completion: nil)
        }
    }
}

