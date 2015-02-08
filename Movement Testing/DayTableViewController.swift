//
//  DayTableViewController.swift
//  Movement Testing
//
//  Created by Matthew Lewis on 25/01/2015.
//  Copyright (c) 2015 iD Foundry. All rights reserved.
//

import UIKit
import CoreData
import CoreLocation

class DayTableViewController: UITableViewController {

    let dateFormatter = NSDateFormatter()

    var dateDay: NSDate = NSDate()
    
    let movementThreshold: Double = 5
    let smoothedMovementThreshold: Double = 0.5
    let accelerationThreshold: Double = 1.9
    let speedThreshold: Double = 4
    
    var rawDates = [NSDate]()
    var rawFriendlyDates = [NSString]()
    var rawLocation = [NSArray]()
    var rawMagnetometer = [Double]()
    var rawAccelerometer = [Double]()
    
    var smoothedSpeed = [Double]()
    
    //let speedThresholdVehicle: Double = 30
    let speedThresholdCycling: Double = 30
    let speedThresholdRunning: Double = 20
    let speedThresholdWalking: Double = 10
    let speedThresholdInactive: Double = 2
    
    var todaysEvents = [NSString]()
    
    var eventLocations = [NSArray]()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        dateFormatter.dateFormat = "HH:mm"
        
        var error : NSError?

        // Estabish core data connection
        
        let appDel:AppDelegate = UIApplication.sharedApplication().delegate as AppDelegate
        let context:NSManagedObjectContext = appDel.managedObjectContext!
        
        var query = NSFetchRequest(entityName: "LocationData")
        query.predicate = NSPredicate(format: "dateShort = %@", dateDay)
        query.returnsObjectsAsFaults = false
        query.sortDescriptors = [NSSortDescriptor(key: "dateRecord", ascending: true)]
        
        // Collect all location data for today and populate rawDates and rawLocation arrays
        
        if let results = context.executeFetchRequest(query, error: &error) {
            
            if results.count > 0 {
                
                for result in results {
                    
                    rawDates.append(result.valueForKey("dateRecord") as NSDate)
                    
                    rawFriendlyDates.append(dateFormatter.stringFromDate(result.valueForKey("dateRecord") as NSDate))
                    
                    let coordinates = [result.valueForKey("lat") as Double, result.valueForKey("long") as Double]
                    
                    rawLocation.append(coordinates)
                }
            }
            else {
                
                println("No data exists for today: \(dateDay)")
            }
        }
        
        // Collect matching magnetometer data and populate rawMagnetometer array
        
        query = NSFetchRequest(entityName: "MagData")
        query.sortDescriptors = [NSSortDescriptor(key: "dateRecord", ascending: true)]
        
        for var i = 0; i < rawDates.count; i++ {
            
            query.predicate = NSPredicate(format: "dateRecord = %@", rawDates[i])

            if let results = context.executeFetchRequest(query, error: &error) {
                
                if results.count > 1 {
                    
                    println("Found \(results.count) records for the same date \(rawDates[i])")
                }
                
                if results.count > 0 {
                    
                    for result in results {
                        
                        rawMagnetometer.append(result.valueForKey("delta") as Double)
                        
                        break
                    }
                }
                else {
                    
                    println("No matching magnetometer record found for date: \(rawDates[i])")
                    
                    rawMagnetometer.append(movementThreshold)
                }
                
            }
        }
        
        // Collect matching accelerometer data and populate rawAccelerometer array
        
        query = NSFetchRequest(entityName: "AccData")
        query.sortDescriptors = [NSSortDescriptor(key: "dateRecord", ascending: true)]
        
        for var i = 0; i < rawDates.count; i++ {
            
            query.predicate = NSPredicate(format: "dateRecord = %@", rawDates[i])
            
            if let results = context.executeFetchRequest(query, error: &error) {
                
                if results.count > 1 {
                    
                    println("Found \(results.count) records for the same date \(rawDates[i])")
                }
                
                if results.count > 0 {
                    
                    for result in results {
                        
                        rawAccelerometer.append(result.valueForKey("value") as Double)
                        
                        break
                    }
                }
                else {
                    
                    println("No matching accelerometer record found for date: \(rawDates[i])")
                    
                    rawAccelerometer.append(accelerationThreshold)
                }
                
            }
        }
        
        smoothedSpeed = smoothSpeedData(rawLocation, smoothSize: 3)

        var binaryMagnetometer = convertToBinary(rawMagnetometer, threshold: movementThreshold)
        var binaryAccelerometer = convertToBinary(rawAccelerometer, threshold: accelerationThreshold)
        var binarySpeed = convertToBinary(smoothedSpeed, threshold: speedThreshold)
        
        var binaryIsActive = [Double]()
        
        //println("speed: \(smoothedSpeed.count) mag: \(binaryMagnetometer.count) acc: \(binaryAccelerometer.count) dates: \(rawDates.count)")
        
