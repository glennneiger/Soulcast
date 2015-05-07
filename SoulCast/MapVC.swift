

import UIKit
import MapKit

protocol mapVCDelegate {
  func mapVCDidChangeradius(radius:Double)
}

class MapVC: UIViewController {
  
  let mapView = MKMapView()
  let locationManager = CLLocationManager()
  var permissionView: UIView!
  var latestLocation: CLLocation? {
    get {
      if let savedLatitude = Device.localDevice.latitude {
        if let savedLongitude = Device.localDevice.longitude {
          return CLLocation(latitude: savedLatitude, longitude: savedLongitude)
        }
      }
      return CLLocation(latitude: 49.2812277842772, longitude: -122.956074765067)
    }
    set (newValue) {
      let updatingDevice = Device.localDevice
      updatingDevice.latitude = newValue?.coordinate.latitude
      updatingDevice.longitude = newValue?.coordinate.longitude
      Device.localDevice = updatingDevice
    }
  }
  var userSpan: MKCoordinateSpan! {
    get {
      if let savedRadius = Device.localDevice.radius {
        
        return MKCoordinateSpanMake(savedRadius, savedRadius)
      } else {
        return MKCoordinateSpanMake(0.03, 0.03)
      }
    }
    set (newValue) {
      let updatingDevice = Device.localDevice
      updatingDevice.radius = newValue.latitudeDelta
      Device.localDevice = updatingDevice
    }
  }
  var originalRegion: MKCoordinateRegion?
  var radiusLabel: UILabel!
  var devicesLabel: UILabel!
  var devicesLabelUpdating = false
  
  override func viewDidLoad() {
    super.viewDidLoad()
    addMap()
    addLabels()
    
  }
  
  override func viewWillAppear(animated: Bool) {
    super.viewWillAppear(animated)
    monitorLocation()
  }
  
  override func viewDidAppear(animated: Bool) {
    super.viewDidAppear(animated)
    manualAskLocationPermission()
  }
  
  
  func saveRegionData() {
    if let location = latestLocation {
      if let span = userSpan {
        deviceManager.updateDeviceRegion(latitude: location.coordinate.latitude as Double, longitude: location.coordinate.longitude as Double, radius: span.latitudeDelta as Double)
      }
    }
  }

  func addMap() {
    mapView.frame = CGRectMake(0, 0, view.frame.size.width, view.frame.size.height*0.9)
    mapView.mapType = .Standard
    mapView.scrollEnabled = false
    mapView.rotateEnabled = false
    mapView.zoomEnabled = false
    mapView.showsUserLocation = true
    if let location = latestLocation {
      if let span = userSpan {
        
        mapView.setRegion(MKCoordinateRegionMake(location.coordinate, span), animated: true)
        
      }
    }
    mapView.delegate = self
    view.addSubview(mapView)
    
    addPinchGestureRecognizer()
  }
  
  func addPinchGestureRecognizer() {
    let pinchRecognizer = UIPinchGestureRecognizer(target: self, action: "didPanOnMapView:")
    mapView.addGestureRecognizer(pinchRecognizer)
  }
  
  func didPanOnMapView(pinchRecognizer:UIPinchGestureRecognizer) {
    switch pinchRecognizer.state {
    case .Began:
      originalRegion = mapView.region
    case .Changed:
      var latitudeDelta = Double(originalRegion!.span.latitudeDelta) / Double(pinchRecognizer.scale)
      var longitudeDelta = Double(originalRegion!.span.longitudeDelta) / Double(pinchRecognizer.scale);
      latitudeDelta = max(min(latitudeDelta, 10), 0.0005);
      longitudeDelta = max(min(longitudeDelta, 10), 0.0005);
      userSpan = MKCoordinateSpanMake(latitudeDelta, longitudeDelta)
      updateRadiusLabel(latitudeDelta)
      updateDevicesLabel()
      self.mapView.setRegion(MKCoordinateRegionMake(originalRegion!.center, userSpan!), animated: false)
    case .Ended:
      saveRegionData()
      
      break
    default:
    break
    }
    
  }
  
  func monitorLocation() {
    locationManager.delegate = self
    locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    locationManager.distanceFilter = 10
    locationManager.startUpdatingLocation()
  }
  
  func hasLocationPermission() -> Bool {
    return CLLocationManager.authorizationStatus() == .AuthorizedAlways || CLLocationManager.authorizationStatus() == .AuthorizedWhenInUse
  }
  
  func manualAskLocationPermission() {
    if CLLocationManager.authorizationStatus() == CLAuthorizationStatus.NotDetermined {
      //ask manually for permission.
      let locationAlert = UIAlertController(title: "Allow location?", message: "SoulCast needs it to listen to those around you", preferredStyle: .Alert)
      let cancelAction = UIAlertAction(title: "cancel", style: .Default, handler: { (action:UIAlertAction!) -> Void in
        //TODO: overlay stuff on MapView, allowing them to ask location permission again.
        
      })
      let successAction = UIAlertAction(title: "OK", style: .Default, handler: { (action:UIAlertAction!) -> Void in
        self.systemAskLocationPermission()
        
      })
      locationAlert.addAction(cancelAction)
      locationAlert.addAction(successAction)
      
      presentViewController(locationAlert, animated: true, completion: { () -> Void in
        //
      })
    }
    

  }
  
