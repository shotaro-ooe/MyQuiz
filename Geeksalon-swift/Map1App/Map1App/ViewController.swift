//
//  ViewController.swift
//  Map1App
//
//  Created by 大江祥太郎 on 2018/12/15.
//  Copyright © 2018年 shotaro. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

class ViewController: UIViewController ,UISearchBarDelegate, CLLocationManagerDelegate, MKMapViewDelegate{
    
    @IBOutlet weak var mySearchBar: UISearchBar!
    
    var myLocationManager:CLLocationManager!
    
    var userAnnotation :MKPointAnnotation!
    
    var userLatitude:CLLocationDegrees!// 取得した現在地の緯度を保持するインスタンス
    var userLongitude: CLLocationDegrees!    // 取得した現在地の経度を保持するインスタンス

    

    @IBOutlet weak var mapView: MKMapView!
    
    var userDefName = "pins"
    override func viewDidLoad() {
        super.viewDidLoad()
        //保存されているピンを配置
        loadPins()
        
        //課題の追加
        //location manager の生成
        myLocationManager = CLLocationManager()
        
        //locationManagerのDelegateの生成
        myLocationManager.delegate = self
        
        //位置情報の精度を指定、任地
        myLocationManager.desiredAccuracy = kCLLocationAccuracyKilometer
        
        // 位置情報取得間隔を指定．指定した値（メートル）移動したら位置情報を更新する．任意．
        myLocationManager.distanceFilter = 1000.0
        
        // 位置情報取得の許可を求めるメッセージの表示．必須．
        
        myLocationManager.requestWhenInUseAuthorization()
        
        //インスタンス化(実体化)
        userAnnotation = MKPointAnnotation()
        userLatitude = CLLocationDegrees()
        userLongitude = CLLocationDegrees()
        
        region = MKCoordinateRegion()
        
        //モデルのインスタンス化
        userAndDestination = UserAndDestinationModel()
        
        
    }

    @IBAction func longTapMapView(_ sender: UILongPressGestureRecognizer) {
        if sender.state != UIGestureRecognizer.State.began{
            //ロングタップ以外では認識しない
            return
        }
        print("longtapしました。")
        
        //位置情報の取得
        let point = sender.location(in: mapView)
        let geo = mapView.convert(point, toCoordinateFrom: mapView)
        //アラートの作成
        let alert = UIAlertController(title: "スポット登録", message: "この場所に残すメッセージを入力してください。", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "キャンセル", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "登録", style: .default, handler: { (action: UIAlertAction) -> Void in
            // 登録アクション
            let pin = Pin(geo: geo, text: alert.textFields?.first?.text)
            
            self.mapView.addAnnotation(pin)
            
            self.savePin(pin)
        }))
        
        //ピンに登録するテキスト用の入力フィールドをアラートに追加します
        alert.addTextField { (textFiled:UITextField) in
            textFiled.placeholder = "メッセージ"
        }
        
