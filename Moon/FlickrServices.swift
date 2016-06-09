 //
//  FlickrServices.swift
//  Moon
//
//  Created by Evan Noble on 6/7/16.
//  Copyright © 2016 Evan Noble. All rights reserved.
//

import Alamofire
import SwiftyJSON

protocol FlickrPhotoDownloadDelegate {
    func finishedDownloading(photos:[Photo])
}

class FlickrServices {
    
    let API_KEY = "02e3fda4a4c12689e036825fad02bc64"
    let URL = "https://api.flickr.com/services/rest/"
    let METHOD = "flickr.photos.search"
    let FORMAT_TYPE:String = "json"
    let JSON_CALLBACK:Int = 1
    let PRIVACY_FILTER:Int = 1
    
    var delegate:FlickrPhotoDownloadDelegate?
    
    // MARK:- Service Call
    
    func makeServiceCall(searchText: String) {
        
        let request = Alamofire.request(.GET, URL, parameters:  ["method": METHOD, "api_key": API_KEY, "tags":searchText,"privacy_filter":PRIVACY_FILTER, "format":FORMAT_TYPE, "nojsoncallback": JSON_CALLBACK])
        request.validate().responseJSON { (response) in
            if response.data != nil {
                
                let data = JSON(data: response.data!)
                let photoInfo = data["photos"]["photo"]
                let randomIndex = Int(arc4random_uniform(UInt32(photoInfo.count)))
                let photoUrlData = photoInfo[randomIndex]
                
                var photos = [Photo]()
                
    
                let id = photoUrlData["id"].stringValue
                let farm = photoUrlData["farm"].stringValue
                let server = photoUrlData["server"].stringValue
                let secret = photoUrlData["secret"].stringValue
                let title = photoUrlData["title"].stringValue
                let photo = Photo(id:id, title:title, farm:farm, secret: secret, server: server)
                photos.append(photo)
                
                self.delegate?.finishedDownloading(photos)
            } else {
                // TODO: Check for errors
            }
        }
    }
}