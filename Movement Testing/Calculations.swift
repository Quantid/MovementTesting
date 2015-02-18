//
//  Calculations.swift
//  Movement Testing
//
//  Created by Matthew Lewis on 12/02/2015.
//  Copyright (c) 2015 iD Foundry. All rights reserved.
//

import UIKit
import CoreLocation

class Calculations: NSObject {

    let magMovementThreshold: Double = 6
    let accMovementThreshold: Double = 1.9
    let speedMovementThreshold: Double = 4
    
    func calculateSpeed(loc1: CLLocation, loc2: CLLocation, time1: NSDate, time2: NSDate) -> Double {
        
        let interval = time1.timeIntervalSinceDate(time2)
        let distance = loc1.distanceFromLocation(loc2)
        let speed = (distance / 1000) / (interval / 3600)
        
        return speed
    }
    
    func binaryConvert(value: Double, type: NSString) -> NSInteger {
        
        var result: NSInteger = 0
        
        switch type {
        case "mag":
            
            if value > magMovementThreshold {
                
                result = 1
            }
        case "acc":
            
            if value > accMovementThreshold {
                
                result = 1
            }
        case "spd":
            
            if value > speedMovementThreshold {
                
                result = 1
            }
        default:
            result = 0
        }
        
        return result
    }
}
