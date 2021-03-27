//
//  ApiRequestManager.swift
//  JSApiSdk
//
//  Created by iMac on 26/03/21.
//

import Foundation
import SystemConfiguration
import Alamofire

public class ApiRequestManager {
    public static let sharedInstance = ApiRequestManager()
    var responseObjectDic = Dictionary<String, AnyObject>()
    var URLString : String!
    var Message : String!
    var resObjects:AnyObject!
    var alamofireManager = Session.default
    public var additionalHeaders: HTTPHeaders = []
    var strAccessToken = ""
    
    //MARK:- Init Alamofire Method
    init() {
        AF.sessionConfiguration.timeoutIntervalForRequest = 60000000
    }
    
    /*
     headers = pass the headers for each request
     endpointurl = it is a combination of server base url and name of api
     parameters = pass the respective parameters to the request
     tokenType = pass the value of which kind of token is used. eg. Bearer, VerifyToken etc.
     accessToken = pass the authentication token for authorization
     Note: In parameters, for image = pass the image data and for audio/video/document upload = pass the local URL of it
     */
    
    //MARK:- Setup Request Parameters Method
    public func setupRequestParameters(isToken: Bool, accessToken: String, tokenType: String, methodName: HTTPMethod, endpointURL: String, apiName: String, headers: HTTPHeaders, parameters: [String:Any]?, responseData:@escaping  (_ error: NSError?,_ responseArray: NSArray?, _ responseDict: NSDictionary?, _ errorMessage: String?, _ statusCode: Int) -> Void) {
        if !isDeviceConnectedToNetwork() {
            responseData(nil, nil, nil, "Sorry! You're not connected to network.", 0)
            
        } else {
            if isToken {
                if tokenType.count > 0, tokenType == "",
                   accessToken.count == 0, accessToken == "" {
                    responseData(nil, nil, nil, "Please provide access token", 0)
                    return
                } else {
                    self.strAccessToken = "\(tokenType) \(accessToken)"
                }
            } else {
                self.strAccessToken = ""
            }
            self.additionalHeaders = headers
            
            if methodName == .get {
                self.getRequest(endpointurl: endpointURL, service: apiName) { (error, resArr, resDict, message, statusCode) in
                    responseData(error, resArr, resDict, message, statusCode)
                }
                
            } else if methodName == .post {
                self.postRequest(endpointurl: endpointURL, service: apiName, parameters: parameters ?? [:]) { (error, resArr, resDict, message, statusCode) in
                    responseData(error, resArr, resDict, message, statusCode)
                }
                
            } else if methodName == .delete {
                self.deleteRequest(endpointurl: endpointURL, service: apiName, parameters: parameters ?? [:]) { (error, resArr, resDict, message, statusCode) in
                    responseData(error, resArr, resDict, message, statusCode)
                }
                
            } else if methodName == .put {
                self.putRequest(endpointurl: endpointURL, service: apiName, parameters: parameters ?? [:]) { (error, resArr, resDict, message, statusCode) in
                    responseData(error, resArr, resDict, message, statusCode)
                }
                
            } else if methodName == .patch {
                self.patchRequest(endpointurl: endpointURL, service: apiName, parameters: parameters ?? [:]) { (error, resArr, resDict, message, statusCode) in
                    responseData(error, resArr, resDict, message, statusCode)
                }
            }
        }
    }
    
    /*
     headers = pass the headers for each request
     endpointurl = it is a combination of server base url and name of api
     isImage = if it is image then pass true otherwise false
     strAppName = pass the name of the application to use it for filename while uploading
     parameters = pass the respective parameters to the request
     tokenType = pass the value of which kind of token is used. eg. Bearer, VerifyToken etc.
     accessToken = pass the authentication token for authorization
     Note: In parameters, for image = pass the image data and for audio/video/document upload = pass the local URL of it
     */
    
