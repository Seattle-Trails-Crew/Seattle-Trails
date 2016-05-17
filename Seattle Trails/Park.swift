//
//  Park.swift
//  Seattle Trails
//
//  Created by Theodore Abshire on 3/29/16.
//  Copyright © 2016 seatrails. All rights reserved.
//

import Foundation
import MapKit

class Park
{
	let name:String
	let region:MKCoordinateRegion
	let trails:[Trail]
    let difficulty: Int
    var surfaces = [String]()
	
	init(name:String, trails:[Trail])
	{
		self.trails = trails
		self.name = name
		
		//calculate the region based on the trails
		var topRight = CLLocationCoordinate2D(latitude: 999, longitude: 999)
		var bottomLeft = CLLocationCoordinate2D(latitude: -999, longitude: -999)
		
        var sumPerc = 0
		for trail in self.trails
		{
			for point in trail.points
			{
				topRight.latitude = min(topRight.latitude, point.latitude)
				topRight.longitude = min(topRight.longitude, point.longitude)
				bottomLeft.latitude = max(bottomLeft.latitude, point.latitude)
				bottomLeft.longitude = max(bottomLeft.longitude, point.longitude)
			}
            if let perc = trail.gradePercent {
                sumPerc += perc
            }
            if let surface = trail.surfaceType {
                if surfaces.indexOf(surface) == nil {
                    surfaces.append(surface)
                }
            }
		}
		
		sumPerc /= self.trails.count
		difficulty = max(min(sumPerc, 10), 0)
		
		let center = CLLocationCoordinate2D(latitude: (topRight.latitude + bottomLeft.latitude) / 2, longitude: (topRight.longitude + bottomLeft.longitude) / 2)
		region = MKCoordinateRegionMake(center, MKCoordinateSpan(latitudeDelta: bottomLeft.latitude - topRight.latitude, longitudeDelta: bottomLeft.longitude - topRight.longitude))
	}
	
	//MARK: utility functions
    var mapRect: MKMapRect {
        let a = MKMapPointForCoordinate(CLLocationCoordinate2DMake(region.center.latitude + region.span.latitudeDelta / 2,
            region.center.longitude - region.span.longitudeDelta / 2))
        let b = MKMapPointForCoordinate(CLLocationCoordinate2DMake(
            region.center.latitude - region.span.latitudeDelta / 2,
            region.center.longitude + region.span.longitudeDelta / 2))
        
        return MKMapRectMake(min(a.x,b.x), min(a.y,b.y), abs(a.x-b.x), abs(a.y-b.y))
    }
    
	var hasOfficial:Bool
	{
		for trail in trails
		{
			if trail.official
			{
				return true
			}
		}
		return false
	}
}