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
	
	init(name:String, trails:[Trail])
	{
		self.trails = trails
		self.name = name
		
		//calculate the region based on the trails
		var topRight = CLLocationCoordinate2D(latitude: 999, longitude: 999)
		var bottomLeft = CLLocationCoordinate2D(latitude: -999, longitude: -999)
		
		for trail in self.trails
		{
			for point in trail.points
			{
				topRight.latitude = min(topRight.latitude, point.latitude)
				topRight.longitude = min(topRight.longitude, point.longitude)
				bottomLeft.latitude = max(bottomLeft.latitude, point.latitude)
				bottomLeft.longitude = max(bottomLeft.longitude, point.longitude)
			}
		}
		
		let center = CLLocationCoordinate2D(latitude: (topRight.latitude + bottomLeft.latitude) / 2, longitude: (topRight.longitude + bottomLeft.longitude) / 2)
		region = MKCoordinateRegionMake(center, MKCoordinateSpan(latitudeDelta: bottomLeft.latitude - topRight.latitude, longitudeDelta: bottomLeft.longitude - topRight.longitude))
	}
	
	//MARK: utility functions
	
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
	
	var easyPark:Bool
	{
		var easy = 0
		var hard = 0
		for trail in trails
		{
			if trail.easyTrail
			{
				easy += 1
			}
			else
			{
				hard += 1
			}
		}
		return easy > hard
	}
}