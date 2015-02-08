//
//  SensorController.swift
//  Movement Testing
//
//  Created by Matthew Lewis on 07/02/2015.
//  Copyright (c) 2015 iD Foundry. All rights reserved.
//

import UIKit
import CoreMotion
import CoreData

class SensorController: NSObject {
    
    let motionManager: CMMotionManager = CMMotionManager()
    
    var xPrev: Double = 0
    var yPrev: Double = 0
    var zPrev: Double = 0
    
    let appDelegate: AppDelegate = AppDelegate()
    
    func engageMagnotometer(timestamp: NSDate) {
        
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
                var dateString = dateFormatter.stringFromDate(timestamp)
                
                // Write to database
                var error: NSError?
                let appDel:AppDelegate = UIApplication.sharedApplication().delegate as AppDelegate
                let context:NSManagedObjectContext = appDel.managedObjectContext!
                var result = NSEntityDescription.insertNewObjectForEntityForName("MagData", inManagedObjectContext: context) as NSManagedObject
                
                result.setValue(timestamp, forKey: "dateRecord")
                result.setValue(NSDate(), forKey: "dateInserted")
                result.setValue(dateFormatter.dateFromString(dateString), forKey: "dateShort")
                result.setValue(deltaMax, forKey: "delta")
                
                if context.save(&error) {
                    
                    self.appDelegate.queueMagDeltas.append(deltaMax)

                    println("Save Magnetometer. Record @ \(timestamp) : Inserted @ \(NSDate())")
                    
                } else {
                    
                    self.appDelegate.queueMagDeltas.append(-1)

                    println("Could not save: \(error?.userInfo)")
                }
            }
            
            delayCounter++
        }
    }
    
    func engageAccelerometer(timestamp: NSDate) {
        
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
                
                let dateFormatter = NSDateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd"
                var dateString = dateFormatter.stringFromDate(timestamp)
                
                // Write to database
                var error: NSError?
                let appDel:AppDelegate = UIApplication.sharedApplication().delegate as AppDelegate
                let context:NSManagedObjectContext = appDel.managedObjectContext!
                var result = NSEntityDescription.insertNewObjectForEntityForName("AccData", inManagedObjectContext: context) as NSManagedObject
                
                result.setValue(timestamp, forKey: "dateRecord")
                result.setValue(NSDate(), forKey: "dateInserted")
                result.setValue(dateFormatter.dateFromString(dateString), forKey: "dateShort")
                result.setValue(deltaAcc, forKey: "value")
                
                if context.save(&error) {
                    
                    self.appDelegate.queueAccValues.append(deltaAcc)

                    println("Save Accelerometer. Record @ \(timestamp) : Inserted @ \(NSDate())")
                    
                } else {
                    
                    self.appDelegate.queueAccValues.append(-1)
                    
                    println("Could not save: \(error?.userInfo)")
                }
            }
        }
    }
}
