//
//  ViewController.swift
//  Seattle Trails
//
//  Created by Eric Mentele on 3/18/16.
//  Copyright © 2016 seatrails. All rights reserved.
//

import UIKit
import MapKit

class ViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate
{

    @IBOutlet weak var mapView: MKMapView!
    var trails = [Trail]()
    @IBOutlet weak var locationButtonBackground: UIImageView!
    var parkNames = [String]()
    var locationManager: CLLocationManager?
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var imageDamper: UIImageView!
    override func viewDidLoad()
    {
        super.viewDidLoad()
        mapView.delegate = self
        
        locationButtonBackground.layer.cornerRadius = locationButtonBackground.frame.width / 2
        let coordinate = CLLocationCoordinate2D(latitude: 47.6190648, longitude: -122.3391903)
        let region = MKCoordinateRegionMakeWithDistance(coordinate, 25000, 25000)
        mapView.setRegion(region, animated: true)
        socrataService.getAllTrails()
            { (trails) in
                if let trails = trails
                {
                    self.trails = trails
                    self.plotAllPoints()
                    self.imageDamper.userInteractionEnabled = false
                    self.imageDamper.hidden = true
                    self.activityIndicator.stopAnimating()
                }
                else
                {
                    print("Something Bad Happened")
                }
        }
        
        locationManager = CLLocationManager()
        locationManager?.delegate = self
        locationManager?.desiredAccuracy = kCLLocationAccuracyHundredMeters
        locationManager?.requestWhenInUseAuthorization()
        locationManager?.startUpdatingLocation()
        mapView.showsUserLocation = true
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
    
    func plotPoint(point: CLLocationCoordinate2D, text: String, difficulty: String)
    {
        // Only Plot One Point Per Trail
        if parkNames.indexOf(text) >= 0 {
            return
        }
        parkNames.append(text)
        
        // Annotation
        let annotation = MKPointAnnotation()
        annotation.coordinate = point
//        print("\(point.latitude) - \(point.longitude)")
        annotation.title = text
        annotation.subtitle = difficulty
        mapView.addAnnotation(annotation)
    }
    
    func plotLine(trail: Trail)
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
    
    func plotAllPoints()
    {
        var parks = [String : [Trail]]()
        for trail in trails {
            if parks[trail.name] == nil
            {
                parks[trail.name] = [Trail]()
            }
            parks[trail.name]?.append(trail)
//            plotPoint(trail.points[0], text: trail.name)
//            self.plotLine(trail)
        }
        
        for park in parks.keys
        {
            var numGood = 0
            var numBad = 0
            var totalCenter = CLLocationCoordinate2D(latitude: 0, longitude: 0)
            for trail in parks[park]!
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
                print(center)
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
            
            plotPoint(totalCenter, text: park, difficulty: difficulty)
        }
    }
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView?
    {
        let view = MKPinAnnotationView(annotation: annotation, reuseIdentifier: nil)
        if let subtitle = annotation.subtitle {
            if subtitle == "Accessible" {
                view.pinTintColor = UIColor(red: 0, green: 0.5, blue: 0, alpha: 1)
            } else {
                view.pinTintColor = UIColor(red: 0.1, green: 0.2, blue: 1, alpha: 1)
            }
        }
        view.canShowCallout = true
        return view
    }
    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView)
    {
        if let title = view.annotation!.title {
			var topRight = CLLocationCoordinate2D(latitude: 999, longitude: 999)
			var bottomLeft = CLLocationCoordinate2D(latitude: -999, longitude: -999)
            for trail in trails {
                if trail.name == title {
                    if (!trail.isDrawn) {
                        plotLine(trail)
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
			
			//zoom in on location
//			let region = MKCoordinateRegionForMapRect(MKMapRect(origin: MKMapPointForCoordinate(topRight), size: MKMapSizeMake(bottomLeft.latitude - topRight.latitude, bottomLeft.longitude - topRight.longitude)))
			let center = CLLocationCoordinate2D(latitude: (topRight.latitude + bottomLeft.latitude) / 2, longitude: (topRight.longitude + bottomLeft.longitude) / 2)
//			let region = MKCoordinateRegionMakeWithDistance(center, bottomLeft.latitude - topRight.latitude, bottomLeft.longitude - topRight.longitude)
			let region = MKCoordinateRegionMake(center, MKCoordinateSpan(latitudeDelta: bottomLeft.latitude - topRight.latitude, longitudeDelta: bottomLeft.longitude - topRight.longitude))
			mapView.setRegion(region, animated: true)
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
}