    //MARK:- Setup Multipart Request Parameters Method
    public func setupMultipartRequestParameters(isImage: Bool, accessToken: String, tokenType: String, endpointURL: String, apiName: String, headers: HTTPHeaders, parameters: [String:Any], responseData:@escaping (_ error: NSError?, _ responseDict: AnyObject?, _ errorMessage: String?, _ statusCode: Int) -> Void) {
        
        if !isDeviceConnectedToNetwork() {
            responseData(nil, nil, "Sorry! You're not connected to network.", 0)
            
        } else {
            if tokenType.count == 0, tokenType == "",
               accessToken.count == 0, accessToken == "" {
                responseData(nil, nil, "Please provide access token", 0)
                return
            } else {
                self.strAccessToken = "\(tokenType) \(accessToken)"
            }
            self.additionalHeaders = headers

            self.requestWithPostMultipartParam(endpointurl: endpointURL, isImage: isImage, strAppName: apiName, parameters: parameters as NSDictionary) { (error, resDict, errMessage, statusCode) in
                responseData(error, resDict, errMessage, statusCode)
            }
        }
    }
    
    //MARK:- Connect to network Method
    func isDeviceConnectedToNetwork() -> Bool {
        var zeroAddress = sockaddr_in()
        zeroAddress.sin_len = UInt8(MemoryLayout.size(ofValue: zeroAddress))
        zeroAddress.sin_family = sa_family_t(AF_INET)
        
        guard let defaultRouteReachability = withUnsafePointer(to: &zeroAddress, {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {zeroSockAddress in
                SCNetworkReachabilityCreateWithAddress(nil, zeroSockAddress)
            }
        })
        else {
            return false
        }
        
        var flags : SCNetworkReachabilityFlags = []
        if !SCNetworkReachabilityGetFlags(defaultRouteReachability, &flags) {
            return false
        }
        
        let isReachable = flags.contains(.reachable)
        let needsConnection = flags.contains(.connectionRequired)
        let available =  (isReachable && !needsConnection)
        if(available) {
            return true
        } else {
            print("No network available")
            return false
        }
    }
    
    //MARK:- GET Method
    func getRequest(endpointurl:String, service: String, responseData:@escaping  (_ error: NSError?,_ responseArray: NSArray?, _ responseDict: NSDictionary?, _ errorMessage: String?, _ statusCode: Int) -> Void) {
        
        AF.request(endpointurl, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: additionalHeaders).responseJSON { (responseString)-> Void in
            
            print("response obj : \(responseString.value ?? "")")
            
            if let responseHttpURL = responseString.response {
                if responseHttpURL.statusCode == 200 {
                    if(responseString.value == nil) {
                        responseData(responseString.error as NSError?,nil,nil,"",responseHttpURL.statusCode)
                    } else {
                        self.resObjects = responseString.value as AnyObject
                        responseData(nil,nil,self.resObjects as? NSDictionary,"",responseHttpURL.statusCode)
                    }
                } else {
                    self.resObjects = responseString.value as AnyObject
                    if let errodict = self.resObjects as? [String : Any] {
                        let errMsg = self.showErrorMessages(myDict: errodict, withCode: responseString.response?.statusCode ?? 0)
                        responseData(nil,nil,nil, errMsg,responseHttpURL.statusCode)
                        
                    } else {
                        responseData(nil,nil,nil, "Server Response Error",responseHttpURL.statusCode)
                    }
                }
            } else {
                responseData(nil,nil,nil, "Oops! Request timed out!",responseString.response?.statusCode ?? 0)
            }
        }
    }
    
    //MARK:- POST Method
    func postRequest(endpointurl:String, service: String, parameters: [String:Any], responseData:@escaping  (_ error: NSError?,_ responseArray: NSArray?, _ responseDict: NSDictionary?, _ errorMessage: String?, _ statusCode: Int) -> Void) {
        
        AF.request(endpointurl, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: additionalHeaders).responseJSON { (responseString)-> Void in
            
            //                printMsg(val: "response obj : \(responseString.value ?? "")")
            
            if let responseHttpURL = responseString.response {
                if responseHttpURL.statusCode == 200 {
                    if(responseString.value == nil) {
                        responseData(responseString.error as NSError?,nil,nil,"",responseHttpURL.statusCode)
                        
                    } else {
                        self.resObjects = responseString.value as AnyObject
                        responseData(nil,nil,self.resObjects as? NSDictionary,"",responseHttpURL.statusCode)
                    }
                } else {
                    self.resObjects = responseString.value as AnyObject
                    if let errodict = self.resObjects as? [String : Any] {
                        let errMsg = self.showErrorMessages(myDict: errodict, withCode: responseString.response?.statusCode ?? 0)
                        responseData(nil,nil,nil, errMsg,responseHttpURL.statusCode)
                        
                    } else {
                        responseData(nil,nil,nil, "ServerResponseError",responseHttpURL.statusCode)
                    }
                }
            } else {
                responseData(nil,nil,nil, "Oops! Request timed out!",responseString.response?.statusCode ?? 0)
            }
        }
    }
        