        for var i = 0; i < rawDates.count; i++ {
            
            let bMagnet = binaryMagnetometer[i]
            let bAcceler = binaryAccelerometer[i]
            let bSpeed = binarySpeed[i]
            
            if bMagnet + bAcceler + bSpeed > 2 {
                
                binaryIsActive.append(1)
            }
            else {
                
                binaryIsActive.append(0)
            }
            
        }
        
        var smoothedBinaryIsActive = smoothData(binaryIsActive, size: 3)
        
        todaysEvents = extractActivityEvents(smoothedBinaryIsActive)
        
        // Insert padding so smooth can be conducted on entire array
        
        //binaryMagnetometer.insert(0.5, atIndex: 0)
        //binaryMagnetometer.insert(0.5, atIndex: 0)
        //binaryMagnetometer.append(0.5)
        //binaryMagnetometer.append(0.5)
        //binaryMagnetometer.append(0.5)
        
        //var smoothedBinaryMagnetometer = smoothData(binaryMagnetometer, size: 5)
        
        // Insert padding so smooth can be conducted on entire array
        
        //binaryAccelerometer.insert(0.3, atIndex: 0)
        //binaryAccelerometer.append(0.3)
        //binaryAccelerometer.append(0.3)
        
        //println(smoothedBinaryMagnetometer)
        
        //smoothedBinaryMagnetometer = convertToBinary(smoothedBinaryMagnetometer, threshold: smoothedMovementThreshold)
        
        //println(smoothedBinaryMagnetometer)
        
        //println(smoothedSpeed)
        
        //println(todayEvents)
        
        //println(smoothedBinaryAccelerometer)
        
        //println(rawAccelerometer)

        //processSmoothedData(smoothedData, timedata: timeTracker)
        
        //setActivityBands()
        
        println("time, binaryMag, rawAcc, speed, IsActive")
        
