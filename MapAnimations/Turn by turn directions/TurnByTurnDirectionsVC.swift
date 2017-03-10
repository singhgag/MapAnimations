//
//  TurnByTurnDirectionsVC.swift
//  MapAnimations
//
//  Created by Gagandeep Singh on 3/3/17.
//  Copyright © 2017 Gagandeep Singh. All rights reserved.
//

import UIKit
import ArcGIS

class TurnByTurnDirectionsVC: UIViewController {

    @IBOutlet var mapView:AGSMapView!
    @IBOutlet var routeBBI:UIBarButtonItem!
    @IBOutlet var directionsView:UIView!
    @IBOutlet var directionsLabel:UILabel!
    
    private var point1 = AGSPoint(x: -13051580.418701, y: 3859622.340737, spatialReference: AGSSpatialReference.webMercator())
    private var point2 = AGSPoint(x: -13034925.709800, y: 3851421.541825, spatialReference: AGSSpatialReference.webMercator())
    
    private var routeTask:AGSRouteTask!
    private var routeParameters:AGSRouteParameters!
    private var generatedRoute:AGSRoute!
    private var routeGraphic:AGSGraphic!
    
    private var stopGraphicsOverlay = AGSGraphicsOverlay()
    private var routeGraphicsOverlay = AGSGraphicsOverlay()
    private var directionsGraphicsOverlay = AGSGraphicsOverlay()
    
    private var isDirectionsListVisible = false
    private var directionIndex = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()

        //initialize map with vector basemap
        let map = AGSMap(basemap: AGSBasemap.topographic())
        
        //assign map to the map view
        self.mapView.map = map
        
        //add the graphics overlays to the map view
        self.mapView.graphicsOverlays.addObjects(from: [routeGraphicsOverlay, directionsGraphicsOverlay, stopGraphicsOverlay])
        
        //zoom to viewpoint
        self.mapView.setViewpointCenter(AGSPoint(x: -13042254.715252, y: 3857970.236806, spatialReference: AGSSpatialReference(wkid: 3857)), scale: 1e5, completion: nil)
        
        //initialize route task
        self.routeTask = AGSRouteTask(url: URL(string: "https://sampleserver6.arcgisonline.com/arcgis/rest/services/NetworkAnalysis/SanDiego/NAServer/Route")!)
        
        //stylize directions view
        self.directionsView.layer.cornerRadius = 5
        self.directionsView.layer.shadowColor = UIColor.gray.cgColor
        self.directionsView.layer.shadowOffset = CGSize(width: 2, height: 2)
        self.directionsView.layer.shadowRadius = 10
        self.directionsView.layer.shadowOpacity = 1
        
        //hide the directions view initially
        self.directionsView.isHidden = true
        
        //add graphics
        self.addGraphics()
        
        //get default parameters
        self.getDefaultParameters()
        
