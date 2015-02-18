//
//  MapViewController.swift
//  Movement Testing
//
//  Created by Matthew Lewis on 07/02/2015.
//  Copyright (c) 2015 iD Foundry. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

class MapViewController: UIViewController, MKMapViewDelegate {

    @IBOutlet weak var mapView: MKMapView!
    
    var dataRoute = [NSArray]()
    
    let zoomMax: Double = 300
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.mapView.delegate = self
        
        prepareMap()

        //println(dataRoute)
        
        var locations = [CLLocation]()
        
        for var i = 0; i < dataRoute.count; i++ {
            
            let location: CLLocation = CLLocation(latitude: dataRoute[i][0] as Double, longitude: dataRoute[i][1] as Double)
            
            locations.append(location)
        }
        
        //println("locations: \(locations)")
        
        var coordinates = locations.map({(location: CLLocation!) -> CLLocationCoordinate2D in
            return location.coordinate
        })
        
        var polyline = MKPolyline(coordinates: &coordinates, count: locations.count)
        
        self.mapView.addOverlay(polyline)
        
        //let path: UIBezierPath = quadCurvedPathWithPoints(dataRoute)
        
        //let strokeColor: UIColor = UIColor.brownColor()
        
        //self.view.setNeedsDisplay()
    }
    
    func prepareMap() {

        let index = dataRoute.count
        var distanceMax: Double = 0
        
        // Calculate center coordinates for the overall journey
        
        let centerCoordinate = centerCoordinates(dataRoute)
        let latCenter = centerCoordinate[0]
        let lngCenter = centerCoordinate[1]
        let coordinateCenter: CLLocationCoordinate2D = CLLocationCoordinate2DMake(latCenter, lngCenter)
        let locationCenter: CLLocation = CLLocation(coordinate: coordinateCenter, altitude: 0, horizontalAccuracy: 10, verticalAccuracy: 10, timestamp: NSDate())
        
        for var i = 0; i < index; i++ {

            let lat: Double = dataRoute[i][0] as Double
            let lng: Double = dataRoute[i][1] as Double
            let coordinatePoint: CLLocationCoordinate2D = CLLocationCoordinate2DMake(lat, lng)
            let locationPoint: CLLocation = CLLocation(coordinate: coordinatePoint, altitude: 0, horizontalAccuracy: 10, verticalAccuracy: 10, timestamp: NSDate())
            
            let distance = locationCenter.distanceFromLocation(locationPoint)
            
            println("distance: \(distance)")

            if distance > distanceMax {

                distanceMax = distance
            }
        }
        
        if distanceMax < zoomMax {
            
            distanceMax = zoomMax
        }

        println("centers: \(latCenter) \(lngCenter)")
        
        //var latDelta: CLLocationDegrees = 0.02
        //var lngDelta: CLLocationDegrees = 0.02
        
        //var span: MKCoordinateSpan = MKCoordinateSpanMake(latDelta, lngDelta)
        var initLocation: CLLocationCoordinate2D = CLLocationCoordinate2DMake(latCenter, lngCenter)
        var region: MKCoordinateRegion = MKCoordinateRegionMakeWithDistance(initLocation, distanceMax * 2.5, distanceMax * 2.5)
        
        self.mapView.setRegion(region, animated: true)
        self.mapView.centerCoordinate = initLocation
    }
    
    func centerCoordinates(data: [NSArray]) -> [Double] {
        
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
    
    func quadCurvedPathWithPoints(points: NSArray) -> UIBezierPath {
        
        var path: UIBezierPath = UIBezierPath()
        
        var value: NSValue = points[0] as NSValue
        
        var p1: CGPoint = value.CGPointValue()
        
        path.moveToPoint(p1)
        
        if points.count == 2 {
            
            value = points[1] as NSValue
            let p2: CGPoint = value.CGPointValue()
            path.addLineToPoint(p2)

            return path
        }
        
        for var i: Int = 1; i < points.count; i++ {
            
            value = points[i] as NSValue
            let p2: CGPoint = value.CGPointValue()
            
            let midPoint: CGPoint = midPointForPoints(p1, p2: p2)
            
            path.addQuadCurveToPoint(midPoint, controlPoint: controlPointForPoints(midPoint, p2: p1))
            path.addQuadCurveToPoint(p2, controlPoint: controlPointForPoints(midPoint, p2: p2))

            p1 = p2
        }
        return path
    }
    
    func midPointForPoints(p1: CGPoint, p2: CGPoint) -> CGPoint {
        
        return CGPointMake((p1.x + p2.x) / 2, (p1.y + p2.y) / 2)
    }
    
    func controlPointForPoints(p1: CGPoint, p2: CGPoint) -> CGPoint {
        
        var controlPoint: CGPoint = midPointForPoints(p1, p2: p2)
        let diffY: CGFloat = abs(p2.y - controlPoint.y)
        
        if p1.y < p2.y {
            
            controlPoint.y += diffY
        }
        else if p1.y > p2.y {
            
            controlPoint.y -= diffY
        }
        
        return controlPoint
    }
    
    func mapView(mapView: MKMapView!, rendererForOverlay overlay: MKOverlay!) -> MKOverlayRenderer! {

        if overlay is MKPolyline {
            var polylineRenderer = MKPolylineRenderer(overlay: overlay)
            polylineRenderer.strokeColor = UIColor.blueColor()
            polylineRenderer.lineWidth = 10
            return polylineRenderer
        }
        
        return nil
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