    //MARK:- Multipart Form Data Method
    func requestWithPostMultipartParam(endpointurl:String, isImage: Bool, strAppName: String, parameters:NSDictionary, responseData:@escaping (_ error: NSError?, _ responseDict: AnyObject?, _ errorMessage: String?, _ statusCode: Int) -> Void) {
        
        
//        additionalHeaders = []
//        additionalHeaders.add(name: "Content-type", value: "multipart/form-data")
//        additionalHeaders.add(name: "Accept", value: "application/json")
        //            additionalHeaders.add(name: "Authorization", value: "Bearer \(self.getToken())")
        
        AF.upload(multipartFormData: { (multipartFormData) in
            for (key, value) in parameters {
                if value is Data {
                    if isImage {
                        //Image
                        if let myvalue = value as? Data,
                           let mykey = key as? String {
                            multipartFormData.append(myvalue, withName: mykey, fileName: "\(strAppName).jpg", mimeType: "image/jpeg")
                        }
                    }
                } else if value is URL {
                    //Audio, video and document upload
                    if let url = value as? URL {
                        let fileExt = (url.lastPathComponent.components(separatedBy: ".").last!).lowercased()
                        var mime = ""
                        
                        switch fileExt {
                        case "xls":
                            mime = "application/vnd.ms-excel"
                            break
                        case "xlsx":
                            mime = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
                            break
                        case "doc":
                            mime = "application/msword"
                            break
                        case "docx":
                            mime = "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
                            break
                        case "pdf":
                            mime = "application/pdf"
                            break
                        case "rtf":
                            mime = "application/rtf"
                            break
                        case "txt":
                            mime = "text/plain"
                            break
                        case "mpg":
                            mime = "video/mpg"
                            break
                        case "mpeg":
                            mime = "video/mpeg"
                            break
                        case "mpe":
                            mime = "video/mpe"
                            break
                        case "mpv":
                            mime = "video/mpv"
                            break
                        case "ogg":
                            mime = "video/ogg"
                            break
                        case "mp4":
                            mime = "video/mp4"
                            break
                        case "m4p":
                            mime = "video/m4p"
                            break
                        case "m4v":
                            mime = "video/m4v"
                            break
                        case "avi":
                            mime = "video/avi"
                            break
                        case "wmv":
                            mime = "video/wmv"
                            break
                        case "mov":
                            mime = "video/mov"
                            break
                        case "flv":
                            mime = "video/flv"
                            break
                        case "m4a":
                            mime = "audio/m4a"
                            break
                        case "mp3":
                            mime = "audio/mp3"
                            break
                        default:
                            break
                        }
                        
                        var fileData:Data? = nil
                        do {
                            fileData = try Data.init(contentsOf: url)
                            if let mydata = fileData,
                               let mykey = key as? String {
                                multipartFormData.append(mydata, withName: mykey, fileName: "\(strAppName).\(fileExt)", mimeType: mime)
                            }
                        }catch{
                            print(error.localizedDescription)
                        }
                    }
                }
                else {
                    if let mydata = "\(value)".data(using: String.Encoding.utf8) {
                        multipartFormData.append(mydata, withName: key as? String ?? "")
                    }
                }
            }
        },to: endpointurl, usingThreshold: UInt64.init(),
        method: .post,
        headers: additionalHeaders).responseJSON { (responseString)-> Void in
            
            //                printMsg(val: "response obj : \(responseString.value)")
            
            if let responseHttpURL = responseString.response {
                if responseHttpURL.statusCode == 200 {
                    if(responseString.value == nil) {
                        responseData(responseString.error as NSError?,nil,"",responseHttpURL.statusCode)
                        
                    } else {
                        self.resObjects = responseString.value as AnyObject
                        responseData(nil,self.resObjects as? NSDictionary,"",responseHttpURL.statusCode)
                    }
                } else {
                    self.resObjects = responseString.value as AnyObject
                    if let errodict = self.resObjects as? [String : Any] {
                        let errMsg = self.showErrorMessages(myDict: errodict, withCode: responseString.response?.statusCode ?? 0)
                        responseData(nil,nil, errMsg,responseHttpURL.statusCode)
                        
                    } else {
                        responseData(nil,nil, "ServerResponseError",responseHttpURL.statusCode)
                    }
                }
            } else {
                responseData(nil,nil, "Oops! Request timed out!",responseString.response?.statusCode ?? 0)
            }
        }
    }
    
