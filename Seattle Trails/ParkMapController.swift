//
//  ParkMapController.swift
//  Seattle Trails
//
//  Created by Theodore Abshire on 4/6/16.
//  Copyright © 2016 seatrails. All rights reserved.
//

import MapKit

/**
The ParkMapController is responsible for directly handling the parks, and translating them into map view pins and lines.
*/
class ParkMapController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate
{
	@IBOutlet weak var mapView: MKMapView!
	
	var locationManager = CLLocationManager()
	var parks = [String:Park]()
	
	//TODO: temporary filter stuff
	var shouldFilter = false
	
	override func viewDidLoad()
	{
		super.viewDidLoad()
		
		self.configureMapViewSettings()
		self.setMapViewPosition()
		self.showUserLocation()
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

	
	// MARK: Map View Methods
	/**
	Sets the map view's starting position.
	*/
	func setMapViewPosition()
	{
		//set map view position
		let coordinate = CLLocationCoordinate2D(latitude: 47.6190648, longitude: -122.3391903)
		let region = MKCoordinateRegionMakeWithDistance(coordinate, 25000, 25000)
		mapView.setRegion(region, animated: true)
	}
	
	/**
	Sets up the map view as desired for the app.
	*/
	private func configureMapViewSettings()
	{
		mapView.delegate = self
		mapView.showsBuildings = false
		mapView.showsTraffic = false
	}
	
	/**
	Sets up the location manager to show user location.
	*/
	func showUserLocation()
	{
		//set up location manager
		locationManager.delegate = self
		locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
		locationManager.requestWhenInUseAuthorization()
		locationManager.startUpdatingLocation()
		mapView.showsUserLocation = true
	}
	
	/**
	Make the annotation pins for all parks.
	*/
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
	
	// MARK: Map View Delegate Methods
	func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView?
	{
		if let _ = annotation as? MKUserLocation
		{
			return nil
		}
		
		// Set the annotation pin color based on overall trail difficulty.
		let view = MKPinAnnotationView(annotation: annotation, reuseIdentifier: nil)
		if let subtitle = annotation.subtitle
		{
			if subtitle == "Accessible" {
				view.pinTintColor = UIColor(red: 0, green: 0.5, blue: 0, alpha: 1)
			}
			else
			{
				view.pinTintColor = UIColor(red: 0.1, green: 0.2, blue: 1, alpha: 1)
			}
		}
		else
		{
			return nil
		}
		
		view.canShowCallout = true
		return view
	}
	
	func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView)
	{
		if let _ = view.annotation as? MKUserLocation
		{
			return
		}
		
		if let title = view.annotation!.title
		{
			showPark(parkName: title!)
		}
	}
	
	func mapView(mapView: MKMapView, regionDidChangeAnimated animated: Bool)
	{
		//TODO: in the future, if we want to add any kind of behavior to the map as it moves
		//IE loading or unloading trails, whatever
		//put it here
	}
	
	func mapView(mapView: MKMapView, rendererForOverlay overlay: MKOverlay) -> MKOverlayRenderer
	{
		// Setting For Line Style
		let polyLineRenderer = MKPolylineRenderer(overlay: overlay)
		
		if let color = overlay.title
		{
			if color == "blue"
			{
				polyLineRenderer.strokeColor = UIColor(red: 0.1, green: 0.2, blue: 1, alpha: 1)
			}
			else if color == "green"
			{
				polyLineRenderer.strokeColor = UIColor(red: 0, green: 0.5, blue: 0, alpha: 1)
			}
		}
		
		polyLineRenderer.lineWidth = 2
		return polyLineRenderer
	}
	
	//MARK: helper methods
	
	/**
	Given a park this will move the map view to it and draw all it's lines.
	
	- parameter name: The name of the trail to view and draw.
	*/
	func showPark(parkName name: String)
	{
		// Check that park name exists in list of parks and get the map view scale.
		if let park = self.parks[name]
		{
			for trail in park.trails
			{
				if (!trail.isDrawn && (!shouldFilter || trail.official))
				{ //TODO: remove the filter/official stuff once we remove filter
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
		if trail.easyTrail
		{
			line.title = "green"
		}
		else
		{
			line.title = "blue"
		}
		
		trail.isDrawn = true
		mapView.addOverlay(line)
	}
}