        for var i = 0; i < rawDates.count; i++ {
            
            //println("\(rawFriendlyDates[i]), \(binaryMagnetometer[i]), \(rawAccelerometer[i]), \(smoothedSpeed[i]), \(binaryIsActive[i])")
        }
    }
    
    func convertToBinary(data: [Double], threshold: Double) -> [Double] {
    
        var dataBinary = [Double]()
        
        for var i = 0; i < data.count; i++ {
            
            var movement: Double = 0
            
            if data[i] > threshold {
                
                movement = 1
            }
            
            dataBinary.append(movement)
        }
    
        return dataBinary
    }
    
    func smoothData(var data: [Double], size: NSInteger) -> [Double] {
        
        var dataSmoothed = [Double]()
        
        let indexCount = data.count
        let lower = (size - 1) / 2
        let upper = lower + 1
        
        for var i = lower; i < (indexCount - upper); i++ {

            var smoothTotal: Double = 0
            
            for var j = (i - lower); j < (i + upper); j++ {

                smoothTotal += (data[j] as Double)
            }
            
            let sizeDbl = Double(size)
            
            dataSmoothed.append(smoothTotal / sizeDbl)
        }
        
        return dataSmoothed
    }
    
    func extractActivityEvents(var data: [Double]) -> [NSString] {
 
        dateFormatter.dateFormat = "HH:mm"
        
        var result = [NSString]()
        var speedTracker = [Double]()
        var locationTracker = [NSArray]()
        
        var timeEndString: NSString = ""
        var timeStartString: NSString = ""
        
        //var indexMax = data.count
        
        for var i = 1; i < data.count - 1; i++ {
            
            var counter = 0 // Reset counter

            if data[i] > 0.4 {

                let intervalBefore = rawDates[i].timeIntervalSinceDate(rawDates[i - 1])
                let timeStart = rawDates[i].dateByAddingTimeInterval(intervalBefore * 0.4 * -1)

                while data[i] > 0.4 && i < data.count - 1 {
                    
                    locationTracker.append([rawLocation[i][0], rawLocation[i][1]])
                
                    speedTracker.append(smoothedSpeed[i])
                    
                    i++
                    
                    counter++
                }
                
                let intervalAfter = rawDates[i + 1].timeIntervalSinceDate(rawDates[i])
                let timeEnd = rawDates[i].dateByAddingTimeInterval(intervalAfter * 0.4)
                
                timeStartString = dateFormatter.stringFromDate(timeStart)
                timeEndString = dateFormatter.stringFromDate(timeEnd)
            }
            else {
                
                var counter = 0 // Reset counter
                
                let intervalBefore = rawDates[i].timeIntervalSinceDate(rawDates[i - 1])
                let timeStart = rawDates[i].dateByAddingTimeInterval(intervalBefore * 0.4 * -1)
                
                while data[i] <= 0.4 && i < data.count - 1 {
                    
                    locationTracker.append([rawLocation[i][0], rawLocation[i][1]])
                    
                    speedTracker.append(smoothedSpeed[i])
                    
                    i++
                    
                    counter++
                }
                
                let intervalAfter = rawDates[i + 1].timeIntervalSinceDate(rawDates[i])
                let timeEnd = rawDates[i].dateByAddingTimeInterval(intervalAfter * 0.4)
                
                timeStartString = dateFormatter.stringFromDate(timeStart)
                timeEndString = dateFormatter.stringFromDate(timeEnd)
            }
            
            if speedTracker.count < 4 {
                
                // Pad speed tracking array for better speed accuray
                
                speedTracker.append(smoothedSpeed[i + 1])
                
                speedTracker.insert(smoothedSpeed[i - counter - 1], atIndex: 0)
            }
            
            // Add before and after coordinates to location tracker
            
            locationTracker.append([rawLocation[i + 1][0], rawLocation[i + 1][1]])
            
            locationTracker.insert([rawLocation[i - counter - 1][0], rawLocation[i - counter - 1][1]], atIndex: 0)
            
            println(speedTracker)
            
            speedTracker = removeHighLow(speedTracker)
            
            let speedAverage = round(arrayAverage(speedTracker) * 10) / 10
            
            let activityType = getActivityType(speedAverage)
            
            println("\(timeStartString) - \(timeEndString): \(activityType.uppercaseString) \(speedAverage)kph")
            
            result.append("\(timeStartString) - \(timeEndString): \(activityType.uppercaseString) \(speedAverage)kph")
            
            eventLocations.append(locationTracker)
            
            speedTracker.removeAll()
            locationTracker.removeAll()
        }

        return result
    }
    
    func removeHighLow(var data: [Double]) -> [Double] {
        
        var low: Double = data[0]
        var high: Double = 0
        var lowIndex: NSInteger = 0
        var highIndex: NSInteger = 0
        
        if data.count > 2 {
            
            for var i = 0; i < data.count; i++ {
                
                if data[i] > high {
                    
                    high = data[i]
                    highIndex = i
                }
            }
            
            data.removeAtIndex(highIndex)

            for var i = 0; i < data.count; i++ {
                
                if data[i] < low {
                    
                    low = data[i]
                    lowIndex = i
                }
            }
            
            data.removeAtIndex(lowIndex)
        }
        
        return data
    }
    
    func arrayAverage(data: [Double]) -> Double {
        
        var total: Double = 0
        var indexCount = data.count
        
        for var i = 0; i < indexCount; i++ {
            
            total += data[i]
        }
        
        return total / Double(indexCount)
    }
    
    func getActivityType(speed: Double) -> NSString {
        
        var result: NSString = "unknown"
        
        if speed < speedThresholdInactive {
            
            result = "inactive"
        }
        else if speed < speedThresholdWalking {
            
            result = "walking"
        }
        else if speed < speedThresholdRunning {
            
            result = "running"
        }
        else if speed < speedThresholdCycling {
            
            result = "cycling"
        }
        else {
            
            result = "transportation"
        }
        
        return result
    }

    func smoothSpeedData(var data: [NSArray], smoothSize: NSInteger) -> [Double] {
        
        var results = [Double]()
        let z = Int((smoothSize - 1) / 2)

        for var i = z; i < (data.count - z); i++ {
            
            let latStart = data[i - z][0] as Double
            let longStart = data[i - z][1] as Double
            let timeStart = rawDates[i]
            let latEnd = data[i + z][0] as Double
            let longEnd = data[i + z][1] as Double
            let timeEnd = rawDates[i + z]
            
            var coordinateStart: CLLocationCoordinate2D = CLLocationCoordinate2DMake(latStart, longStart)
            var coordinateEnd: CLLocationCoordinate2D = CLLocationCoordinate2DMake(latEnd, longEnd)
            
            var locationStart: CLLocation = CLLocation(coordinate: coordinateStart, altitude: 0, horizontalAccuracy: 10, verticalAccuracy: 10, timestamp: NSDate())
            var locationEnd: CLLocation = CLLocation(coordinate: coordinateEnd, altitude: 0, horizontalAccuracy: 10, verticalAccuracy: 10, timestamp: NSDate())

            let distance = locationStart.distanceFromLocation(locationEnd)
            let interval = timeEnd.timeIntervalSinceDate(timeStart)
            let speedie = (distance / 1000) / (interval / 3600)
            let speed = round(speedie * 10) / 10
            
            results.append(speed)
        }
        
        // Pad data
        let indexCount = results.count
        
        results.insert(results[0], atIndex: 0)
        results.append(results[indexCount - 2])

        return results
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {

        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

        return todaysEvents.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("cell", forIndexPath: indexPath) as UITableViewCell

        cell.textLabel?.text = todaysEvents[indexPath.row]
        
        return cell
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        performSegueWithIdentifier("jumpToMap", sender: self)

    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if segue.identifier == "jumpToMap" {
            
            println("segue")
            
            if let selectedIndex = self.tableView.indexPathForSelectedRow()?.row {
                
                let mapVC: MapViewController = segue.destinationViewController as MapViewController

                mapVC.dataRoute = eventLocations[selectedIndex] as [NSArray]
            }
        }
    }
}
