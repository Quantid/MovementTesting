//
//  VenueTableViewController.swift
//  Movement Testing
//
//  Created by Matthew Lewis on 07/02/2015.
//  Copyright (c) 2015 iD Foundry. All rights reserved.
//

import UIKit

class VenueTableViewController: UITableViewController {
    
    let kCLIENTID = "ZJBZJHRSW4LMMV0F4EOIDODPOLICPGLAJNTURTHPPLFAYOJP"
    let kCLIENTSECRET = "WZDUCDTNFV2L1SQOATMAMO0WKAYSFWORDN2G4VM0MDPXZFKK"
    
    var venues: NSArray = NSArray()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureRestKit()
        
        loadVenues()
  
    }
    
    func configureRestKit() {
        
        // initialize AFNetworking HTTPClient
        let baseURL: NSURL = NSURL(string: "https://api.foursquare.com")!
        let client = AFHTTPClient(baseURL: baseURL)
        
        // initialize RestKit
        let objectManager = RKObjectManager(HTTPClient: client)
        
        // setup object mappings
        let venueMapping = RKObjectMapping(forClass: Venue.self)
        venueMapping.addAttributeMappingsFromArray(["name"])
        
        let locationMapping = RKObjectMapping(forClass: Location.self)
        locationMapping.addAttributeMappingsFromArray(["address", "city", "country", "crossStreet", "postalCode", "state", "distance", "lat", "lng"])
        
        venueMapping.addPropertyMapping(RKRelationshipMapping(fromKeyPath: "location", toKeyPath: "location", withMapping: locationMapping))

        // register mappings with the provider using a response descriptor
        let responseDescriptor = RKResponseDescriptor(mapping: venueMapping, method: RKRequestMethod.GET, pathPattern: "/v2/venues/search", keyPath: "response.venues", statusCodes: NSIndexSet(index: 200))
        
        objectManager.addResponseDescriptor(responseDescriptor)
    }
    
    func loadVenues() {
        let latLon = "51.472026, -0.203229" // approximate latLon of The Mothership (a.k.a Apple headquarters)
        let queryParams = [
            "ll": latLon,
            "client_id": kCLIENTID,
            "client_secret": kCLIENTSECRET,
            //"categoryId": "4bf58dd8d48988d1e0931735",
            "v" : "20140617"
        ]
        
        RKObjectManager.sharedManager().getObjectsAtPath("/v2/venues/search", parameters: queryParams,
            success:{ operation, mappingResult in
                self.venues = mappingResult.array()
                self.tableView.reloadData()
            },
            failure:{ operation, error in
                NSLog("What do you mean by 'there is no coffee?': \(error!.localizedDescription)")
            }
        )
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

        return venues.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("cell", forIndexPath: indexPath) as UITableViewCell

        let venue: Venue = venues[indexPath.row] as Venue
        let distance = venue.location?.distance?.floatValue
        
        cell.textLabel?.text = venue.name
        cell.detailTextLabel?.text = NSString(format: "%.0fm", distance!)
        
        return cell
    }

    /*
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return NO if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return NO if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
    }
    */

}
