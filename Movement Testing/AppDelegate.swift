//
//  AppDelegate.swift
//  Movement Testing
//
//  Created by Matthew Lewis on 23/01/2015.
//  Copyright (c) 2015 iD Foundry. All rights reserved.
//

import UIKit
import CoreData
import CoreLocation
import CoreMotion

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, CLLocationManagerDelegate {
    
    let locationManager: CLLocationManager = CLLocationManager()
    let motionManager: CMMotionManager = CMMotionManager()

    var timerBackground: NSTimer = NSTimer()
    var timerForeground: NSTimer = NSTimer()
    
    var timerInterval: NSTimeInterval = 0
    var intervalTracker = [Double]()
    var intervalDelegateTracker: NSTimeInterval = 0
    var throttleIsActivated: Bool = false
    var userStatus = "inactive"
    
    var xPrev: Double = 0
    var yPrev: Double = 0
    var zPrev: Double = 0
    
    var bestEffortLocation: CLLocation?
    var userLocation: CLLocation?
    var locationPrev: CLLocation = CLLocation()
    var locationDelegatePrev: CLLocation = CLLocation()
    var timePrev: NSDate = NSDate()
    var timeDelegatePrev: NSDate = NSDate()

    var bgTask: UIBackgroundTaskIdentifier = 0
    
    let inactiveTimer: NSTimeInterval = 60
    let inactiveTimerMax: NSTimeInterval = 300
    let activeTimer: NSTimeInterval = 10
    let activeTimerMax: NSTimeInterval = 90
    
    let magMovementThreshold: Double = 6
    let accMovementThreshold: Double = 1.3
    
    var queueMagDeltas = [Double]() // Not currently in use
    var queueAccValues = [Double]() // Not currently in use
    
    var notes = [NSArray]()

    var window: UIWindow?

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
        timerInterval = inactiveTimer

        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        locationManager.requestAlwaysAuthorization()
        locationManager.activityType = CLActivityType.Other
        locationManager.pausesLocationUpdatesAutomatically = true
        locationManager.delegate = self
        
        if motionManager.magnetometerAvailable && motionManager.accelerometerAvailable {
            
            //locationManager.startUpdatingLocation()
            
            println("Launch setup completed.")
        }
        else {
            
            println("Magnetometer or Accelerometer unavailable")
        }
        
        return true // Needed
    }

    func locationManager(manager: CLLocationManager!, didUpdateLocations locations: [AnyObject]!) {
        
        var error = ""
        
        var nowLocation:CLLocation = locations[0] as CLLocation    // Collect location data
        
        userLocation = nowLocation

        // Get distance and interval since last location delegate update
        let intervalDelegate = timeDelegatePrev.timeIntervalSinceNow * -1
        let distanceDelegate = nowLocation.distanceFromLocation(locationDelegatePrev)
        
        // START filtering old, cached and inaccuracy location data
        
        var speed = calculateSpeed(distanceDelegate, interval: intervalDelegate)
        
        if speed > 500 {
            
            error = "Invalid speed of \(speed)kph"
        }
        
        if intervalDelegate < 3 && intervalDelegateTracker < 20 {
            
            intervalDelegateTracker += intervalDelegate
            
            error = "Update too quick. intDel=\(intervalDelegateTracker)"
        }
        
        if nowLocation.timestamp.timeIntervalSinceNow > 5 {
            
            error = "Data too old"
        }
        
        if nowLocation.horizontalAccuracy < 0 {
            
            error = "Data inaccurate"
        }
        
        locationDelegatePrev = nowLocation
        timeDelegatePrev = NSDate()
        
        if error != "" {
            
            println("Location not processed. Error: \(error)")
            
            return
        }
        
        // END of filtering
        
        intervalDelegateTracker = 0
        
        locationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers
        locationManager.distanceFilter = 99999
        
        if let timestamp = userLocation?.timestamp {
            
            let dateFormatter = NSDateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            var dateString = dateFormatter.stringFromDate(timestamp)
            
            //Add location data to coredata
            var saveError: NSError?
            let appDel:AppDelegate = UIApplication.sharedApplication().delegate as AppDelegate
            let context:NSManagedObjectContext = appDel.managedObjectContext!
            var result = NSEntityDescription.insertNewObjectForEntityForName("LocationData", inManagedObjectContext: context) as NSManagedObject
            
            result.setValue(timestamp, forKey: "dateRecord")
            result.setValue(NSDate(), forKey: "dateInserted")
            result.setValue(dateFormatter.dateFromString(dateString), forKey: "dateShort")
            result.setValue(userLocation?.coordinate.latitude, forKey: "lat")
            result.setValue(userLocation?.coordinate.longitude, forKey: "long")
            result.setValue(userLocation?.horizontalAccuracy, forKey: "accuracyH")
            result.setValue(userLocation?.verticalAccuracy, forKey: "accuracyV")
            
            if context.save(&saveError) {

                engageMagnotometer(timestamp)
                
                println("Save location. Record @ \(timestamp) : Inserted @ \(NSDate())")
            }
            else {
                
                println("Could not save: \(saveError?.userInfo)")
            }
        }

        // Set the variables needed for next location update
        
        locationPrev = nowLocation
        timePrev = NSDate()
    }
    
    func locationManager(manager: CLLocationManager!, didFailWithError error: NSError!) {
        
        println(error)
    }
    
    func engageMagnotometer(timestampMag: NSDate) {

        var delay = 20
        var delayCounter = 0
        var delta: Double = 0
        var deltaMax: Double = 0
        
        motionManager.magnetometerUpdateInterval = 0.1
        
        motionManager.startMagnetometerUpdatesToQueue(NSOperationQueue.mainQueue()) {
            (magnetometerData: CMMagnetometerData!, error: NSError!) in
        
            var x: Double = magnetometerData.magneticField.x
            var y: Double = magnetometerData.magneticField.y
            var z: Double = magnetometerData.magneticField.z
            
            var dx = fabs(x - self.xPrev)
            var dy = fabs(y - self.yPrev)
            var dz = fabs(z - self.zPrev)
            
            delta = dx + dy + dz
            
            if deltaMax < delta {
                
                deltaMax = delta
            }
            
            self.xPrev = x
            self.yPrev = y
            self.zPrev = z
        
            if delayCounter == delay {

                self.motionManager.stopMagnetometerUpdates()
                
                let dateFormatter = NSDateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd"
                var dateString = dateFormatter.stringFromDate(timestampMag)
                
                // Write to database
                var error: NSError?
                let appDel:AppDelegate = UIApplication.sharedApplication().delegate as AppDelegate
                let context:NSManagedObjectContext = appDel.managedObjectContext!
                var result = NSEntityDescription.insertNewObjectForEntityForName("MagData", inManagedObjectContext: context) as NSManagedObject
                
                result.setValue(timestampMag, forKey: "dateRecord")
                result.setValue(NSDate(), forKey: "dateInserted")
                result.setValue(dateFormatter.dateFromString(dateString), forKey: "dateShort")
                result.setValue(deltaMax, forKey: "delta")
                
                if context.save(&error) {
                    
                    println("Save Magnetometer. Record @ \(timestampMag) : Inserted @ \(NSDate())")
                    
                } else {

                    println("Could not save: \(error?.userInfo)")
                }
                
                self.engageAccelerometer(deltaMax, timestampAcc: timestampMag)
            }
            
            delayCounter++
        }
    }
    
    func engageAccelerometer(deltaMag: Double, timestampAcc: NSDate) {
        
        var delay = 30
        var delayCounter = 0

        var xAccPrev: Double = 0
        var yAccPrev: Double = 0
        var zAccPrev: Double = 0
        
        var deltaAcc: Double = 0
        
        motionManager.accelerometerUpdateInterval = 0.1
        
        motionManager.startAccelerometerUpdatesToQueue(NSOperationQueue.mainQueue()) {
            (accelData: CMAccelerometerData!, error: NSError!) -> Void in
            
            var x: Double = accelData.acceleration.x
            var y: Double = accelData.acceleration.y
            var z: Double = accelData.acceleration.z
            
            var dx = fabs(x - xAccPrev)
            var dy = fabs(y - yAccPrev)
            var dz = fabs(z - zAccPrev)
            
            var delta = dx + dy + dz
            
            if delta > deltaAcc {
                
                deltaAcc = delta
            }
            
            delayCounter++
            
            if delayCounter == delay {
                
                self.motionManager.stopAccelerometerUpdates()
                
                self.adjustTimerSensitivity(deltaMag, da: deltaAcc, dateRecord: timestampAcc)
                
                let dateFormatter = NSDateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd"
                var dateString = dateFormatter.stringFromDate(timestampAcc)
                
                // Write to database
                var error: NSError?
                let appDel:AppDelegate = UIApplication.sharedApplication().delegate as AppDelegate
                let context:NSManagedObjectContext = appDel.managedObjectContext!
                var result = NSEntityDescription.insertNewObjectForEntityForName("AccData", inManagedObjectContext: context) as NSManagedObject
                
                result.setValue(timestampAcc, forKey: "dateRecord")
                result.setValue(NSDate(), forKey: "dateInserted")
                result.setValue(dateFormatter.dateFromString(dateString), forKey: "dateShort")
                result.setValue(deltaAcc, forKey: "value")
                
                if context.save(&error) {
                    
                    println("Save Accelerometer. Record @ \(timestampAcc) : Inserted @ \(NSDate())")
                    
                } else {

                    println("Could not save: \(error?.userInfo)")
                }
            }
        }
    }
    
    func adjustTimerSensitivity(dm: Double, da: Double, dateRecord: NSDate) {
        
        // Adjust timers if movement is detected (to optimise battery life)
        
        if dm > magMovementThreshold && da > accMovementThreshold {
            
            if userStatus == "inactive" {
                
                timerInterval = activeTimer
            }
            else if timerInterval < activeTimerMax {
                
                timerInterval += 10
            }
            
            userStatus = "active"
            
            notes.append([dateRecord, "\tAV\(timerInterval)"])
        }
        else {
            
            if userStatus == "active" {
                
                timerInterval = inactiveTimer
            }
            else if timerInterval < inactiveTimerMax {
                
                timerInterval += 60
            }
            
            userStatus = "inactive"
            notes.append([dateRecord, "\tav\(timerInterval)"])
        }
        
        // Disable timers just in case any are still running
        timerBackground.invalidate()
        timerForeground.invalidate()
        
        // Kill background task
        UIApplication.sharedApplication().endBackgroundTask(bgTask)
        bgTask = UIBackgroundTaskInvalid
        
        // Set background timer if app is in background
        if UIApplication.sharedApplication().applicationState == UIApplicationState.Background {
            
            // Setup background task
            bgTask = UIApplication.sharedApplication().beginBackgroundTaskWithExpirationHandler({})
            
            timerBackground = NSTimer.scheduledTimerWithTimeInterval(timerInterval, target: self, selector: Selector("resumeUpdatingLocation"), userInfo: nil, repeats: false)
        }
        else {
            
            // Set foreground timer
            timerForeground = NSTimer.scheduledTimerWithTimeInterval(timerInterval, target: self, selector: Selector("resumeUpdatingLocation"), userInfo: nil, repeats: true)
        }
    }
 
    func resumeUpdatingLocation() {
        
        // Increase location accuracy
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        locationManager.distanceFilter = kCLDistanceFilterNone
        
        // Kill background task
        UIApplication.sharedApplication().endBackgroundTask(bgTask)
        bgTask = UIBackgroundTaskInvalid
    }
    
    func calculateSpeed(distance: CLLocationDistance, interval: Double) -> Double {
        
        let speed = (distance / 1000) / (interval / 3600)
        
        return speed
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        
        println("App went into the background")
        
        // Disable timers
        timerForeground.invalidate()
        timerBackground.invalidate()
        
        // Kill background task
        UIApplication.sharedApplication().endBackgroundTask(bgTask)
        bgTask = UIBackgroundTaskInvalid
        
        // Massive boost location accuracy
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        locationManager.distanceFilter = kCLDistanceFilterNone
    }

    func applicationWillEnterForeground(application: UIApplication) {
        
        println("App is in foreground.")
        
        // Disable timers
        timerForeground.invalidate()
        timerBackground.invalidate()
        
        // Kill background task
        UIApplication.sharedApplication().endBackgroundTask(bgTask)
        bgTask = UIBackgroundTaskInvalid
        
        // Set foreground timer
        timerForeground = NSTimer.scheduledTimerWithTimeInterval(
            timerInterval, target: self, selector: Selector("resumeUpdatingLocation"), userInfo: nil, repeats: true)
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.

        self.saveContext()
    }

    // MARK: - Core Data stack

    lazy var applicationDocumentsDirectory: NSURL = {
        // The directory the application uses to store the Core Data store file. This code uses a directory named "com-mclewis.Movement_Testing" in the application's documents Application Support directory.
        let urls = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
        return urls[urls.count-1] as NSURL
    }()

    lazy var managedObjectModel: NSManagedObjectModel = {
        // The managed object model for the application. This property is not optional. It is a fatal error for the application not to be able to find and load its model.
        let modelURL = NSBundle.mainBundle().URLForResource("Movement_Testing", withExtension: "momd")!
        return NSManagedObjectModel(contentsOfURL: modelURL)!
    }()

    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator? = {
        // The persistent store coordinator for the application. This implementation creates and return a coordinator, having added the store for the application to it. This property is optional since there are legitimate error conditions that could cause the creation of the store to fail.
        // Create the coordinator and store
        var coordinator: NSPersistentStoreCoordinator? = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        let url = self.applicationDocumentsDirectory.URLByAppendingPathComponent("Movement_Testing.sqlite")
        var error: NSError? = nil
        var failureReason = "There was an error creating or loading the application's saved data."
        if coordinator!.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: url, options: nil, error: &error) == nil {
            coordinator = nil
            // Report any error we got.
            let dict = NSMutableDictionary()
            dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data"
            dict[NSLocalizedFailureReasonErrorKey] = failureReason
            dict[NSUnderlyingErrorKey] = error
            error = NSError(domain: "YOUR_ERROR_DOMAIN", code: 9999, userInfo: dict)
            // Replace this with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog("Unresolved error \(error), \(error!.userInfo)")
            abort()
        }
        
        return coordinator
    }()

    lazy var managedObjectContext: NSManagedObjectContext? = {
        // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.) This property is optional since there are legitimate error conditions that could cause the creation of the context to fail.
        let coordinator = self.persistentStoreCoordinator
        if coordinator == nil {
            return nil
        }
        var managedObjectContext = NSManagedObjectContext()
        managedObjectContext.persistentStoreCoordinator = coordinator
        return managedObjectContext
    }()

    // MARK: - Core Data Saving support

    func saveContext () {
        if let moc = self.managedObjectContext {
            var error: NSError? = nil
            if moc.hasChanges && !moc.save(&error) {
                // Replace this implementation with code to handle the error appropriately.
                // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                NSLog("Unresolved error \(error), \(error!.userInfo)")
                abort()
            }
        }
    }

}

