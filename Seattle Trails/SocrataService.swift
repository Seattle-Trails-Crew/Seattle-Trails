//
//  SocrataService.swift
//  Seattle Trails
//
//  Created by Theodore Abshire on 3/22/16.
//  Copyright © 2016 seatrails. All rights reserved.
//

import UIKit
import Foundation
import MapKit

let appToken = "o9zqUXd72sDpc0BWNR45Fc1TH"

class SocrataService
{
	//MARK: Network Request Methods
    class func getAllTrails(returnClosure:(([String : Park]?)->()))
	{
		//do network calls
		doRequest(nil, completion: returnClosure)
	}
    
    class func getTrailsInArea(upperLeft:CLLocationCoordinate2D, lowerRight:CLLocationCoordinate2D, returnClosure:(([String : Park]?)->()))
    {
        doRequest("$where=within_box(the_geom, \(upperLeft.latitude), \(upperLeft.longitude), \(lowerRight.latitude), \(lowerRight.longitude))", completion: returnClosure)
    }
	
    private class func doRequest(arguments:String?, completion:([String : Park]?)->())
	{
		//prepare the URL string
		let urlString = "https://data.seattle.gov/resource/vwtx-gvpm.json?$limit=999999999&$$app_token=\(appToken)\(arguments != nil ? "&\(arguments!)" : "")"//&$where=trail_clas==1"
		//TODO: for now, I've disabled the park of the URL string that asks for the trail class; turn that back on later, once we no longer want the filter
		
		if let url = NSURL(string: urlString)
		{
			//prepare the session
//			let session = NSURLSession(configuration: NSURLSessionConfiguration.defaultSessionConfiguration())
			let request = NSMutableURLRequest(URL: url)
			request.HTTPMethod = "GET"
			
			let manager = AFURLSessionManager.init(sessionConfiguration: NSURLSessionConfiguration.defaultSessionConfiguration())
			
			let dataTask = manager.dataTaskWithRequest(request)
			{ (response, responseObject, error) in
//			session.dataTaskWithRequest(request, completionHandler:
//				{ (data, response, error) in
				if let error = error
				{
					//you didn't get the data, so output an error
					NSOperationQueue.mainQueue().addOperationWithBlock()
					{
						NSLog("ERROR: " + error.description)
						completion(nil)
					}
				}
				else if let json = responseObject as? [[String : AnyObject]]
				{
					//you got the data, serialize and return it
					let result = serializeInner(json)
					NSOperationQueue.mainQueue().addOperationWithBlock()
					{
						completion(result)
					}
				}
				else
				{
					NSOperationQueue.mainQueue().addOperationWithBlock()
					{
						print("UNKNOWN ERROR")
						completion(nil)
					}
				}
			}
			dataTask.resume()
//			}).resume()
		}
	}
    
    //MARK: JSON serialization
	//this function is unnecessary now, AFNetworking does the serialization for us
//    private class func serialize(data:NSData) -> [String : Park]?
//    {
//        do
//        {
//            if let json = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.MutableContainers) as? [[String : AnyObject]]
//            {
//                return serializeInner(json)
//            }
//        }
//        catch _
//        {
//        }
//        NSLog("ERROR: failed to load trails!");
//        return nil
//    }
	
    private class func serializeInner(json:[[String : AnyObject]]) -> [String : Park]
    {
        var trails = [String : [Trail]]()
        
        for dict in json
        {
            //parse this JSON dictionary into a trail
            let canopy = dict["canopy"] as? String
            let condition = dict["condition"] as? String
            let gradeType = dict["grade_type"] as? String
            let surfaceType = dict["surface_ty"] as? String
            
            if let pmaid = dict["pmaid"] as? String, let trailNum = dict["trail_num"] as? String, let name = dict["pma_name"] as? String, let length = dict["gis_length"] as? String, let geom = dict["the_geom"] as? [String:AnyObject]
            {
                let trail = Trail()
                trail.canopy = canopy
                trail.condition = condition
                trail.gradeType = gradeType
                trail.surfaceType = surfaceType
                trail.name = name
                trail.length = (length as NSString).floatValue
                trail.trailNum = (trailNum as NSString).integerValue
                trail.pmaid = (pmaid as NSString).integerValue
				
				//TODO: remove this once we remove filtering
				trail.official = (dict["trail_clas"] as! NSString).intValue == 1
                
                
                if let points = geom["coordinates"] as? [[Double]]
                {
                    for point in points
                    {
                        let location = CLLocationCoordinate2D(latitude: point[1], longitude: point[0])
                        trail.points.append(location)
                    }
                    
                    if trail.points.count > 0
                    {
                        trail.startPoint = trail.points[0]
                        if trails[trail.name] == nil
						{
                            trails[trail.name] = [Trail]()
                            trails[trail.name]?.append(trail)
                        } else {
                            trails[trail.name]?.append(trail)
                        }
                    }
                    else
                    {
                        NSLog("ERROR: trail " + name + " has no points!");
                    }
                }
                else
                {
                    NSLog("ERROR: failed to load points on trail " + name + "!");
                }
                
            }
            else
            {
                NSLog("ERROR: failed to load trail!");
            }
        }
		
		//translate the trail dictionaries into parks
		var parks = [String : Park]()
		for (name, tr) in trails
		{
			parks[name] = Park(name: name, trails: tr)
		}
		return parks
    }
    
    //MARK: debug info checking
    class func getCanopyLevels(trails:[Trail]) -> [String]
    {
        var levels = Set<String>()
        
        for trail in trails
        {
            if let canopy = trail.canopy
            {
                levels.insert(canopy)
            }
        }
        
        return Array(levels)
    }
    
    class func getSurfaceTypes(trails:[Trail]) -> [String]
    {
        var levels = Set<String>()
        
        for trail in trails
        {
            if let surfaceType = trail.surfaceType
            {
                levels.insert(surfaceType)
            }
        }
        
        return Array(levels)
    }
    
    class func getGradeTypes(trails:[Trail]) -> [String]
    {
        var levels = Set<String>()
        
        for trail in trails
        {
            if let gradeType = trail.gradeType
            {
                levels.insert(gradeType)
            }
        }
        
        return Array(levels)
    }
}