//
//  Model.swift
//  Seattle Trails
//
//  Created by Theodore Abshire on 3/18/16.
//  Copyright © 2016 seatrails. All rights reserved.
//

import UIKit

class Trail
{
	var points = [CGPoint]();
	var name:String = ""
	var canopy:String = ""
	var condition:String = ""
	var gradeType:String = ""
	var surfaceType:String = ""
	var length:Float = 0
	
	//utility functions
	var center:CGPoint
		{
			var c = CGPoint(x: 0, y: 0)
			for point in points
			{
				c.x += point.x
				c.y += point.y
			}
			c.x /= CGFloat(points.count)
			c.y /= CGFloat(points.count)
			return c
	}
}


class socrataService
{
	class func getNearestTrail(nearestTo:CGPoint, returnClosure:((Trail)->()))
	{
		//TODO: whatever
		getAllTrails(
			{ (all:[Trail]) -> () in
				returnClosure(all[0])
		})
	}
	
	class func getTrailsInArea(area:CGRect, returnClosure:(([Trail])->()))
	{
		//TODO: whatever
		getAllTrails(returnClosure)
	}
	
	class func getAllTrails(returnClosure:(([Trail])->()))
	{
		//TODO: do network calls
		
		//for now, make dummy data
		var dummy = Trail()
		dummy.name = "TRAIL"
		dummy.canopy = "High"
		dummy.condition = "Good"
		dummy.gradeType = "Flat"
		dummy.surfaceType = "Gravel"
		dummy.length = 1337
		dummy.points.append(CGPoint(x:-122.303, y:47.67))
		
		returnClosure([dummy])
	}
}