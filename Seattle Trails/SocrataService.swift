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
    class func getAllTrails(_ returnClosure:@escaping (([String : Park]?)->()))
    {
        //do network calls
        doRequest(nil, completion: returnClosure)
    }
    
    class func getTrailsInArea(_ upperLeft:CLLocationCoordinate2D, lowerRight:CLLocationCoordinate2D, returnClosure:@escaping (([String : Park]?)->()))
    {
        doRequest("$where=within_box(the_geom, \(upperLeft.latitude), \(upperLeft.longitude), \(lowerRight.latitude), \(lowerRight.longitude))", completion: returnClosure)
    }
    
    fileprivate class func doRequest(_ arguments:String?, completion:@escaping ([String : Park]?)->())
    {
        //prepare the URL string
        let urlString = "https://data.seattle.gov/resource/vwtx-gvpm.json?$limit=999999999&$$app_token=\(appToken)\(arguments != nil ? "&\(arguments!)" : "")"//&$where=trail_clas==1"
        //TODO: for now, I've disabled the park of the URL string that asks for the trail class; turn that back on later, once we no longer want the filter
        
        if let url = URL(string: urlString)
        {
            //prepare the session
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            URLSession(configuration: URLSessionConfiguration.default).dataTask(with: request, completionHandler: { (data, response, error) in
                
                if let error = error
                {
                    //you didn't get the data, so output an error
                    OperationQueue.main.addOperation()
                        {
                            NSLog("ERROR: " + error.localizedDescription)
                            completion(nil)
                    }
                }
                else if let data = data
                {
                    //you got the data, serialize and return it
                    let result = serialize(data)
                    OperationQueue.main.addOperation()
                        {
                            completion(result)
                    }
                }
                else
                {
                    OperationQueue.main.addOperation()
                        {
                            print("UNKNOWN ERROR")
                            completion(nil)
                    }
                }
            }).resume()
        }
    }
    
    //MARK: JSON serialization
    fileprivate class func serialize(_ data:Data) -> [String : Park]?
    {
        do
        {
            if let json = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.mutableContainers) as? [[String : AnyObject]]
            {
                return serializeInner(json)
            }
        }
        catch _
        {
        }
        NSLog("ERROR: failed to load trails!");
        return nil
    }
    
    fileprivate class func serializeInner(_ json:[[String : AnyObject]]) -> [String : Park]
    {
        var trails = [String : [Trail]]()
        
        for dict in json
        {
            //parse this JSON dictionary into a trail
            let canopy = dict["canopy"] as? String
            let condition = dict["condition"] as? String
            let gradeType = dict["grade_type"] as? String
            let percent = dict["grade_perc"] as? String
            var gradePercent: Int? = nil
            if percent != nil {
                gradePercent = Int(percent!)
            }
            let surfaceType = dict["surface_ty"] as? String
            
            if let pmaid = dict["pmaid"] as? String, let trailNum = dict["trail_num"] as? String, let name = dict["pma_name"] as? String, let length = dict["gis_length"] as? String, let geom = dict["the_geom"] as? [String:AnyObject]
            {
                let trail = Trail()
                trail.canopy = canopy
                trail.condition = condition
                trail.gradeType = gradeType
                trail.gradePercent = gradePercent
                trail.surfaceType = surfaceType
                trail.name = name
                trail.length = (length as NSString).floatValue
                trail.trailNum = (trailNum as NSString).integerValue
                trail.pmaid = (pmaid as NSString).integerValue
                
                //TODO: remove this once we remove filtering
                trail.official = (dict["trail_clas"] as! NSString).intValue == 1
                
                
                if let points = geom["coordinates"] as? [[[Double]]]
                {
                    for pointSet in points[0]
                    {
                        let pointY: Double = pointSet[1]
                        let pointX: Double = pointSet[0]
                            
                        let location = CLLocationCoordinate2D(latitude: pointY as Double, longitude: pointX)
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
    class func getCanopyLevels(_ trails:[Trail]) -> [String]
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
    
    class func getSurfaceTypes(_ trails:[Trail]) -> [String]
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
    
    class func getGradeTypes(_ trails:[Trail]) -> [String]
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
