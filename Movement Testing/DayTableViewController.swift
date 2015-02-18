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
    var rawLocationAccuracy = [NSArray]()
    
    var smoothedSpeed = [Double]()
    
    //let speedThresholdVehicle: Double = 30
    let speedThresholdCycling: Double = 30
    let speedThresholdRunning: Double = 20
    let speedThresholdWalking: Double = 10
    let speedThresholdInactive: Double = 4
    
    let distanceThresholdForSignificantMovement: Double = 100
    
    var todaysEvents = [NSArray]()
    
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
                    let accuracy = [result.valueForKey("accuracyH") as Double, result.valueForKey("accuracyV") as Double]
                    rawLocation.append(coordinates)
                    rawLocationAccuracy.append(accuracy)
                    
                    println("\(rawDates[rawDates.count - 1]) - \(accuracy)")
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
                    
                    rawMagnetometer.append(-999)
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
                    
                    rawAccelerometer.append(-999)
                }
                
            }
        }
        
        
        
        smoothedSpeed = smoothSpeedData(rawLocation, smoothSize: 3)
        
        rawMagnetometer = cleanRawData(rawMagnetometer)
        rawAccelerometer = cleanRawData(rawAccelerometer)

        var binaryMagnetometer = convertToBinary(rawMagnetometer, threshold: movementThreshold)
        var binaryAccelerometer = convertToBinary(rawAccelerometer, threshold: accelerationThreshold)
        var binarySpeed = convertToBinary(smoothedSpeed, threshold: speedThreshold)

        var binaryIsActive = [Double]()
        
        for var i = 0; i < rawDates.count; i++ {
            
            let bMagnet = binaryMagnetometer[i]
            let bAcceler = binaryAccelerometer[i]
            let bSpeed = binarySpeed[i]
            
            if bMagnet + bAcceler + bSpeed > 1 {
                
                binaryIsActive.append(1)
            }
            else {
                
                binaryIsActive.append(0)
            }
            
        }
        
        var smoothedBinaryIsActive = smoothData(binaryIsActive, size: 3)
        
        todaysEvents = extractActivityEvents(smoothedBinaryIsActive)
        
        //println("time, rawMag, rawAcc, speed, IsActive, Accuracy")
        
        for var i = 0; i < rawDates.count; i++ {
            
            //println("\(rawFriendlyDates[i]), \(rawMagnetometer[i]), \(rawAccelerometer[i]), \(smoothedSpeed[i]), \(binaryIsActive[i]), \(rawLocationAccuracy[i][0])")
        }
    }
    
    
    func cleanRawData(var data: [Double]) -> [Double]{
        
        let indexCount = data.count
        
        for var i = 0; i < indexCount; i++ {
            
            if data[i] == -999 {
                
                if i < (indexCount - 1) {
                    
                    let adjustedValue: Double = (data[i - 1] + data[i + 1]) / 2
                    
                    data[i] = adjustedValue
                }
                else {
                    data[i] = data[i - 1]
                }
            }
        }
        return data
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
    
    func extractActivityEvents(var data: [Double]) -> [NSArray] {
 
        dateFormatter.dateFormat = "HH:mm"
        
        var results = [NSMutableArray]()
        var speedTracker = [Double]()
        var locationTracker = [NSArray]()
        var isActiveNow: Bool = false
        var wasActiveBefore: Bool = false
        var activityType: NSString = ""
        var timeEndString: NSString = ""
        var timeStartString: NSString = ""
        
        //var indexMax = data.count

        for var i = 1; i < data.count - 1; i++ {

            let intervalBefore = rawDates[i].timeIntervalSinceDate(rawDates[i - 1])
            let timeStart = rawDates[i].dateByAddingTimeInterval(intervalBefore * 0.4 * -1)
            
            var counter = 0 // Reset counter

            if data[i] > 0.4 {
                
                isActiveNow = true

                while data[i] > 0.4 && i < data.count - 1 {
                    
                    locationTracker.append([rawLocation[i][0], rawLocation[i][1]])
                    
                    //println("i = \(i) - raw lat: \(rawLocation[i][0]) raw long: \(rawLocation[i][1])")
                
                    speedTracker.append(smoothedSpeed[i])
                    
                    i++
                    
                    counter++
                }
            }
            else {
                
                isActiveNow = false

                while data[i] <= 0.4 && i < data.count - 1 {
                    
                    locationTracker.append([rawLocation[i][0], rawLocation[i][1]])
                    
                    //println("i = \(i) - raw lat: \(rawLocation[i][0]) raw long: \(rawLocation[i][1])")
                    
                    speedTracker.append(smoothedSpeed[i])
                    
                    i++
                    
                    counter++
                }
            }
            
            let intervalAfter = rawDates[i + 1].timeIntervalSinceDate(rawDates[i])
            let timeEnd = rawDates[i].dateByAddingTimeInterval(intervalAfter * 0.4)
            
            let interval = timeEnd.timeIntervalSinceDate(timeStart)
            
            timeStartString = dateFormatter.stringFromDate(timeStart)
            timeEndString = dateFormatter.stringFromDate(timeEnd)
            
            // Determine activity type by analysing speed pattern
            
            if speedTracker.count < 4 {
                
                // Pad speed tracking array for better speed accuray
                speedTracker.append(smoothedSpeed[i + 1])
                speedTracker.insert(smoothedSpeed[i - counter - 1], atIndex: 0)
            }
            
            speedTracker = removeHighLow(speedTracker)
            let speedMedian = round(arrayMedian(speedTracker) * 10) / 10
            activityType = getActivityType(speedMedian)
            
            if activityType == "inactive" {
                isActiveNow = false
            }
            
            var ignoreEvent = false
            var distanceMax: Double = 0
            let rc = results.count
            
            if rc > 0 {
                
                var distanceArray = [Double]()

                let centerCoordinatesPreviousLocation = centerCoordinates(results[rc - 1][5] as [NSArray])

                for var k = 0; k < locationTracker.count; k++ {
                    
                    let distance = calculateDistance(centerCoordinatesPreviousLocation, end: locationTracker[k])
                    distanceArray.append(distance)
               }

                distanceMax = arrayMedian(distanceArray)

                if isActiveNow && !wasActiveBefore && interval < 150 {
                    println("condition0")
                    ignoreEvent = true
                }
                
                if isActiveNow && !wasActiveBefore && distanceMax < distanceThresholdForSignificantMovement {
                    println("condition1")
                    ignoreEvent = true
                }
                
                if !isActiveNow && !wasActiveBefore {
                    println("condition2")
                    println("ALERT: find out why I'm here")
                    ignoreEvent = true
                }
                
                if locationTracker.count == 1 {
                    println("condition3")
                   ignoreEvent = true
                }
                
                if distanceMax < distanceThresholdForSignificantMovement {
                    println("condition4")
                    //ignoreEvent = true
                }
            }
            
            println("\(timeStartString) - \(timeEndString): \(activityType.uppercaseString) \(speedMedian)kph")
            
            if ignoreEvent {

                results[rc - 1][1] = timeEndString  // Update the end time of previous results record
                
                var locationTrackerPrevious: [NSArray] = results[rc - 1][5] as [NSArray]
                
                for var k = 0; k < locationTracker.count; k++ {
                    
                    locationTrackerPrevious.append(locationTracker[k])
                }
                results[rc - 1][5] = locationTrackerPrevious
            }
            else {
                
                // Add before and after coordinates to location tracker
                locationTracker.append([rawLocation[i + 1][0], rawLocation[i + 1][1]])
                locationTracker.insert([rawLocation[i - counter - 1][0], rawLocation[i - counter - 1][1]], atIndex: 0)

                results.append([timeStartString, timeEndString, interval, activityType.uppercaseString, speedMedian, locationTracker])
            }
            wasActiveBefore = isActiveNow
            speedTracker.removeAll()
            locationTracker.removeAll()
        }

        return results
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
    
    func arrayMedian(var data: [Double]) -> Double {
        
        var median: Double = data[0]
        var indexCount = data.count
        
        data.sort{$0 < $1}
        
        if indexCount > 1 {
            
            median = data[(Int(indexCount / 2))]
        }
        
        return median
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
        var removeArray = [NSInteger]()
        let z = Int((smoothSize - 1) / 2)
        let lowerBound = z
        let upperBound = data.count - z

        for var i = lowerBound; i < upperBound; i++ {
            
            let latStart = data[i - z][0] as Double
            let lngStart = data[i - z][1] as Double
            let timeStart = rawDates[i]
            let latEnd = data[i + z][0] as Double
            let lngEnd = data[i + z][1] as Double
            let timeEnd = rawDates[i + z]
            
            let distance = calculateDistance([latStart, lngStart], end: [latEnd, lngEnd])
            let interval = timeEnd.timeIntervalSinceDate(timeStart)
            let speedie = (distance / 1000) / (interval / 3600)
            let speed = round(speedie * 10) / 10
            
            if interval < 15 {
                
                println("interval:\(round(interval))\tDist:\(round(distance))\tSP:\(round(speed))")
            }
            
            // Do not append to result is speed value is deemed inaccurate
            if speed > 30 && interval < 12 {
                
                removeArray.append(i)
            }
            else {
                results.append(speed)
            }
        }
        
        // Pad data so that it matches other datasets
        let indexCount = results.count
        
        results.insert(results[0], atIndex: 0)
        results.append(results[indexCount - 2])
        
        // Remove matching record for inaccurate speed data

        for var i = 0; i < removeArray.count; i++ {

            rawDates.removeAtIndex(removeArray[i] - i)
            rawFriendlyDates.removeAtIndex(removeArray[i] - i)
            rawLocation.removeAtIndex(removeArray[i] - i)
            rawLocationAccuracy.removeAtIndex(removeArray[i] - i)
            rawMagnetometer.removeAtIndex(removeArray[i] - i)
            rawAccelerometer.removeAtIndex(removeArray[i] - i)
        }
        return results
    }
    
    
    func calculateDistance(start: NSArray, end: NSArray) -> Double {
        
        let latStart = start[0] as Double
        let lngStart = start[1] as Double
        let latEnd = end[0] as Double
        let lngEnd = end[1] as Double
        
        var coordinateStart: CLLocationCoordinate2D = CLLocationCoordinate2DMake(latStart, lngStart)
        var coordinateEnd: CLLocationCoordinate2D = CLLocationCoordinate2DMake(latEnd, lngEnd)
        
        var locationStart: CLLocation = CLLocation(coordinate: coordinateStart, altitude: 0, horizontalAccuracy: 10, verticalAccuracy: 10, timestamp: NSDate())
        var locationEnd: CLLocation = CLLocation(coordinate: coordinateEnd, altitude: 0, horizontalAccuracy: 10, verticalAccuracy: 10, timestamp: NSDate())
        
        let distance = locationStart.distanceFromLocation(locationEnd)
        
        return distance
    }
    
    func centerCoordinates(data: [NSArray]) -> [Double] {
//println("center point data: \(data)")
        // Calculate the center point of all coordinates
        
        let pi: Double = 22/7
        var x: Double = 0
        var y: Double = 0
        var z: Double = 0
        
        let indexDbl: Double = Double(data.count)
        
        for var i = 0; i < data.count; i++ {
            
            let latStart: Double = data[i][0] as Double
            let lngStart: Double = data[i][1] as Double
            
            let latRad = latStart * pi / 180
            let lngRad = lngStart * pi / 180
            
            x += cos(latRad) * cos(lngRad)
            y += cos(latRad) * sin(lngRad)
            z += sin(latRad)
        }
        
        x = x / indexDbl
        y = y / indexDbl
        z = z / indexDbl
        
        let lngCenter = atan2(y, x) * 180 / pi
        let hyp = sqrt(x * x + y * y)
        let latCenter = atan2(z, hyp) * 180 / pi
        
        return [latCenter, lngCenter]
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
        
        let start = todaysEvents[indexPath.row][0] as NSString
        let end = todaysEvents[indexPath.row][1] as NSString
        let activity = todaysEvents[indexPath.row][3] as NSString
        let speed = todaysEvents[indexPath.row][4] as Double

        cell.textLabel?.text = "\(start) - \(end) \(activity) (\(speed)kph)"
        
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

                mapVC.dataRoute = todaysEvents[selectedIndex][5] as [NSArray]
            }
        }
    }
}
