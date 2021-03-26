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
    public var additionalHeaders: HTTPHeaders = [:]
    var strAccessToken = ""
    
    //MARK:- Init Alamofire Method
    init() {
        AF.sessionConfiguration.timeoutIntervalForRequest = 60000000
    }
    
    public func setupRequestParameters(isToken: Bool, accessToken: String, tokenType: String, methodName: HTTPMethod, endpointURL: String, apiName: String, headers: HTTPHeaders, parameters: [String:Any]?, responseData:@escaping  (_ error: NSError?,_ responseArray: NSArray?, _ responseDict: NSDictionary?, _ errorMessage: String?) -> Void) {
        if isToken {
            self.strAccessToken = "\(tokenType) \(accessToken)"
        } else {
            self.strAccessToken = ""
        }
        self.additionalHeaders = headers
        
        if methodName == .get {
            self.getRequest(endpointurl: endpointURL, service: apiName) { (error, resArr, resDict, message) in
                responseData(error, resArr, resDict, message)
            }
            
        } else if methodName == .post {
            
        } else if methodName == .delete {
            
        } else if methodName == .put {
            
        } else if methodName == .patch {
            
        }
    }
    
    public func setupMultipartRequestParameters() {
        
    }
    
    //MARK:- Get Token
//    func getToken() -> String {
////        printMsg(val: "MyToken : \(UserDefaultManager.getStringFromUserDefaults(key: kAccessToken))")
//        return UserDefaultManager.getStringFromUserDefaults(key: kAccessToken)
//    }
    
    func isConnectedToNetwork() -> Bool
    {
        var zeroAddress = sockaddr_in()
        zeroAddress.sin_len = UInt8(MemoryLayout.size(ofValue: zeroAddress))
        zeroAddress.sin_family = sa_family_t(AF_INET)
        
        guard let defaultRouteReachability = withUnsafePointer(to: &zeroAddress, {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {zeroSockAddress in
                SCNetworkReachabilityCreateWithAddress(nil, zeroSockAddress)
            }
        })
            else
        {
            return false
        }
        
        var flags : SCNetworkReachabilityFlags = []
        if !SCNetworkReachabilityGetFlags(defaultRouteReachability, &flags) {
            return false
        }
        
        let isReachable = flags.contains(.reachable)
        let needsConnection = flags.contains(.connectionRequired)
        let available =  (isReachable && !needsConnection)
        if(available)
        {
            return true
        }
        else
        {
            print("No network available")
            return false
        }
    }
    
    //MARK:- GET Method
    func getRequest(endpointurl:String, service: String, responseData:@escaping  (_ error: NSError?,_ responseArray: NSArray?, _ responseDict: NSDictionary?, _ errorMessage: String?) -> Void) {
        
        if isConnectedToNetwork() {
            AF.request(endpointurl, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: additionalHeaders).responseJSON { (responseString)-> Void in
                
                print("response obj : \(responseString.value ?? "")")
                
                if let responseHttpURL = responseString.response {
                    if responseHttpURL.statusCode == 200 {
                        if(responseString.value == nil) {
                            responseData(responseString.error as NSError?,nil,nil,"")
                        } else {
                            self.resObjects = responseString.value as AnyObject
                            responseData(nil,nil,self.resObjects as? NSDictionary,"")
                        }
                    } else {
                        self.resObjects = responseString.value as AnyObject
                        if let errodict = self.resObjects as? [String : Any] {
                            let errMsg = self.showErrorMessages(myDict: errodict, withCode: responseString.response?.statusCode ?? 0)
                            responseData(nil,nil,nil, errMsg)
                            
                        } else {
                            responseData(nil,nil,nil, "Server Response Error")
                        }
                    }
                } else {
                    responseData(nil,nil,nil, "Oops! Request timed out!")
                }
            }
        }
    }
    
    //MARK:- POST Method
    func postRequest(endpointurl:String, service: String, parameters: [String:Any], responseData:@escaping  (_ error: NSError?,_ responseArray: NSArray?, _ responseDict: NSDictionary?, _ errorMessage: String?) -> Void) {
        
        if isConnectedToNetwork() {
            AF.request(endpointurl, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: additionalHeaders).responseJSON { (responseString)-> Void in
                
//                printMsg(val: "response obj : \(responseString.value ?? "")")
                
                if let responseHttpURL = responseString.response {
                    if responseHttpURL.statusCode == 200 {
                        if(responseString.value == nil) {
                            responseData(responseString.error as NSError?,nil,nil,"")
                            
                        } else {
                            self.resObjects = responseString.value as AnyObject
                            responseData(nil,nil,self.resObjects as? NSDictionary,"")
                        }
                    } else {
                        self.resObjects = responseString.value as AnyObject
                        if let errodict = self.resObjects as? [String : Any] {
                            let errMsg = self.showErrorMessages(myDict: errodict, withCode: responseString.response?.statusCode ?? 0)
                            responseData(nil,nil,nil, errMsg)
                            
                        } else {
                            responseData(nil,nil,nil, "ServerResponseError")
                        }
                    }
                } else {
                    responseData(nil,nil,nil, "Oops! Request timed out!")
                }
            }
        }
    }
    
    //MARK:- Multipart Form Data Method
    func requestWithPostMultipartParam(endpointurl:String, intImgAudVid: Int, parameters:NSDictionary, responseData:@escaping (_ data: AnyObject?, _ error: NSError?, _ message: String?, _ responseDict: AnyObject?, _ errorMessage: String?) -> Void) {
        if isConnectedToNetwork() {
            additionalHeaders = []
            additionalHeaders.add(name: "Content-type", value: "multipart/form-data")
            additionalHeaders.add(name: "Accept", value: "application/json")
//            additionalHeaders.add(name: "Authorization", value: "Bearer \(self.getToken())")

            AF.upload(multipartFormData: { (multipartFormData) in
                for (key, value) in parameters
                {
                    if value is Data {
                        if intImgAudVid == 1 {
                            //Image
                            if let myvalue = value as? Data,
                               let mykey = key as? String {
                                multipartFormData.append(myvalue, withName: mykey, fileName: "pollzillauser.jpg", mimeType: "image/jpeg")
                            }
                        }
                    }
                    else if value is URL {
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
                            do{
                                fileData = try Data.init(contentsOf: url)
                                if let mydata = fileData,
                                   let mykey = key as? String {
                                    multipartFormData.append(mydata, withName: mykey, fileName: "pollzilla.\(fileExt)", mimeType: mime)
                                }
                            }catch{
                                print(error.localizedDescription)
                            }
                        }
                    }
                    else {
                        multipartFormData.append("\(value)".data(using: String.Encoding.utf8)!, withName: key as! String)
                    }
                }
                
            },to: endpointurl, usingThreshold: UInt64.init(),
            method: .post,
            headers: additionalHeaders).responseJSON { (responseString)-> Void in
                
//                printMsg(val: "response obj : \(responseString.value)")
                
                if let responseHttpURL = responseString.response {
                    if responseHttpURL.statusCode == 200 {
                        if(responseString.value == nil) {
                            responseData(nil, responseString.error as NSError?,nil,nil,"")
                            
                        } else {
                            self.resObjects = responseString.value as AnyObject
                            responseData(nil,nil,nil,self.resObjects as? NSDictionary,"")
                        }
                    } else {
                        self.resObjects = responseString.value as AnyObject
                        if let errodict = self.resObjects as? [String : Any] {
                            let errMsg = self.showErrorMessages(myDict: errodict, withCode: responseString.response?.statusCode ?? 0)
                            responseData(nil, nil,nil,nil, errMsg)
                            
                        } else {
                            responseData(nil, nil,nil,nil, "ServerResponseError")
                        }
                    }
                } else {
                    responseData(nil,nil,nil,nil, "Oops! Request timed out!")
                }
            }
        }
    }
    
    //MARK:- DELETE Method
    func deleteRequest(endpointurl:String, service: String, parameters: [String:Any], responseData:@escaping  (_ error: NSError?,_ responseArray: NSArray?, _ responseDict: NSDictionary?, _ errorMessage: String?) -> Void) {
        
        if isConnectedToNetwork() {
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
                            responseData(responseString.error as NSError?,nil,nil,"")
                        } else {
                            self.resObjects = responseString.value as AnyObject
                            responseData(nil,nil,self.resObjects as? NSDictionary,"")
                        }
                    } else {
                        self.resObjects = responseString.value as AnyObject
                        if let errodict = self.resObjects as? [String : Any] {
                            let errMsg = self.showErrorMessages(myDict: errodict, withCode: responseString.response?.statusCode ?? 0)
                            responseData(nil,nil,nil, errMsg)
                            
                        } else {
                            responseData(nil,nil,nil, "Server Response Error")
                        }
                    }
                } else {
                    responseData(nil,nil,nil, "Oops! Request timed out!")
                }
            }
        }
    }
    
    //MARK:- PUT Method
    func putRequest(endpointurl:String, service: String, parameters: [String:Any], responseData:@escaping  (_ error: NSError?,_ responseArray: NSArray?, _ responseDict: NSDictionary?, _ errorMessage: String?) -> Void) {
        
        if isConnectedToNetwork() {
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
                            responseData(responseString.error as NSError?,nil,nil,"")
                        } else {
                            self.resObjects = responseString.value as AnyObject
                            responseData(nil,nil,self.resObjects as? NSDictionary,"")
                        }
                    } else {
                        self.resObjects = responseString.value as AnyObject
                        if let errodict = self.resObjects as? [String : Any] {
                            let errMsg = self.showErrorMessages(myDict: errodict, withCode: responseString.response?.statusCode ?? 0)
                            responseData(nil,nil,nil, errMsg)
                            
                        } else {
                            responseData(nil,nil,nil, "Server Response Error")
                        }
                    }
                } else {
                    responseData(nil,nil,nil, "Oops! Request timed out!")
                }
            }
        }
    }
    
    //MARK:- PATCH Method
    func patchRequest(endpointurl:String, service: String, parameters: [String:Any], responseData:@escaping  (_ error: NSError?,_ responseArray: NSArray?, _ responseDict: NSDictionary?, _ errorMessage: String?) -> Void) {
        
        if isConnectedToNetwork() {
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
                            responseData(responseString.error as NSError?,nil,nil,"")
                        } else {
                            self.resObjects = responseString.value as AnyObject
                            responseData(nil,nil,self.resObjects as? NSDictionary,"")
                        }
                    } else {
                        self.resObjects = responseString.value as AnyObject
                        if let errodict = self.resObjects as? [String : Any] {
                            let errMsg = self.showErrorMessages(myDict: errodict, withCode: responseString.response?.statusCode ?? 0)
                            responseData(nil,nil,nil, errMsg)
                            
                        } else {
                            responseData(nil,nil,nil, "Server Response Error")
                        }
                    }
                } else {
                    responseData(nil,nil,nil, "Oops! Request timed out!")
                }
            }
        }
    }
    
    /*
    //MARK:- Encryption/Decryption Methods
    func getEncryptedParameters(dictionary:[String:Any]) -> (value:String,mac:String) {
        var value = ""
        if let theJSONData = try? JSONSerialization.data( withJSONObject: dictionary,
                                                          options: []) {
            let theJSONText = String(data: theJSONData, encoding: .ascii)
            value = (try! theJSONText?.aesEncrypt1(key: APP_ENC_KEY, iv: APP_ENCRYPT_VI_KEY))!
        }
        
        let data = (APP_ENCRYPT_VI_KEY).data(using: String.Encoding.utf8)
        let base64String = data!.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0))
        let final = "\(base64String)"+"\(value)"
        let mac = final.hmac(algorithm: .SHA256, key: APP_ENC_KEY)
        return (value,mac)
    }
    
    func getInnerEncryptedParameters(dictionary:[String:Any]) -> [String:Any]
    {
        var value = ""
        if let theJSONData = try? JSONSerialization.data( withJSONObject: dictionary,
                                                          options: []) {
            let theJSONText = String(data: theJSONData, encoding: .ascii)
            value = (try! theJSONText?.aesEncrypt1(key: APP_ENC_KEY, iv: APP_ENCRYPT_VI_KEY))!
        }
        
        let data = (APP_ENCRYPT_VI_KEY).data(using: String.Encoding.utf8)
        let base64String = data!.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0))
        
        let final = "\(base64String)"+"\(value)"
        let mac = final.hmac(algorithm: .SHA256, key: APP_ENC_KEY)
        
        let dict:[String:Any] = ["mac" : mac, "value": value]
        return dict
    }
    
    func isGotValidResponseFromMac(value:String,macFromResponse:String) -> (Bool,[String:Any]?,[[String:Any]]?,[String]?)
    {
        let data = (APP_DECRYPT_VI_KEY).data(using: String.Encoding.utf8)
        let base64String = data!.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0))
        let final = "\(base64String)"+"\(value)"
        let mac = final.hmac(algorithm: .SHA256, key: APP_DEC_KEY)
        if mac == macFromResponse,
            let response = value.aesDecrypt1(key: APP_DEC_KEY, iv: APP_DECRYPT_VI_KEY) {
//            print("json response:----- \(response)")
            if let dict = self.convertToDictionary(text: response) {
                return (true,dict,nil,nil)
            } else if let arrDict = self.convertToArray(text: response) {
                return (true,nil,arrDict,nil)
            } else if let arrString = self.convertToStringArray(text: response) {
                return (true,nil,nil,arrString)
            }else {
                if response == "null" {
                    return (true,nil,nil,nil)
                }
                return (false,nil,nil,nil)
            }
        } else {
            return (false,nil,nil,nil)
        }
    }
    
    func convertToDictionary(text: String) -> [String: Any]? {
        if let data = text.data(using: .utf8) {
            do {
                return try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
            } catch {
                print(error.localizedDescription)
            }
        }
        return nil
    }
    
    func convertToArray(text: String) -> [[String: Any]]? {
        if let data = text.data(using: .utf8) {
            do {
                //print(try JSONSerialization.jsonObject(with: data, options: []) as? [[String: Any]])
                return try JSONSerialization.jsonObject(with: data, options: []) as? [[String: Any]]
            } catch {
                print(error.localizedDescription)
            }
        }
        return nil
    }
    
    func convertToStringArray(text: String) -> [String]? {
        if let data = text.data(using: .utf8) {
            do {
                return try JSONSerialization.jsonObject(with: data, options: []) as? [String]
            } catch {
                print(error.localizedDescription)
            }
        }
        return nil
    }
 */
 
    //MARK:- Show Response Status Method
    func showErrorMessages(myDict: [String:Any], withCode: Int) -> String {
        print("response error code: \(withCode)")
        if withCode == 401 {
            //Logout Automatically
//            UserDefaultManager.resetUserDefaultValues()
            
            var isGoBack: Bool = true
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