        //add observer for map scale, to update the direction symbols
        self.mapView.addObserver(self, forKeyPath: "mapScale", options: .new, context: nil)
        
    }
    
    //MARK: - Turns logic
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "mapScale" {
            self.focusOnManuever(atIndex: self.directionIndex, inAnimation: false, completion: nil)
        }
    }
    
    @IBAction func animate() {
        self.directionIndex = 0
        self.startManueverAnimation()
    }
    
    func startManueverAnimation() {
        
        self.focusOnManuever(atIndex: self.directionIndex, inAnimation: true) { [weak self] (finished) in
            
            if let weakSelf = self {
                
                self?.directionIndex += 1
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8, execute: {
                    
                    if weakSelf.directionIndex < weakSelf.generatedRoute.directionManeuvers.count {
                        self?.startManueverAnimation()
                    }
                    else {
                        //animation finished
                        
                        //reset view point to route's geometry
                        weakSelf.mapView.setViewpointRotation(0, completion: nil)
                        weakSelf.mapView.setViewpointGeometry(weakSelf.generatedRoute.routeGeometry!, padding: 20, completion: nil)
                        
                        //clear direction graphics
                        weakSelf.directionsGraphicsOverlay.graphics.removeAllObjects()
                        
                        //hide directions view
                        weakSelf.directionsView.isHidden = true
                    }
                })
            }
        }
    }
    
    func focusOnManuever(atIndex index:Int, inAnimation:Bool, completion: ((Bool) -> Void)?) {
        if self.generatedRoute != nil && index < self.generatedRoute.directionManeuvers.count {
            self.directionsGraphicsOverlay.graphics.removeAllObjects()
            
            var points = [AGSPoint]()
            
            // get current direction and add it to the graphics layer
            let directions = self.generatedRoute.directionManeuvers
            
            let length = 10 * self.mapView.mapScale / 1000
            
            if index - 1 > 0 {
                if let prevGeometry = directions[index - 1].geometry as? AGSPolyline {
                    if let prevSubPolyline = prevGeometry.toBuilder().subPolyline(inForwardDirection: false, length: length) {
                        points.append(contentsOf: prevSubPolyline.parts[0].points.array().reversed())
                    }
                }
            }
            
            if let currGeometry = directions[index].geometry as? AGSPolyline {
                if let subPolyline = currGeometry.toBuilder().subPolyline(inForwardDirection: true, length: length) {
                    points.append(contentsOf: subPolyline.parts[0].points.array())
                }
            }
            
            if points.count > 0 {
                let combinedPolyline = AGSPolyline(points: points)
                let graphic = AGSGraphic(geometry: combinedPolyline, symbol: self.currentDirectionSymbol(), attributes: nil)
                
                
                if inAnimation {
                    let rotationAngle = self.angleOfRotationForPolyline(combinedPolyline)
                    let viewpoint = AGSViewpoint(center: combinedPolyline.extent.center, scale: 1e4, rotation: rotationAngle)
                    
                    self.mapView.setViewpoint(viewpoint, duration: 1, curve: .linear, completion: { (finished) in
                        completion?(finished)
                    })
                    
                    //unhide the directions view
                    if self.directionsView.isHidden {
                        self.directionsView.isHidden = false
                    }
                    
                    //update directions label
                    let directionText = directions[index].directionText
                    self.directionsLabel.text = directionText
                    
                    self.directionsGraphicsOverlay.graphics.add(graphic)
                    
                    if let arrowHeadGeometry = combinedPolyline.toBuilder().arrowhead(size: length/3) {
                        let arrowHeadGraphic = AGSGraphic(geometry: arrowHeadGeometry, symbol: self.currentDirectionSymbol(), attributes: nil)
                        self.directionsGraphicsOverlay.graphics.add(arrowHeadGraphic)
                    }
                }
                else {
                    completion?(true)
                }
            }
            else {
                completion?(true)
            }
            
        }
    }
    
    func angleOfRotationForPolyline(_ polyline:AGSPolyline) -> Double {
        //consider single part polyline
        //let totalPoint = polyline.parts[0].pointCount
        let firstPoint = polyline.parts[0].point(at: 0)
        let secondPoint = polyline.parts[0].point(at: 1)
        
        
        // Calculate perpendicular offset
        
        let length = AGSGeometryEngine.distanceBetweenGeometry1(firstPoint, geometry2: secondPoint)
        if length <= 0 {
            return 0
        }
        let dx = secondPoint.x - firstPoint.x
        let dy = secondPoint.y - firstPoint.y
        
        let angleXRadians = atan(dy/dx)
        let angleXInDegrees = angleXRadians * 180 / M_PI
        var angleYInDegrees = 90 - angleXInDegrees
        
        if dx < 0 {
            angleYInDegrees += 180
        }
        
        return angleYInDegrees.truncatingRemainder(dividingBy: 360)
        
    }
    
    //composite symbol for the direction graphic
    func currentDirectionSymbol() -> AGSCompositeSymbol {
        let compositeSymbol = AGSCompositeSymbol()
        
        let outerLineSymbol = AGSSimpleLineSymbol()
        outerLineSymbol.color = UIColor.white
        outerLineSymbol.style = .solid
        outerLineSymbol.width = 8
        compositeSymbol.symbols.append(outerLineSymbol)
        
        let innerLineSymbol = AGSSimpleLineSymbol()
        innerLineSymbol.color = UIColor.orange
        innerLineSymbol.style = .solid
        innerLineSymbol.width = 4
        compositeSymbol.symbols.append(innerLineSymbol)
        
        return compositeSymbol
    }
    

    //MARK: - Route logic
    
    private func addGraphics() {
        
        //symbol for start and stop points
        let symbol1 = AGSPictureMarkerSymbol(image: UIImage(named: "GreenMarker")!)
        symbol1.offsetY = 22
        let symbol2 = AGSPictureMarkerSymbol(image: UIImage(named: "RedMarker")!)
        symbol2.offsetY = 22
        
        //graphics
        let graphic1 = AGSGraphic(geometry: self.point1, symbol: symbol1, attributes: nil)
        let graphic2 = AGSGraphic(geometry: self.point2, symbol: symbol2, attributes: nil)
        
        //add these graphics to the overlay
        self.stopGraphicsOverlay.graphics.addObjects(from: [graphic1, graphic2])
    }
    
    func getDefaultParameters() {
        
        //get the default route parameters
        self.routeTask.defaultRouteParameters { [weak self] (params: AGSRouteParameters?, error: Error?) -> Void in
            if let error = error {
                SVProgressHUD.showError(withStatus: error.localizedDescription)
            }
            else {
                SVProgressHUD.dismiss()
                
                //keep a reference
                self?.routeParameters = params
                
                //enable bar button item
                self?.routeBBI.isEnabled = true
                
                self?.route()
            }
        }
    }
    
    @IBAction func route() {
        
        SVProgressHUD.show(withStatus: "Routing", maskType: SVProgressHUDMaskType.gradient)
        
        //clear routes
        self.routeGraphicsOverlay.graphics.removeAllObjects()
        
        //all calculations are in meters so need the directions geometry in web mercator
        self.routeParameters.outputSpatialReference = AGSSpatialReference.webMercator()
        
        //return directions
        self.routeParameters.returnDirections = true
        
        //add stops
        self.routeParameters.setStops([AGSStop(point: point1), AGSStop(point: point2)])
        
        //solve route
        self.routeTask.solveRoute(with: self.routeParameters) { [weak self] (routeResult:AGSRouteResult?, error:Error?) -> Void in
            if let error = error {
                //show error
                SVProgressHUD.showError(withStatus: "\(error.localizedDescription) \((error as NSError).localizedFailureReason ?? "")")
            }
            else {
                //dismiss progress hud
                SVProgressHUD.dismiss()
                
                //if a route is found
                if let route = routeResult?.routes[0], let weakSelf = self {
                    
                    //create graphic for the route
                    let routeGraphic = AGSGraphic(geometry: route.routeGeometry, symbol: weakSelf.routeSymbol(false), attributes: nil)
                    
                    //add route graphic to route graphics overlay
                    weakSelf.routeGraphicsOverlay.graphics.add(routeGraphic)
                    
                    //keep reference to route, for animation
                    weakSelf.generatedRoute = route
                }
            }
        }
    }
    
    //composite symbol for route graphic
    func routeSymbol(_ dashed: Bool) -> AGSCompositeSymbol {
        
        let compositeSymbol = AGSCompositeSymbol()
        
        //outer/wider line symbol
        let outerLineSymbol = AGSSimpleLineSymbol()
        outerLineSymbol.color = UIColor(red: 0, green: 174.0/255.0, blue: 231.0/255.0, alpha: 1)
        outerLineSymbol.style = dashed ? .dash : .solid
        outerLineSymbol.width = 8
        
        //inner/thinner line symbol
        let innerLineSymbol = AGSSimpleLineSymbol()
        innerLineSymbol.color = UIColor(red: 52.0/255.0, green: 203.0/255.0, blue: 252.0/255.0, alpha: 1)
        innerLineSymbol.style = dashed ? .dash : .solid
        innerLineSymbol.width = 4
        
        //add both the symbols to the composite symbol in order
        compositeSymbol.symbols.append(contentsOf: [outerLineSymbol, innerLineSymbol])
        
        return compositeSymbol
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
