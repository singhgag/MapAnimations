//
//  CarsAnimationViewController.swift
//  MapAnimations
//
//  Created by Gagandeep Singh on 3/3/17.
//  Copyright © 2017 Gagandeep Singh. All rights reserved.
//

import UIKit
import ArcGIS

class CarsAnimationViewController: UIViewController {

    @IBOutlet var mapView:AGSMapView!
    
    let filenames = ["Trip1", "Trip2", "Trip3", "Trip4", "Trip5", "Trip6", "Trip7", "Trip8", "Trip9", "Trip10", "Trip11", "Trip12", "Trip13"]
    
    private var hiddenGraphicsOverlay = AGSGraphicsOverlay()
    private var carsGraphicsOverlay = AGSGraphicsOverlay()
    private var paths:[AGSPolyline]!
    private var animationHelpers:[AnimateAlongPathHelper]!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        //initialize map with vector basemap
        let map = AGSMap(basemap: AGSBasemap.topographic())
        
        //assign map to the map view
        self.mapView.map = map
        
        self.mapView.interactionOptions.isRotateEnabled = false
        
        //add the graphics overlays to the map view
        self.mapView.graphicsOverlays.addObjects(from: [carsGraphicsOverlay])
        
        //zoom to viewpoint
        self.mapView.setViewpointCenter(AGSPoint(x: -13040126.830260, y: 3857243.727160, spatialReference: AGSSpatialReference(wkid: 3857)), scale: 40391.247274802692, completion: nil)
        
        //
        self.createPaths()
    }
    
    private func createPaths() {
        self.paths = [AGSPolyline]()
        self.animationHelpers = [AnimateAlongPathHelper]()
        
        let pathSymbol = AGSSimpleLineSymbol(style: .solid, color: UIColor.blue, width: 4)
        
        for filename in filenames {
            let polyline = self.geometryFromTextFile(filename: filename) as! AGSPolyline
            self.paths.append(polyline)
            
            let pathGraphic = AGSGraphic(geometry: polyline, symbol: pathSymbol, attributes: nil)
            self.hiddenGraphicsOverlay.graphics.add(pathGraphic)
        }
    }
    
    @IBAction func simulate() {
        
        for path in self.paths {
            
            let symbol = AGSPictureMarkerSymbol(image: UIImage(named: "Car")!)
            let graphic = AGSGraphic(geometry: path.parts[0].points[0], symbol: symbol, attributes: nil)
            self.carsGraphicsOverlay.graphics.add(graphic)
            
            let helper = AnimateAlongPathHelper(polyline: path, animatingGraphic: graphic, speed: 40)
            helper.startAnimation()
            self.animationHelpers.append(helper)
        }
    }
    
    @IBAction func switchValueChanged(sender:UISwitch) {
        if sender.isOn {
            self.mapView.graphicsOverlays.insert(self.hiddenGraphicsOverlay, at: 0)
        }
        else {
            self.mapView.graphicsOverlays.remove(self.hiddenGraphicsOverlay)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    //MARK: - Helper methods
    
    func geometryFromTextFile(filename:String) -> AGSGeometry? {
        if let filepath = Bundle.main.path(forResource: filename, ofType: "txt") {
            if let jsonString = try? String(contentsOfFile: filepath, encoding: String.Encoding.utf8) {
                let data = jsonString.data(using: String.Encoding.utf8, allowLossyConversion: false)
                let dictionary = (try! JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions())) as! [NSObject:AnyObject]
                let geometry = try? AGSGeometry.fromJSON(dictionary)
                return geometry as? AGSGeometry
            }
        }
        
        return nil
    }
}
