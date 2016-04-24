//
//  ParkMapController.swift
//  Seattle Trails
//
//  Created by Theodore Abshire on 4/6/16.
//  Copyright © 2016 seatrails. All rights reserved.
//

import MapKit


class ColoredLine: MKPolyline
{
    var color: UIColor?
	var width: CGFloat?
}
class ColoredAnnotation: MKPointAnnotation
{
    var color: UIColor?
    
}
class DrivingButton: UIButton
{
    var coordinate: CLLocationCoordinate2D?
}

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
    func annotatePark(point: CLLocationCoordinate2D, text: String, difficulty: Int, surfaces: [String])
	{
		// Annotation
		let annotation = ColoredAnnotation()
		annotation.coordinate = point
		annotation.title = text
        annotation.subtitle = surfaces.joinWithSeparator(", ")
        annotation.color = gradientFromDifficulty(difficulty, forAnnotation: true)
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
        
        dispatch_async(dispatch_get_main_queue()) { 
            self.mapView.setRegion(region, animated: true)
        }
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
            let difficulty = park.difficulty
            
			//TODO: remove this if statement once we remove filtering
			if (!shouldFilter || park.hasOfficial)
			{
				annotatePark(park.region.center, text: name, difficulty: difficulty, surfaces: park.surfaces)
			}
		}
	}
	
	/**
	Clears all map annotations
	*/
	func clearAnnotations()
	{
		self.mapView.removeAnnotations(self.mapView.annotations)
	}
	
	/**
	Clears all map overlays
	*/
	func clearOverlays()
	{
		self.mapView.removeOverlays(self.mapView.overlays)
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
        if let coloredAnnotation = annotation as? ColoredAnnotation {
            if let color  = coloredAnnotation.color {
                view.pinTintColor = color
            }
        }
		else
		{
			return nil
		}
        
        // Button Takes User To Maps Directions
        let driving = DrivingButton(type: .DetailDisclosure)
        driving.coordinate = annotation.coordinate
        view.rightCalloutAccessoryView = driving
        
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
			showPark(parkName: title!, withAnnotation: false)
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
		
        if let coloredLine = overlay as? ColoredLine {
            if let color = coloredLine.color, width = coloredLine.width {
                polyLineRenderer.strokeColor = color
				polyLineRenderer.lineWidth = width
            }
        }
		return polyLineRenderer
	}
	
	//MARK: helper methods
	
	/**
	Given a park this will move the map view to it and draw all it's lines.
	
	- parameter name: The name of the trail to view and draw.
	- parameter withAnnotation: Set to true if you want to activate the pin.
	*/
	func showPark(parkName name: String, withAnnotation:Bool)
	{
		// Check that park name exists in list of parks and get the map view scale.
		if let park = self.parks[name]
		{
			// hides the previous park's lines
			self.clearOverlays()
			
			if withAnnotation
			{
				//turn that annotation on
				for annotation in self.mapView.annotations
				{
					if let title = annotation.title!
					{
						if title == name
						{
							self.mapView.selectAnnotation(annotation, animated: true)
							
							//turning the annotation on will call showPark again, without withAnnotation, so just end here
							return
						}
					}
				}
			}
			
			for trail in park.trails
			{
				if (!shouldFilter || trail.official)
				{ //TODO: remove the filter/official stuff once we remove filter
					plotTrailLine(trail, border: true)
				}
			}
			for trail in park.trails
			{
				if (!shouldFilter || trail.official)
				{ //TODO: remove the filter/official stuff once we remove filter
					plotTrailLine(trail, border: false)
				}
			}
			
			mapView.setRegion(park.region, animated: true)
		}
	}
	
	/**
	Draws the path line for a given trail with color representing difficulty.
	
	- parameter trail: The Trail object to draw.
	*/
	func plotTrailLine(trail: Trail, border:Bool)
	{
		// Plot All Trail Lines
		let line = ColoredLine(coordinates: &trail.points, count: trail.points.count)
        
        // Easy   ->  Red: 0, Green: 1
        // Medium ->  Red: 1, Green: 1
        // Hard   ->  Red: 1, Green: 0
		if (border)
		{
			line.color = colorFromSurfaces(trail.surfaceType)
			line.width = 8
		}
		else if let difficulty = trail.gradePercent {
			line.color = gradientFromDifficulty(difficulty, forAnnotation: false)
			line.width = 5
		}
		
		mapView.addOverlay(line)
	}
}

/**
Returns color from surface hardness
 - parameter surfaceType: a string containing the name of the surface type
*/
func colorFromSurfaces(surfaceType:String?) -> UIColor
{
	if let surfaceType = surfaceType
	{
		switch(surfaceType.lowercaseString)
		{
            //TODO: Hard, medium, soft, stairs. surface types white, brown, black.
            //TODO: Smoother line size scaling. Dashes or dots instead of colored outline?
		//black is "bad" surfaces
		case "grass": fallthrough
		case "soil": return UIColor.brownColor()
		case "bark": fallthrough
		case "gravel": return UIColor.whiteColor()
		case "stairs": fallthrough
		case "check steps": return UIColor.redColor()
			
		//gray is "good" surfaces
		case "boardwalk": fallthrough
		case "asphalt": fallthrough
		case "bridge": fallthrough
		case "concrete": return UIColor.blackColor()
			
		default: break
		}
	}
	
	//if the surfacetype is unknown, or it doesn't have one
	return UIColor.blackColor()
}

/**
Returns Color From Green To Red Based On Difficulty
 - parameter difficulty: Int 0 - 10
 */
func gradientFromDifficulty(difficulty: Int, forAnnotation: Bool) -> UIColor
{
	//when making a pin, set the difficulty to 0, 5, or 10, depending on what is the closest
	//this way the park pins will be one of three standard colors (green for easy, yellow for medium, red for hard)
	var difficulty = difficulty
	if forAnnotation
	{
		if (difficulty > 5)
		{
			difficulty = abs(difficulty - 5) < abs(difficulty - 10) ? 5 : 10;
		}
		else
		{
			difficulty = abs(difficulty - 5) < difficulty ? 5 : 0;
		}
	}
	
	let green:CGFloat = 1.0 / 3.0;
	return UIColor(hue: green * CGFloat(difficulty) * 0.1, saturation: 0.9, brightness: 0.9, alpha: 1)
}