    //MARK:- DELETE Method
    func deleteRequest(endpointurl:String, service: String, parameters: [String:Any], responseData:@escaping  (_ error: NSError?,_ responseArray: NSArray?, _ responseDict: NSDictionary?, _ errorMessage: String?, _ statusCode: Int) -> Void) {
        
        //            additionalHeaders.add(name: "Accept", value: "application/json")
        //            additionalHeaders.add(name: "Content-Type", value: "application/x-www-form-urlencoded")
        //
        //            if UserDefaultManager.getBooleanFromUserDefaults(key: UD_IsLoggedIn) {
        //                additionalHeaders.add(name: "Authorization", value: "Bearer \(self.getToken())")
        //            }
        
        AF.request(endpointurl, method: .delete, parameters: parameters, encoding: JSONEncoding.default, headers: additionalHeaders).responseJSON { (responseString)-> Void in
            
            //                print("response obj : \(responseString.value ?? "")")
            
            if let responseHttpURL = responseString.response {
                if responseHttpURL.statusCode == 200 {
                    if(responseString.value == nil) {
                        responseData(responseString.error as NSError?,nil,nil,"",responseHttpURL.statusCode)
                    } else {
                        self.resObjects = responseString.value as AnyObject
                        responseData(nil,nil,self.resObjects as? NSDictionary,"",responseHttpURL.statusCode)
                    }
                } else {
                    self.resObjects = responseString.value as AnyObject
                    if let errodict = self.resObjects as? [String : Any] {
                        let errMsg = self.showErrorMessages(myDict: errodict, withCode: responseString.response?.statusCode ?? 0)
                        responseData(nil,nil,nil, errMsg,responseHttpURL.statusCode)
                        
                    } else {
                        responseData(nil,nil,nil, "Server Response Error",responseHttpURL.statusCode)
                    }
                }
            } else {
                responseData(nil,nil,nil, "Oops! Request timed out!",responseString.response?.statusCode ?? 0)
            }
        }
    }
    
    //MARK:- PUT Method
    func putRequest(endpointurl:String, service: String, parameters: [String:Any], responseData:@escaping  (_ error: NSError?,_ responseArray: NSArray?, _ responseDict: NSDictionary?, _ errorMessage: String?, _ statusCode: Int) -> Void) {
        
        //            additionalHeaders.add(name: "Accept", value: "application/json")
        //            additionalHeaders.add(name: "Content-Type", value: "application/x-www-form-urlencoded")
        //
        //            if UserDefaultManager.getBooleanFromUserDefaults(key: UD_IsLoggedIn) {
        //                additionalHeaders.add(name: "Authorization", value: "Bearer \(self.getToken())")
        //            }
        
        AF.request(endpointurl, method: .put, parameters: parameters, encoding: JSONEncoding.default, headers: additionalHeaders).responseJSON { (responseString)-> Void in
            
            //                print("response obj : \(responseString.value ?? "")")
            
            if let responseHttpURL = responseString.response {
                if responseHttpURL.statusCode == 200 {
                    if(responseString.value == nil) {
                        responseData(responseString.error as NSError?,nil,nil,"",responseHttpURL.statusCode)
                    } else {
                        self.resObjects = responseString.value as AnyObject
                        responseData(nil,nil,self.resObjects as? NSDictionary,"",responseHttpURL.statusCode)
                    }
                } else {
                    self.resObjects = responseString.value as AnyObject
                    if let errodict = self.resObjects as? [String : Any] {
                        let errMsg = self.showErrorMessages(myDict: errodict, withCode: responseString.response?.statusCode ?? 0)
                        responseData(nil,nil,nil, errMsg,responseHttpURL.statusCode)
                        
                    } else {
                        responseData(nil,nil,nil, "Server Response Error",responseHttpURL.statusCode)
                    }
                }
            } else {
                responseData(nil,nil,nil, "Oops! Request timed out!",responseString.response?.statusCode ?? 0)
            }
        }
    }
    
