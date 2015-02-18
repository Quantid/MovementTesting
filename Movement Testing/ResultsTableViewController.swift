//
//  ResultsTableViewController.swift
//  Movement Testing
//
//  Created by Matthew Lewis on 29/01/2015.
//  Copyright (c) 2015 iD Foundry. All rights reserved.
//

import UIKit
import CoreData

class ResultsTableViewController: UITableViewController {
    
    var output = [NSString]()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        loadTable()
        
        let timer = NSTimer.scheduledTimerWithTimeInterval(10, target: self, selector: Selector("loadTable"), userInfo: nil, repeats: true)
    }
    
    func loadTable() {
        
        let delegate = UIApplication.sharedApplication().delegate as AppDelegate
        
        var error: NSError?
        
        var dataLocation = [NSArray]()
        var dataMagnetometer = [Double]()
        var dataAccelerometer = [Double]()
        var dataDates = [NSDate]()
        
        var datePrevious = NSDate()
        
        let appDel:AppDelegate = UIApplication.sharedApplication().delegate as AppDelegate
        let context:NSManagedObjectContext = appDel.managedObjectContext!
        
        var request = NSFetchRequest(entityName: "LocationData")
        request.fetchLimit = 100
        request.returnsObjectsAsFaults = false
        request.resultType = NSFetchRequestResultType.DictionaryResultType
        request.sortDescriptors = [NSSortDescriptor(key: "dateRecord", ascending: false)]
        
        var results:NSArray = context.executeFetchRequest(request, error: &error)!
        
        if error == nil {

            for result in results {
                
                let lat = result["lat"] as Double
                let long = result["long"] as Double
                let accuracy = result["accuracyH"] as Double
                
                dataDates.append(result["dateRecord"] as NSDate)
                dataLocation.append([lat, long, accuracy])
            }
            
            for var i = 0; i < dataDates.count; i++ {
                
                let query = NSFetchRequest(entityName: "MagData")
                query.predicate = NSPredicate(format: "dateRecord = %@", dataDates[i])
                query.returnsObjectsAsFaults = false
                
                if let results = context.executeFetchRequest(query, error: &error) {
                    
                    if results.count > 0 {
                        
                        for result in results {

                            if let value = result.valueForKey("delta") as? Double {
                                
                                dataMagnetometer.append(value)
                            }
                            else {
                                dataMagnetometer.append(0)
                            }
                            
                            break
                        }
                    }
                    else {
                        
                        dataMagnetometer.append(0)
                    }
                }
                else {
                    
                    println("There was an error \(error)")
                }
            }
            
            for var i = 0; i < dataDates.count; i++ {
                
                let query = NSFetchRequest(entityName: "AccData")
                query.predicate = NSPredicate(format: "dateRecord = %@", dataDates[i])
                query.returnsObjectsAsFaults = false
                query.sortDescriptors = [NSSortDescriptor(key: "dateRecord", ascending: true)]
                
                if let results = context.executeFetchRequest(query, error: &error) {
                    
                    if results.count > 0 {
                        
                        for result in results {
                            
                            if let value = result.valueForKey("value") as? Double {
                                
                                dataAccelerometer.append(value)
                            }
                            else {
                                
                                dataAccelerometer.append(0)
                            }
                            
                            break
                        }
                    }
                    else {
                        
                        dataAccelerometer.append(0)
                    }
                }
                else {
                    
                    println("There was an error \(error)")
                }
            }
        }
        else {
            
            println("There was a error: \(error)")
        }
        
        output.removeAll()

        for var i = 0; i < dataDates.count - 2; i++ {
            
            let date = dataDates[i] as NSDate
            let mag = dataMagnetometer[i] as Double
            let acc = dataAccelerometer[i] as Double
            let accuracy = dataLocation[i][2] as Double
            
            var interval:NSTimeInterval = 0
            var note = ""
        
            interval = date.timeIntervalSinceDate(dataDates[i + 1])
            
            for var j = 0; j < delegate.notes.count; j++ {
                
                if delegate.notes[j][0] as NSDate == dataDates[i] {
                    
                    note = delegate.notes[j][1] as NSString
                }
            }
            
            let outputString = "\(Int(interval))\t[\(round(mag * 10) / 10)]\t[\(round(acc * 10) / 10)]\t\(round(accuracy * 10) / 10)\(note)"
            
            output.append(outputString)
            
            datePrevious = date
        }
        
        tableView.reloadData()
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

        return output.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("cell", forIndexPath: indexPath) as UITableViewCell
        
        cell.textLabel?.font = UIFont.systemFontOfSize(12)
        cell.textLabel?.text = output[indexPath.row]
        
        return cell
    }
}
