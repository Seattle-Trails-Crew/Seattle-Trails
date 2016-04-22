//
//  Trail.swift
//  Seattle Trails
//
//  Created by Theodore Abshire on 3/22/16.
//  Copyright © 2016 seatrails. All rights reserved.
//

import Foundation
import MapKit

class Trail
{
	var points = [CLLocationCoordinate2D]();
	var startPoint = CLLocationCoordinate2D(latitude: 0, longitude: 0)
	var name:String = ""
	var canopy:String?
	var condition:String?
	var gradePercent:Int?
	var gradeType:String?
	var surfaceType:String?
	var length:Float = 0
	var trailNum:Int = 0
	var pmaid:Int = 0
	var official:Bool = false
	
	//MARK: utility functions
	
	/// Calculated individual trail center.
	var center:CLLocationCoordinate2D
	{
		//this calculates the center of the trail, by volume of points
		//so it's kind of an approximation
		
		var c = CLLocationCoordinate2D(latitude: 0, longitude: 0)
		
		for point in points
		{
			c.latitude += point.latitude
			c.longitude += point.longitude
		}
		
		c.latitude /= Double(points.count)
		c.longitude /= Double(points.count)
		return c
	}
}