//
//  ViewController.swift
//  Seattle Trails
//
//  Created by Eric Mentele on 3/18/16.
//  Copyright © 2016 seatrails. All rights reserved.
//

import UIKit
import MapKit

class ViewController: UIViewController
{

    @IBOutlet weak var mapView: MKMapView!
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        let coordinate = CLLocationCoordinate2D(latitude: 47.6190648, longitude: -122.3391903)
        let region = MKCoordinateRegionMakeWithDistance(coordinate, 25000, 25000)
        mapView.setRegion(region, animated: true)
        plotLine()
    }
    
    @IBAction func navButtonPressed(sender: UIButton)
    {
        
    }
    
    func plotPoint()
    {
        let annotation = MKPointAnnotation()
        
        let coordinate = CLLocationCoordinate2D(latitude: 47.58144035069734, longitude: -122.38291159311778)
        
        annotation.coordinate = coordinate
        
        mapView.addAnnotation(annotation)
        
    }
    func plotLine()
    {
        // Not Showing Yet

        let coordinateA = CLLocationCoordinate2D(latitude: 47.58144035069734, longitude: -122.38291159311778)
        let coordinateB = CLLocationCoordinate2D(latitude: 60.08144035069734, longitude: -100.98291159311778)
        let coordinateC = CLLocationCoordinate2D(latitude: 60.08144035069734, longitude: -100.98291159311778)
        let coordinateD = CLLocationCoordinate2D(latitude: 60.08144035069734, longitude: -100.98291159311778)
        
        var coordinates: [CLLocationCoordinate2D] = [CLLocationCoordinate2D]()
        coordinates.append(coordinateA)
        coordinates.append(coordinateB)
        coordinates.append(coordinateC)
        coordinates.append(coordinateD)
        let line = MKPolyline(coordinates: &coordinates, count: 4)
        mapView.addOverlay(line)
    }
}

