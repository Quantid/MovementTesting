//
//  CalendarTableViewController.swift
//  Movement Testing
//
//  Created by Matthew Lewis on 25/01/2015.
//  Copyright (c) 2015 iD Foundry. All rights reserved.
//

import UIKit
import CoreData

var dates = [NSDate]()

let dateFormatter = NSDateFormatter()

class CalendarTableViewController: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        dates.removeAll()
        
        // Initialise core data
        
        var error: NSError?
        let appDel:AppDelegate = UIApplication.sharedApplication().delegate as AppDelegate
        let context:NSManagedObjectContext = appDel.managedObjectContext!

        var request = NSFetchRequest(entityName: "LocationData")
        request.propertiesToFetch = NSArray(object: "dateShort")
        request.returnsObjectsAsFaults = false
        request.returnsDistinctResults = true
        request.resultType = NSFetchRequestResultType.DictionaryResultType
        request.sortDescriptors = [NSSortDescriptor(key: "dateRecord", ascending: false)]
        
        var results:NSArray = context.executeFetchRequest(request, error: &error)!
        
        if error == nil {
            println(results)
            for result in results {
                
                if let dateResult = result["dateShort"] as? NSDate {
                    
                    dates.append(dateResult)
                }
            }
        }
        else {
            
            println("Error fetching dates: \(error)")
        }
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

        return dates.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("cell", forIndexPath: indexPath) as UITableViewCell
        
        dateFormatter.dateFormat = "dd-MMM-yyyy"
        
        cell.textLabel?.text = dateFormatter.stringFromDate(dates[indexPath.row])

        return cell
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        performSegueWithIdentifier("jumpToDay", sender: self)
   }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if segue.identifier == "jumpToDay" {
            
            if let selectedIndex = self.tableView.indexPathForSelectedRow()?.row {
                
                var destinationVC: DayTableViewController = segue.destinationViewController as DayTableViewController

                destinationVC.dateDay = dates[selectedIndex] as NSDate
            }
        }
    }

}
