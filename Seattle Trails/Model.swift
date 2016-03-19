//
//  Model.swift
//  Seattle Trails
//
//  Created by Theodore Abshire on 3/18/16.
//  Copyright © 2016 seatrails. All rights reserved.
//

import UIKit
import Foundation

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


let appToken = "o9zqUXd72sDpc0BWNR45Fc1TH"

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
		doRequest()
		{
			NSLog("DONE")
		}
		
		
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
	
	private class func serialize(data:NSData) -> [Trail]?
	{
		do
		{
			if let json = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.MutableContainers) as? [[String : AnyObject]]
			{
				for dict in json
				{
					//TODO: parse this JSON dictionary
					//into a trail
				}
				
				//TODO: return the trails
				return nil
			}
		}
		catch let error
		{
		}
		return nil
	}
	
	private class func doRequest(completion:()->())
	{
		let urlString = "https://data.seattle.gov/resource/vwtx-gvpm.json?$$app_token=" + appToken
		if let url = NSURL(string: urlString)
		{
			let session = NSURLSession(configuration: NSURLSessionConfiguration.defaultSessionConfiguration())
			let request = NSMutableURLRequest(URL: url)
			request.HTTPMethod = "GET"
			
			session.dataTaskWithRequest(request, completionHandler:
			{ (data, response, error) in
				if let error = error
				{
					NSOperationQueue.mainQueue().addOperationWithBlock()
					{
						NSLog("ERROR: " + error.description)
					}
				}
				else if let data = data
				{
					//TODO: note there still might be a problem (ie check to see if there's a "error" argument!)
					
					if let serialized = serialize(data)
					{
						NSOperationQueue.mainQueue().addOperationWithBlock()
						{
							//TODO: return the data
							//this will involve changing that completion
						}
					}
				}
			}).resume()
		}
	}
}