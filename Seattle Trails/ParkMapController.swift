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
	var annotationButtonClosure:((MKPinAnnotationView)->())!
	
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
        annotation.color = gradientFromDifficulty(difficulty)
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
		
		for (_, park) in self.parks
		{
			for trail in park.trails
			{
				trail.isDrawn = false
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
        if let coloredAnnotation = annotation as? ColoredAnnotation {
            if let color  = coloredAnnotation.color {
                view.pinTintColor = color
            }
        }
		else
		{
			return nil
		}
		
        // Can we remove this and define the annotation methods here? -David W
		// That would require moving the image picker logic into the park map controller, which is not responsible for it
		// if you can think of a nicer method to avoid that, go ahead -Theodore
		self.annotationButtonClosure(view);
        
        // Button Takes User To Maps Directions
        let driving = DrivingButton(type: .DetailDisclosure)
        driving.coordinate = annotation.coordinate
        driving.addTarget(self, action: #selector(self.drivingButtonPressed(_:)), forControlEvents: UIControlEvents.TouchUpInside)
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
            if let color = coloredLine.color {
                polyLineRenderer.strokeColor = color
            }
        }
        polyLineRenderer.fillColor = UIColor.blueColor()
		
		polyLineRenderer.lineWidth = 2
		return polyLineRenderer
	}
	
	//MARK: helper methods
    
    func drivingButtonPressed(button: DrivingButton)
    {
        if let coords = button.coordinate {
            let placemark = MKPlacemark(coordinate: coords, addressDictionary: nil)
            let mapItem = MKMapItem(placemark: placemark)
            let launchOptions = [MKLaunchOptionsDirectionsModeKey : MKLaunchOptionsDirectionsModeDriving]
            mapItem.openInMapsWithLaunchOptions(launchOptions)
        }
    }
	
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
		let line = ColoredLine(coordinates: &trail.points, count: trail.points.count)
        
        // Easy   ->  Red: 0, Green: 1
        // Medium ->  Red: 1, Green: 1
        // Hard   ->  Red: 1, Green: 0
        if let difficulty = trail.gradePercent {
            line.color = gradientFromDifficulty(difficulty)
        }
        
		// Example How To Alter Colors
		trail.isDrawn = true
		mapView.addOverlay(line)
	}
}

/**
Returns Color From Green To Red Based On Difficulty
 - parameter difficulty: Int 0 - 10
 */
func gradientFromDifficulty(difficulty: Int) -> UIColor
{
    let red: CGFloat
    let green: CGFloat
    if difficulty < 6 {
        green = 0.9
        red = CGFloat(difficulty) / 5.0
    } else if difficulty == 6 {
        green = 0.9
        red = 0.9
    } else {
        green = (10 - CGFloat(difficulty)) / 5.0
        red = 0.9
    }
    return UIColor(red: red, green: green, blue: 0, alpha: 1)
}