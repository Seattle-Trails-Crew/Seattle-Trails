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
        mapView.showsScale = true
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
                annotatePark(park.region.center, parkName: name, difficulty: difficulty, surfaces: park.surfaces)
            }
        }
    }
    
    /**
     Annotates map with trail/park name in the middle of it's bounds.
     
     - parameter point:      The overall center point of the trail/park.
     - parameter text:       The trail/park name.
     - parameter difficulty: The overall difficulty rating of the trail.
     */
    func annotatePark(point: CLLocationCoordinate2D, parkName: String, difficulty: Int, surfaces: [String])
    {
        let newString = NSMutableAttributedString()
        
        for surface in surfaces {
            let coloredSurface = NSMutableAttributedString(string: surface)
            let spacerString = NSAttributedString(string: ", ")
            let color = colorFromSurfaces(surface)
            coloredSurface.addAttribute(NSForegroundColorAttributeName, value: color, range: NSRange(location: 0, length: surface.characters.count))
            
            newString.appendAttributedString(coloredSurface)
            if surface != surfaces.last {
                newString.appendAttributedString(spacerString)
            }
        }
        
        // Annotation
        let annotation = ParkAnnotation(coordinate: point)
        annotation.titleLabelText = parkName
        annotation.subtitleLabelText = newString
        annotation.color = gradientFromDifficulty(difficulty, forAnnotation: true)
        mapView.addAnnotation(annotation)
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
        if let annotation = annotation as? ParkAnnotation
        {
            guard let view = mapView.dequeueReusableAnnotationViewWithIdentifier("ParkPin") else
            {
//                let view = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "ParkPin")
				let view = ParkPinView(annotation: annotation, reuseIdentifier: "ParkPin")
                view.canShowCallout = false
                view.pinTintColor = annotation.color
                return view
            }
      
            return view
        } else {
            return nil
        }
    }
	
	func hitSelector(sender: ParkAnnotationView)
	{
		//this is a virtual function; please over-write it!
		assert(false)
	}
	
    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView)
    {
        if let _ = view.annotation as? MKUserLocation
        {
            return
        }
        
        if let parkAnnotation = view.annotation as? ParkAnnotation
        {
            let parkView = (NSBundle.mainBundle()).loadNibNamed("ParkAnnotationView", owner: self, options: nil)[0] as! ParkAnnotationView
			
			//format the parkview
			parkView.layer.cornerRadius = 20
			parkView.layer.borderWidth = 2
			parkView.layer.borderColor = UIColor(red: 0.2, green: 0.65, blue: 0.96, alpha: 1).CGColor
			parkView.layer.backgroundColor = UIColor(hue: 0, saturation: 0, brightness: 1, alpha: 0.75).CGColor
            parkView.titleLabel.text = parkAnnotation.titleLabelText
            parkView.subtitleLabel.attributedText = parkAnnotation.subtitleLabelText
			
            parkView.center = CGPointMake(view.bounds.size.width / 2, -parkView.bounds.size.height*0.52)
            view.addSubview(parkView)
			
			parkView.addTarget(self, action: #selector(hitSelector(_:)), forControlEvents: UIControlEvents.TouchUpInside)
            
            if let title = parkAnnotation.titleLabelText {
                showPark(parkName: title, withAnnotation: false)
            }
        }
    }
    
    func mapView(mapView: MKMapView, didDeselectAnnotationView view: MKAnnotationView) {
//        if view.isKindOfClass(MKAnnotationView)
//        {
//            for subview in view.subviews
//            {
//                subview.removeFromSuperview()
//            }
//        }
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
        //black is "bad" surfaces
        case "grass": fallthrough
        case "soil": return UIColor(hue: 0.33, saturation: 1, brightness: 0.7, alpha: 1)
        case "bark": fallthrough
		case "gravel": return UIColor(hue: 0.66, saturation: 0.1, brightness: 0.6, alpha: 1)
        case "stairs": fallthrough
        case "check steps": return UIColor(hue: 0.0, saturation: 1, brightness: 0.65, alpha: 1)
            
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
            difficulty = abs(difficulty - 5) < abs(difficulty - 10) ? 4 : 10;
        }
        else
        {
            difficulty = abs(difficulty - 5) < difficulty ? 4 : 0;
        }
    }
    
    let green:CGFloat = 1.0 / 3.0;
    return UIColor(hue: green * CGFloat(difficulty) * 0.1, saturation: 1.0, brightness: 1.0, alpha: 1)
}