  func addPermissionView() {
    permissionView = UIView(frame: mapView.frame)
    permissionView.backgroundColor = UIColor.darkGrayColor().colorWithAlphaComponent(0.3)
    
    let permissionLabel = UILabel(frame: CGRectMake(0, 0, mapView.frame.size.width, 200))
    permissionLabel.center = mapView.center
    permissionLabel.text = "ALLOW LOCATION PERMISSION"
    permissionLabel.textAlignment = .Center
    permissionLabel.font = UIFont(name: "Helvetica", size: 20)
    permissionLabel.textColor = UIColor.whiteColor().colorWithAlphaComponent(0.85)
    permissionView.addSubview(permissionLabel)
    
    let permissionTapRecognizer = UITapGestureRecognizer(target: self, action: "permissionViewTapped:")
    permissionView.addGestureRecognizer(permissionTapRecognizer)
    
    view.addSubview(permissionView)
  }
  
  func permissionViewTapped(recognizer:UIGestureRecognizer) {
    recognizer.removeTarget(self, action: "permissionViewTapped:")
    manualAskLocationPermission()
  }
  
  func systemAskLocationPermission() {
    if locationManager.respondsToSelector("requestAlwaysAuthorization") {
      locationManager.requestAlwaysAuthorization()
    }
    if locationManager.respondsToSelector("requestWhenInUseAuthorization") {
      locationManager.requestWhenInUseAuthorization()
    }
  }
  
  func addLabels() {
    radiusLabel = UILabel(frame: CGRect(x: view.frame.width - 180, y: 0, width: 180, height: 50))
    radiusLabel.text = "Radius: " +  "  km"
    radiusLabel.decorateWhite(15)
    radiusLabel.textAlignment = .Right
    view.addSubview(radiusLabel)
    
    devicesLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 160, height: 50))
    devicesLabel.text = "No others nearby"
    devicesLabel.decorateWhite(15)
    devicesLabel.textAlignment = .Left
    view.addSubview(devicesLabel)
    updateDevicesLabel()
  }
  
  func updateRadiusLabel(delta:Double) {
    // one degree of latitude is always approximately 111 kilometers (69 miles).
    radiusLabel.text = "Radius: " + String(format:"%.1f", (delta * 111 / 2)) + " km"
    
  }
  
  func updateDevicesLabel() {
    if devicesLabelUpdating {
      return
    }
    devicesLabelUpdating = true
    if Device.localDevice.radius != nil {
      networkRequestManager().GET(serverURL + othersQuerySuffix, parameters: Device.localDevice.toParams(), success: { (operation: AFHTTPRequestOperation!, response: AnyObject!) -> Void in
        self.devicesLabelUpdating = false
        let params = response as! NSDictionary
        let nearby = params["nearby"] as! Int
        var newText = ""
        if nearby == 0 {
          newText = "No others nearby"
        } else if nearby == 1 {
          newText = String(nearby) + " other nearby"
        } else {
          newText = String(nearby) + " others nearby"
        }
        self.devicesLabel.text = newText
        
        }, failure: { (operation: AFHTTPRequestOperation!, error: NSError!) -> Void in
        println("updateDevicesLabel error: \(error)")
      })
    }
  }
  
  
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
  
  
  
}

extension MapVC: MKMapViewDelegate {
  func mapView(mapView: MKMapView!, didUpdateUserLocation userLocation: MKUserLocation!) {
    let mapRegion = MKCoordinateRegion(center: mapView.userLocation.coordinate, span: userSpan!)
    mapView.setRegion(mapRegion, animated: true)
    
  }
  
  func mapView(mapView: MKMapView!, regionDidChangeAnimated animated: Bool) {
    updateRadiusLabel(mapView.region.span.latitudeDelta)
  }
  
  func mapView(mapView: MKMapView!, regionWillChangeAnimated animated: Bool) {
    //
  }
}

extension MapVC: CLLocationManagerDelegate {
  func locationManager(manager: CLLocationManager!, didUpdateLocations locations: [AnyObject]!) {
    //update location
    if let previousLocation = latestLocation {
      let distance = (locations.last as? CLLocation)?.distanceFromLocation(previousLocation)
      if distance > 50 {
        
      } else {
        //do nothing interesting
      }
    }
    manager.stopUpdatingLocation()
    NSTimer.scheduledTimerWithTimeInterval(30, target: self, selector: "restartLocationUpdates:", userInfo: nil, repeats: false)
    latestLocation = locations.last as? CLLocation
    saveRegionData()
    
  }
  
  func restartLocationUpdates(timer: NSTimer) {
    timer.invalidate()
    locationManager.startUpdatingLocation()
    
    
  }
  
}
