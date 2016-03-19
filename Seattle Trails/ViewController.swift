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
        plotPoint()
    }
    
    func plotPoint()
    {
        let annotation = MKPointAnnotation()
        
        let coordinate = CLLocationCoordinate2D(latitude: 47.58144035069734, longitude: -122.38291159311778)
        
        annotation.coordinate = coordinate
        
        mapView.addAnnotation(annotation)
        
    }
}

