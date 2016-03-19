//
//  ViewController.swift
//  Seattle Trails
//
//  Created by Eric Mentele on 3/18/16.
//  Copyright © 2016 seatrails. All rights reserved.
//

import UIKit
import MapKit

class ViewController: UIViewController, MKMapViewDelegate
{

    @IBOutlet weak var mapView: MKMapView!
    var parkNames = [String]()
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        mapView.delegate = self
        
        let coordinate = CLLocationCoordinate2D(latitude: 47.6190648, longitude: -122.3391903)
        let region = MKCoordinateRegionMakeWithDistance(coordinate, 25000, 25000)
        mapView.setRegion(region, animated: true)
        socrataService.getAllTrails()
            { (trails) in
                if let trails = trails
                {
					//do some utility checks
					print("GRADIENT TYPES:")
					for gradeType in socrataService.getGradeTypes(trails)
					{
						print(gradeType)
					}
					print("SURFACE TYPES:")
					for gradeType in socrataService.getSurfaceTypes(trails)
					{
						print(gradeType)
					}
					print("CANOPY TYPES:")
					for gradeType in socrataService.getCanopyLevels(trails)
					{
						print(gradeType)
					}
					
					for trail in trails {
                        self.plotLine(trail)
                    }
                }
                else
                {
                    print("Something Bad Happened")
                }
        }

//        plotLine()
    }
    
    @IBAction func navButtonPressed(sender: UIButton)
    {
        
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
        plotPoint(trail.points[0], text: trail.name)
        let line = MKPolyline(coordinates: &trail.points, count: trail.points.count)
        
        // Example How To Alter Colors
        if trail.points.count % 2 == 0 {
            line.title = "green"
        } else {
            line.title = "blue"
        }
        
        mapView.addOverlay(line)
    }
    
    func mapView(mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        let rect = mapView.visibleMapRect
        let eastPoint = MKMapPointMake(MKMapRectGetMinX(rect), MKMapRectGetMinY(rect))
        let westPoint = MKMapPointMake(MKMapRectGetMaxX(rect), MKMapRectGetMaxY(rect))
        let distance = MKMetersBetweenMapPoints(eastPoint, westPoint)
        print("Distance: \(distance)")
//        polyLineRenderer?.lineWidth = CGFloat(distance * 0.001)
        let center = mapView.center
        
        // Do query, $where=within_box(..., center.lat, center.long, distance)
    }
    
    func mapView(mapView: MKMapView, rendererForOverlay overlay: MKOverlay) -> MKOverlayRenderer
    {
        // Setting For Line Style
        let polyLineRenderer = MKPolylineRenderer(overlay: overlay)
        if let color = overlay.title {
            if color == "blue" {
                polyLineRenderer.strokeColor = UIColor(red: 0, green: 0, blue: 1, alpha: 1)
            } else if color == "green" {
                polyLineRenderer.strokeColor = UIColor(red: 0, green: 1, blue: 0, alpha: 1)
            }
        }
        polyLineRenderer.lineWidth = 2
        return polyLineRenderer
    }
}

