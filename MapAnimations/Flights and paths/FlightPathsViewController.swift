//
//  FlightPathsViewController.swift
//  MapAnimations
//
//  Created by Gagandeep Singh on 3/4/17.
//  Copyright © 2017 Gagandeep Singh. All rights reserved.
//

import UIKit
import ArcGIS

class FlightPathsViewController: UIViewController {

    @IBOutlet var mapView:AGSMapView!
    
    private var airportGraphicsOverlay = AGSGraphicsOverlay()
    private var planeGraphicsOverlay = AGSGraphicsOverlay()
    private var routeGraphicsOverlay = AGSGraphicsOverlay()
    private var hiddenRouteGraphicsOverlay = AGSGraphicsOverlay()
    
    private var flightPaths:[AGSPolyline]!
    private var drawAnimationHelpers:[DrawAnimationHelper]!
    private var animateAlongPathHelpers:[AnimateAlongPathHelper]!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let map = AGSMap(basemap: AGSBasemap.topographic())
        self.mapView.map = map
        
        self.mapView.graphicsOverlays.addObjects(from: [self.airportGraphicsOverlay, self.routeGraphicsOverlay, self.planeGraphicsOverlay])
        
        self.createFlightRoutes()
        
    }
    
    @IBAction func animatePlanes() {
        
        //clear graphics
        self.clearGraphics()
        
        //initialize array
        self.animateAlongPathHelpers = [AnimateAlongPathHelper]()
        
        for polyline in self.flightPaths {
            
            let planeSymbol = AGSPictureMarkerSymbol(image: UIImage(named: "plane")!)
            let graphic = AGSGraphic(geometry: nil, symbol: planeSymbol, attributes: nil)
            
            
            let randomTime = Double(arc4random_uniform(3000)) / 60.0
            let randomSpeed = Double(arc4random_uniform(9)) + 1
            
            let animateAlongPathHelper = AnimateAlongPathHelper(polyline: polyline, animatingGraphic: graphic, speed: 10000 * randomSpeed)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + randomTime, execute: { [weak self] in
                self?.planeGraphicsOverlay.graphics.add(graphic)
                animateAlongPathHelper.startAnimation()
            })
            
            self.animateAlongPathHelpers.append(animateAlongPathHelper)
        }
    }
    
    @IBAction func animateRoutes() {
        
        //clear existing graphics
        self.clearGraphics()
        
        //initialize array to store helper objects
        self.drawAnimationHelpers = [DrawAnimationHelper]()
        
        //loop through each polyline to create and start animation
        for polyline in self.flightPaths {
            
            //
            let symbol = AGSSimpleLineSymbol(style: .solid, color: UIColor.blue, width: 2)
            let graphic = AGSGraphic(geometry: nil, symbol: symbol, attributes: nil)
            
            let randomTime = Double(arc4random_uniform(3000)) / 60.0
            let randomSpeed = Double(arc4random_uniform(9)) + 1
            
            let drawAnimationHelper = DrawAnimationHelper(polyline: polyline, animatingGraphic: graphic, speed: 10000 * randomSpeed)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + randomTime, execute: { [weak self] in
                drawAnimationHelper.startAnimation()
                self?.routeGraphicsOverlay.graphics.add(graphic)
            })
            
            self.drawAnimationHelpers.append(drawAnimationHelper)
        }
    }
    
    @IBAction func animateBoth() {
        
        //clear graphics
        self.clearGraphics()
        
        //initialize arrays
        self.animateAlongPathHelpers = [AnimateAlongPathHelper]()
        self.drawAnimationHelpers = [DrawAnimationHelper]()
        
        for polyline in self.flightPaths {
            
            let planeSymbol = AGSPictureMarkerSymbol(image: UIImage(named: "plane")!)
            let planeGraphic = AGSGraphic(geometry: nil, symbol: planeSymbol, attributes: nil)
            
            let routeSymbol = AGSSimpleLineSymbol(style: .solid, color: UIColor.blue, width: 2)
            let routeGraphic = AGSGraphic(geometry: polyline, symbol: routeSymbol, attributes: nil)
            
            let randomTime = Double(arc4random_uniform(3000)) / 60.0
            let randomSpeed = Double(arc4random_uniform(9)) + 1
            
            let animateAlongPathHelper = AnimateAlongPathHelper(polyline: polyline, animatingGraphic: planeGraphic, speed: 10000 * randomSpeed)
            let drawAnimationHelper = DrawAnimationHelper(polyline: polyline, animatingGraphic: routeGraphic, speed: 10000 * randomSpeed)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + randomTime, execute: { [weak self] in
                
                drawAnimationHelper.startAnimation()
                self?.routeGraphicsOverlay.graphics.add(routeGraphic)
                
                animateAlongPathHelper.startAnimation()
                self?.planeGraphicsOverlay.graphics.add(planeGraphic)
            })
            
            self.drawAnimationHelpers.append(drawAnimationHelper)
            self.animateAlongPathHelpers.append(animateAlongPathHelper)
        }
    }
    
    @IBAction func switchValueChanged(sender: UISwitch) {
        if sender.isOn {
            self.mapView.graphicsOverlays.insert(self.hiddenRouteGraphicsOverlay, at: 1)
        }
        else {
            self.mapView.graphicsOverlays.remove(self.hiddenRouteGraphicsOverlay)
        }
    }
    
    private func clearGraphics() {
        
        self.planeGraphicsOverlay.graphics.removeAllObjects()
        self.routeGraphicsOverlay.graphics.removeAllObjects()
        
        //stop animation
        self.animateAlongPathHelpers?.removeAll()
        self.drawAnimationHelpers?.removeAll()
    }
    
    //MARK : - Helper
    
    func createFlightRoutes() {
        let lax = AGSPoint(x: -118.408075, y: 33.942536, spatialReference: AGSSpatialReference.wgs84())
        let lhr = AGSPoint(x: -0.461389, y: 51.4775, spatialReference: AGSSpatialReference.wgs84())
        let dxb = AGSPoint(x: 55.364444, y: 25.252778, spatialReference: AGSSpatialReference.wgs84())
        let hkg = AGSPoint(x: 113.914603, y: 22.308919, spatialReference: AGSSpatialReference.wgs84())
        let igt = AGSPoint(x: 77.0999578, y: 28.5561624, spatialReference: AGSSpatialReference.wgs84())
        let bom = AGSPoint(x: 72.8663173, y: 19.0926195, spatialReference: AGSSpatialReference.wgs84())
        let ccu = AGSPoint(x: 88.4463299, y: 22.6520429, spatialReference: AGSSpatialReference.wgs84())
        let cdg = AGSPoint(x: 2.5479245, y: 49.0096906, spatialReference: AGSSpatialReference.wgs84())
        let ist = AGSPoint(x: 28.814599990799998, y: 40.9768981934, spatialReference: AGSSpatialReference.wgs84())
        let opo = AGSPoint(x: -8.68138980865, y: 41.2481002808, spatialReference: AGSSpatialReference.wgs84())
        let nbo = AGSPoint(x: 36.9277992249, y: -1.31923997402, spatialReference: AGSSpatialReference.wgs84())
        let los = AGSPoint(x: 3.321160078048706, y: 6.5773701667785645, spatialReference: AGSSpatialReference.wgs84())
        let mji = AGSPoint(x: 13.276000022888184, y: 32.894100189208984, spatialReference: AGSSpatialReference.wgs84())
        let thr = AGSPoint(x: 51.31340026855469, y: 35.68920135498047, spatialReference: AGSSpatialReference.wgs84())
        let kix = AGSPoint(x: 135.24400329589844, y: 34.42729949951172, spatialReference: AGSSpatialReference.wgs84())
        let bkk = AGSPoint(x: 100.74700164794922, y: 13.681099891662598, spatialReference: AGSSpatialReference.wgs84())
        let sin = AGSPoint(x: 103.994003, y: 1.35019, spatialReference: AGSSpatialReference.wgs84())
        let yqb = AGSPoint(x: -71.393303, y: 46.7911, spatialReference: AGSSpatialReference.wgs84())
        let ymx = AGSPoint(x: -74.0386962891, y: 45.6795005798, spatialReference: AGSSpatialReference.wgs84())
        let yvr = AGSPoint(x: -123.183998108, y: 49.193901062, spatialReference: AGSSpatialReference.wgs84())
        let yyz = AGSPoint(x: -79.63059997559999, y: 43.6772003174, spatialReference: AGSSpatialReference.wgs84())
        let yeg = AGSPoint(x: -113.580001831, y: 53.309700012200004, spatialReference: AGSSpatialReference.wgs84())
        let ywg = AGSPoint(x: -97.2398986816, y: 49.909999847399995, spatialReference: AGSSpatialReference.wgs84())
        let jfk = AGSPoint(x: -73.77890015, y: 40.63980103, spatialReference: AGSSpatialReference.wgs84())
        let ord = AGSPoint(x: -87.90480042, y: 41.97859955, spatialReference: AGSSpatialReference.wgs84())
        let den = AGSPoint(x: -104.672996521, y: 39.861698150635, spatialReference: AGSSpatialReference.wgs84())
        let sfo = AGSPoint(x: -122.375, y: 37.61899948120117, spatialReference: AGSSpatialReference.wgs84())
        let phl = AGSPoint(x: -159.33900451660156, y: 21.97599983215332, spatialReference: AGSSpatialReference.wgs84())
        let atl = AGSPoint(x: -84.4281005859375, y: 33.63669967651367, spatialReference: AGSSpatialReference.wgs84())
        let dfw = AGSPoint(x: -97.03800201416016, y: 32.89680099487305, spatialReference: AGSSpatialReference.wgs84())
        let sea = AGSPoint(x: -122.30899810791016, y: 47.44900131225586, spatialReference: AGSSpatialReference.wgs84())
        let eze = AGSPoint(x: -58.5358, y: -34.8222, spatialReference: AGSSpatialReference.wgs84())
        let gru = AGSPoint(x: -46.47305679321289, y: -23.435556411743164, spatialReference: AGSSpatialReference.wgs84())
        let cun = AGSPoint(x: -86.8770980835, y: 21.036500930800003, spatialReference: AGSSpatialReference.wgs84())
        let mex = AGSPoint(x: -99.072098, y: 19.4363, spatialReference: AGSSpatialReference.wgs84())
        
        let points = [lax, dxb, hkg, igt, bom, ccu, cdg, ist, opo, nbo, los, mji, thr, kix, bkk, sin, yqb, ymx, yvr, yyz, yeg, ywg, jfk, ord, den, sfo, phl, atl, dfw, sea, eze, gru, cun, mex]
        
        self.mapView.setViewpointCenter(lhr, scale: 6750011.74, completion: nil)
        
        let airportSymbol = AGSSimpleMarkerSymbol(style: .circle, color: UIColor.brown, size: 15)
        let airportGraphic = AGSGraphic(geometry: lhr, symbol: airportSymbol, attributes: nil)
        self.airportGraphicsOverlay.graphics.add(airportGraphic)
        
        self.flightPaths = [AGSPolyline]()
        
        let symbol = AGSSimpleLineSymbol(style: .solid, color: UIColor.orange, width: 2)
        
        for point in points {
            let polyline = AGSPolyline(points: [lhr, point])
            let geodesicPolyline = AGSGeometryEngine.geodeticDensifyGeometry(polyline, maxSegmentLength: 100, lengthUnit: AGSLinearUnit.kilometers(), curveType: AGSGeodeticCurveType.normalSection) as! AGSPolyline
            let projectedPolyline = AGSGeometryEngine.projectGeometry(geodesicPolyline, to: AGSSpatialReference.webMercator()) as! AGSPolyline
            self.flightPaths.append(projectedPolyline)
            
            //add graphic to hidden route graphicsOverlay
            let graphic = AGSGraphic(geometry: geodesicPolyline, symbol: symbol, attributes: nil)
            self.hiddenRouteGraphicsOverlay.graphics.add(graphic)
        }
    }

    private func randomColor() -> UIColor {
        //let r = CGFloat(arc4random_uniform(255)) / 255.0
        //let g = CGFloat(arc4random_uniform(255)) / 255.0
        //let b = CGFloat(arc4random_uniform(255)) / 255.0
        //return UIColor(red: r, green: g, blue: b, alpha: 1)
        
        let h = CGFloat(arc4random_uniform(255)) / 255.0
        return UIColor(hue: h, saturation: 1, brightness: 0.7, alpha: 1)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
