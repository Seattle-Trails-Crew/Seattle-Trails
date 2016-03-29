//
//  ViewController.swift
//  Seattle Trails
//
//  Created by Eric Mentele on 3/18/16.
//  Copyright © 2016 seatrails. All rights reserved.
// Test change for demo

import UIKit
import MapKit

protocol TrailsDataSource
{
    var trails: [String: [Trail]] { get }
    func performActionWithSelectedTrail(trail: String)
}

class ViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate, UITextFieldDelegate, UIPopoverPresentationControllerDelegate, TrailsDataSource, PopoverViewDelegate
{

    @IBOutlet weak var mapView: MKMapView!
    var trails = [String:[Trail]]()
    var parkNames = [String]()
    var locationManager: CLLocationManager?
	var loaded = false
	var loading = false
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var imageDamper: UIImageView!
    
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
        if locationManager != nil {
            if let location = locationManager!.location {
                let center = location.coordinate
                let region = MKCoordinateRegionMakeWithDistance(center, 1200, 1200)
                mapView.setRegion(region, animated: true)
            }
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
    @IBAction func searchButtonPressed(sender: UIButton)
    {
//        performSegueWithIdentifier("PopoverSegue", sender: nil)
//        view.endEditing(true)
//        if let search = searchTextField.text {
//            searchTrails(parkName: search)
//        }
    }
    
    
    // MARK: Data Fetching Methods
    private func fetchAndRenderTrails()
    {
        self.isLoading(true)
        
        SocrataService.getAllTrails()
            { [unowned self] (trails) in
                //get rid of the loading
                self.isLoading(false)
                
                guard let trails = trails else
                {
                    self.loadDataFailed()
                    //TODO: also detect if they turn airplane mode off while in-app
                    return
                }
                
                self.trails = trails
                self.plotAllPoints()
                self.loaded = true
        }
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
    
    func loadDataFailed() {
        //display an error
        let failAlert = UIAlertController(title: "Error", message: "Failed to load trail info from Socrata. Please check network connection and try agian later.", preferredStyle: .Alert)
        let okButton = UIAlertAction(title: "OK", style: .Default, handler: nil)
        failAlert.addAction(okButton)
        self.presentViewController(failAlert, animated: true, completion: nil)
        
        //set it up to try to load again, when the app returns to focus
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ViewController.tryToLoad), name: UIApplicationWillEnterForegroundNotification, object: UIApplication.sharedApplication());
    }
    
    func tryToLoad()
    {
        if !self.loaded && !self.loading
        {
            self.fetchAndRenderTrails()
        }
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
        locationManager = CLLocationManager()
        locationManager?.delegate = self
        locationManager?.desiredAccuracy = kCLLocationAccuracyHundredMeters
        locationManager?.requestWhenInUseAuthorization()
        locationManager?.startUpdatingLocation()
        mapView.showsUserLocation = true
    }
    
    // TODO: Refactor from here down.
    func plotAllPoints()
    {
        for trailName in self.trails.keys
        {
            var numGood = 0
            var numBad = 0
            var totalCenter = CLLocationCoordinate2D(latitude: 0, longitude: 0)
            
            for trail in self.trails[trailName]!
            {
                if trail.easyTrail
                {
                    numGood += 1
                }
                else
                {
                    numBad += 1
                }
                
                let center = trail.center
                totalCenter.latitude += center.latitude
                totalCenter.longitude += center.longitude
            }
            
            totalCenter.latitude /= Double(numGood + numBad)
            totalCenter.longitude /= Double(numGood + numBad)
            
            let difficulty: String
            
            if (numGood > numBad)
            {
                difficulty = "Accessible"
            }
            else
            {
                difficulty = ""
            }
            
            annotatePark(totalCenter, text: trailName, difficulty: difficulty)
        }
    }
    
    func annotatePark(point: CLLocationCoordinate2D, text: String, difficulty: String)
    {
        // Only Plot One Point Per Trail
        if parkNames.indexOf(text) >= 0 {
            return
        }
        
        parkNames.append(text)
        
        // Annotation
        let annotation = MKPointAnnotation()
        annotation.coordinate = point
        annotation.title = text
        annotation.subtitle = difficulty
        mapView.addAnnotation(annotation)
    }
    
    // MARK: Helper Methods
    func centerMapOnTrail(trailName name: String)
    {
        var validPark = false  // Check that park name exists in list of parks
        var topRight = CLLocationCoordinate2D(latitude: 999, longitude: 999)
        var bottomLeft = CLLocationCoordinate2D(latitude: -999, longitude: -999)
        
        for trailKey in self.trails.keys {
            if trailKey == name && self.trails[trailKey] != nil {
                for trail in self.trails[trailKey]! {
                    validPark = true
                    if (!trail.isDrawn) {
                        plotTrailLine(trail)
                    }
                
                    for point in trail.points
                    {
                        topRight.latitude = min(topRight.latitude, point.latitude)
                        topRight.longitude = min(topRight.longitude, point.longitude)
                        bottomLeft.latitude = max(bottomLeft.latitude, point.latitude)
                        bottomLeft.longitude = max(bottomLeft.longitude, point.longitude)
                    }
                }
            }
        }
        if !validPark {
            return
        }
        let center = CLLocationCoordinate2D(latitude: (topRight.latitude + bottomLeft.latitude) / 2, longitude: (topRight.longitude + bottomLeft.longitude) / 2)
        let region = MKCoordinateRegionMake(center, MKCoordinateSpan(latitudeDelta: bottomLeft.latitude - topRight.latitude, longitudeDelta: bottomLeft.longitude - topRight.longitude))
        mapView.setRegion(region, animated: true)
    }
    
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

    
    // MARK: Map View Delegate Methods
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView?
    {
        if let _ = annotation as? MKUserLocation {
            return nil
        }
        
        
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
            centerMapOnTrail(trailName: title!)
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

    // MARK: Misc Delegate Methods
    func dismissPopover()
    {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    func performActionWithSelectedTrail(trail: String)
    {
        centerMapOnTrail(trailName: trail)
        dismissViewControllerAnimated(true, completion: nil)
    }
    //
    func adaptivePresentationStyleForPresentationController(controller: UIPresentationController) -> UIModalPresentationStyle
    {
        return UIModalPresentationStyle.None
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "PopoverSegue" {
            let popoverViewController = segue.destinationViewController as! PopoverViewController
            popoverViewController.popoverPresentationController?.delegate = self
            popoverViewController.trailsDataSource = self
            popoverViewController.delegate = self
        }
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool
    {
        view.endEditing(true)
        if let search = textField.text {
            searchTrails(parkName: search)
        }
        return false
    }
    
    func searchTrails(parkName name: String)
    {
        for trail in trails {
            if (name.caseInsensitiveCompare(trail.0) == .OrderedSame) {
                defer {
                    dispatch_async(dispatch_get_main_queue(), {
                        self.centerMapOnTrail(trailName: trail.0)
                    })
                }
                return
            }
        }
    }
}