    //MARK:- PATCH Method
    func patchRequest(endpointurl:String, service: String, parameters: [String:Any], responseData:@escaping  (_ error: NSError?,_ responseArray: NSArray?, _ responseDict: NSDictionary?, _ errorMessage: String?, _ statusCode: Int) -> Void) {
        
        //            additionalHeaders.add(name: "Accept", value: "application/json")
        //            additionalHeaders.add(name: "Content-Type", value: "application/x-www-form-urlencoded")
        //
        //            if UserDefaultManager.getBooleanFromUserDefaults(key: UD_IsLoggedIn) {
        //                additionalHeaders.add(name: "Authorization", value: "Bearer \(self.getToken())")
        //            }
        
        AF.request(endpointurl, method: .patch, parameters: parameters, encoding: JSONEncoding.default, headers: additionalHeaders).responseJSON { (responseString)-> Void in
            
            //                print("response obj : \(responseString.value ?? "")")
            
            if let responseHttpURL = responseString.response {
                if responseHttpURL.statusCode == 200 {
                    if(responseString.value == nil) {
                        responseData(responseString.error as NSError?,nil,nil,"",responseHttpURL.statusCode)
                    } else {
                        self.resObjects = responseString.value as AnyObject
                        responseData(nil,nil,self.resObjects as? NSDictionary,"",responseHttpURL.statusCode)
                    }
                } else {
                    self.resObjects = responseString.value as AnyObject
                    if let errodict = self.resObjects as? [String : Any] {
                        let errMsg = self.showErrorMessages(myDict: errodict, withCode: responseString.response?.statusCode ?? 0)
                        responseData(nil,nil,nil, errMsg,responseHttpURL.statusCode)
                        
                    } else {
                        responseData(nil,nil,nil, "Server Response Error",responseHttpURL.statusCode)
                    }
                }
            } else {
                responseData(nil,nil,nil, "Oops! Request timed out!",responseString.response?.statusCode ?? 0)
            }
        }
    }
    
    //MARK:- Show Response Status Method
    func showErrorMessages(myDict: [String:Any], withCode: Int) -> String {
        print("response error code: \(withCode)")
        if withCode == 401 {
            //Logout Automatically
            //            UserDefaultManager.resetUserDefaultValues()
            
//            var isGoBack: Bool = true
            //            if let arr = APP_DELEGATE.appNavigation?.viewControllers {
            //                for vc in arr {
            //                    if let _ = vc as? TabbarVC {
            //                        isGoBack = false
            //                    }
            //                }
            //            }
            
            //            if isGoBack {
            //                APP_DELEGATE.appNavigation = UINavigationController(rootViewController: loadVC(strStoryboardId: SB_TABBAR, strVCId: idTabbarVC))
            //                APP_DELEGATE.appNavigation?.isNavigationBarHidden = true
            //                APP_DELEGATE.appNavigation?.interactivePopGestureRecognizer?.delegate = nil
            //                APP_DELEGATE.appNavigation?.interactivePopGestureRecognizer?.isEnabled = true
            //                APP_DELEGATE.window?.rootViewController = APP_DELEGATE.appNavigation
            //                APP_DELEGATE.window?.makeKeyAndVisible()
            //            }
        }
        
        if let errordict = myDict["errors"] as? NSDictionary,
           errordict.count > 0 {
            var strerr = ""
            for (offset: index,element: (key: _,value: value)) in errordict.enumerated() {
                //                print("error value : \(index)")
                
                if let mymsg = value as? String {
                    if index == errordict.count - 1 {
                        strerr = strerr + "\(mymsg)"
                    } else {
                        strerr = strerr + "\(mymsg)\n"
                    }
                }
            }
            if strerr != "" {
                //                self.showStatusCode(msg: strerr)
                return strerr
            } else {
                if let errmsg = myDict["message"] as? String {
                    //                    self.showStatusCode(msg: errmsg)
                    return errmsg
                }
            }
        } else {
            if let errmsg = myDict["message"] as? String {
                //                self.showStatusCode(msg: errmsg)
                return errmsg
            }
        }
        return ""
    }
    
    func showStatusCode(msg: String) {
        DispatchQueue.main.async {
            print(msg)
        }
    }
}