        //アラートの表示
        present(alert, animated: true, completion: nil)
    }
    
    //addAnnotationした際に呼ばれるデリゲート
    //表示関係のメソッド
    @available(iOS 11.0, *)
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        let pinView = MKMarkerAnnotationView()
        
        
        if annotation === mapView.userLocation {
            // 現在地を示すアノテーションの場合はデフォルトのまま
            return nil //nilを返すことで現在地がピンにならない
        }
        
        pinView.annotation = annotation
        
        //ピンの色
        pinView.markerTintColor = UIColor.blue
        
        pinView.animatesWhenAdded = true
        
        return pinView
    }
    
    //pinの保存
    func savePin(_ pin:Pin){
        let ud = UserDefaults.standard
        
        //保存するPinをUserdefaults用に変換します
        let pinInfo = pin.toDictionary()
        
        if var savedPins = ud.object(forKey: userDefName)as? [[String:Any]]{
            //すでにPinデータがある場合、それに追加する形で保存します
            savedPins.append(pinInfo)
            ud.set(savedPins, forKey: userDefName)
        }else{
            //まだ保存データがない場合、新しい配列に保存する
            let newSavedPins :[[String:Any]] = [pinInfo]
            
            ud.set(newSavedPins, forKey: userDefName)
        }
    }
    
    //すでに保存されているピンを取得
    func loadPins(){
        let ud = UserDefaults.standard
        if let savedPins = ud.object(forKey: userDefName) as? [[String:Any]]{
            //現在のピンを消去
            self.mapView.removeAnnotations(self.mapView.annotations)
            
            for pinInfo in savedPins{
                let newPin = Pin(dictionary: pinInfo)
                
                self.mapView.addAnnotation(newPin)
            }
        }
    }
    
    //位置情報利用のステータスが変わった(didChangeAuthorization status)
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedAlways, .authorizedWhenInUse:
            myLocationManager.startUpdatingLocation()
            
        default:
            
            //ロケーションの更新を停止する
            myLocationManager.stopUpdatingLocation()
        }
    }
    
    //位置情報取得失敗した時に呼ばれる関数
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(error.localizedDescription)
    }
    
    /* 現在の位置情報取得成功時に実行される関数 */
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        print("\ngot UserLocation!!!\n")
        
        let newLocation = locations.last
        // 取得した緯度がnewLocation.coordinate.latitudeに格納されている
        userLatitude = newLocation!.coordinate.latitude
        // 取得した経度がnewLocation.coordinate.longitudeに格納されている
        userLongitude = newLocation!.coordinate.longitude
        
        //取得した緯度経度から変換
        let userLocation:CLLocationCoordinate2D  = CLLocationCoordinate2DMake(userLatitude,userLongitude)
        
        userAnnotation = MKPointAnnotation()
        
        //ピンに座標を入れて
        userAnnotation.coordinate = userLocation
        
        //ピンをマップ上に立てる
        mapView.addAnnotation(userAnnotation)
        
        // 取得した緯度・経度をLogに表示
        print("latitude: \(String(describing: userLatitude)) , longitude: \(String(describing: userLongitude))")
        
        // GPSの使用を停止する．停止しない限りGPSは実行され，指定間隔で更新され続ける．
        myLocationManager.stopUpdatingLocation()
        
        /*  didUpdateLocationsのコールバックが複数回返ってくるので
         delegateに対してnilを入れることで2度目のコールバックが呼ばれる事をブロックしました。*/
        self.myLocationManager.delegate = nil
    }
    
    /*
     * 検索ボタン押下時の呼び出しメソッド
     */
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        
        //キーボードを閉じる。
        mapSearchBar.resignFirstResponder()
        
        //検索条件を作成する。
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = mapSearchBar.text!
        
        //検索範囲はマップビューと同じにする。
        request.region = mapView.region
        
        //ローカル検索を実行する。
        let localSearch:MKLocalSearch = MKLocalSearch(request: request)
        localSearch.start(completionHandler: {(result, error) in
            
            //検索結果がnilじゃないとき（nilだとfor...inできない）
            if result?.mapItems != nil{
                
                for placemark in (result?.mapItems)! {
                    
                    //エラーなし
                    if(error == nil) {
                        
                        //検索された場所にピンを刺す。
                        
                        //ピン生成
                        self.searchedPin = MKPointAnnotation()
                        
                        //ピンに座標を入れる
                        self.searchedPin?.coordinate = CLLocationCoordinate2DMake(
                            placemark.placemark.coordinate.latitude, placemark.placemark.coordinate.longitude)
                        
                        //タイトル、サブタイトルをつける
                        self.searchedPin?.title = placemark.placemark.name
                        self.searchedPin?.subtitle = placemark.placemark.title
                        
                        //ピンを刺す
                        self.mapView.addAnnotation(self.searchedPin!)
                        
                        //表示範囲を計算するモデルのメソッドを呼んであげている
                        self.userAndDestination.showUserAndDestinationOnMap(userLatitude: self.userLatitude, userLongitude: self.userLongitude, annotation: self.searchedPin, mapView: self.mapView)
                        
                        self.region = self.userAndDestination.region
                        
                        //表示範囲を画面上の地図に反映
                        self.getShowRegion(mapView: self.mapView, region: self.region)
                        
                        print(self.region.center)
                        
                        print(self.userLatitude)
                        print(self.userLongitude)
                        
                        
                        
                        //検索が終了したアラートを出す
                        let title = "検索が完了しました"
                        let message = "OKを押して続けてください"
                        self.showAlert(title:title, message:message)
                        
                    } else {
                        
                        
                        print(placemark.placemark.name!)
                        print(placemark.placemark.title!)
                        
                        //エラー
                        print("error!")
                    }
                }
            }else{
                
                //検索結果がnilのとき検索失敗のアラートを出す
                let title = "検索できませんでした"
                let message = "別の言葉で試してみてください"
                self.showAlert(title:title, message:message)
                
                
            }
        })
    }

    
    @IBAction func pressedDelete(_ sender: Any) {
        //削除されたとき用のアラート
        let deleteAlart = UIAlertController(title: "ピンの削除", message: "保存されているすべてのピンを削除します", preferredStyle: .alert)
        deleteAlart.addAction(UIAlertAction(title: "キャンセル", style: .cancel, handler: nil))
        deleteAlart.addAction(UIAlertAction(title: "削除", style: .destructive, handler: {(acition) in
            //アラート上の「削除」が押されたら実際に削除する
            let userDafaults = UserDefaults.standard
            userDafaults.removeObject(forKey: self.userDefName)
            userDafaults.set([[:]], forKey: self.userDefName)
            self.mapView.removeAnnotations(self.mapView.annotations)
        }))
        
        present(deleteAlart, animated: true, completion: nil)

    }
    
    
}

