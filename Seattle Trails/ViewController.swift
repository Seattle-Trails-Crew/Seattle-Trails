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
                    self.plotAllLines()
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
    
    func plotPoint(point: CLLocationCoordinate2D, text: String)
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
        
        mapView.addOverlay(line)
    }
    
    func plotAllLines()
    {
        for trail in trails {
            plotPoint(trail.points[0], text: trail.name)
//            self.plotLine(trail)
        }
    }
    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView)
    {
        print("hi")
        
    }
    func mapView(mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        let rect = mapView.visibleMapRect
        let upLeft = CLLocationCoordinate2D(latitude: MKMapRectGetMinX(rect), longitude: MKMapRectGetMaxY(rect))
        let downRight = CLLocationCoordinate2D(latitude: MKMapRectGetMaxX(rect), longitude: MKMapRectGetMinY(rect))
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

