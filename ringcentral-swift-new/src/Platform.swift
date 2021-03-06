//
//  Platform.swift
//  src
//
//  Created by Anil Kumar BP on 10/27/15.
//  Copyright (c) 2015 Anil Kumar BP. All rights reserved.
//

import Foundation


/// Platform used to call HTTP request methods.
class Platform {
    
    // platform Constants
    let ACCESS_TOKEN_TTL = "3600"; // 60 minutes
    let REFRESH_TOKEN_TTL = "604800"; // 1 week
    let TOKEN_ENDPOINT = "/restapi/oauth/token";
    let REVOKE_ENDPOINT = "/restapi/oauth/revoke";
    let API_VERSION = "v1.0";
    let URL_PREFIX = "/restapi";
    
    
    // Platform credentials
    var auth: Auth
    var client: Client
    let server: String
    let appKey: String
    let appSecret: String
//    var subscription: Subscription?
    
    //default contructor
    //    init(){
    //        self.appKey = appKey
    //        self.appSecret = appSecret
    //        self.server = server
    //    }
    //
    
    
    
    /// Constructor for the platform of the SDK
    ///
    /// :param: appKey      The appKey of your app
    /// :param: appSecet    The appSecret of your app
    /// :param: server      Choice of PRODUCTION or SANDBOX
    init(appKey: String, appSecret: String, server: String) {
        self.appKey = appKey
        self.appSecret = appSecret
        self.server = server
        self.auth = Auth()
        self.client = Client()
        
    }
    
    
    // Returns the auth object
    ///
    func returnAuth() -> Auth {
        return self.auth
    }
    
    /// createUrl
    ///
    /// @param: path              The username of the RingCentral account
    /// @param: options           The password of the RingCentral account
    /// @response: ApiResponse    The password of the RingCentral account
    func createUrl(path: String, options: [String: AnyObject]) -> String {
        var builtUrl = ""
        if(options["skipAuthCheck"] != nil){
            builtUrl = builtUrl + self.server + path
            return builtUrl
        }
        builtUrl = builtUrl + self.server + self.URL_PREFIX + "/" + self.API_VERSION + path
        return builtUrl
    }
    
//    func loggedIn() -> Bool {
//        
////        do {
////            try {
////                if (self.auth.accessTokenValid() || self.refresh()) {
////                    return true
////                }
////            }; catch() {
////                    return false
////            }
////        }
//    }
    /// Authorizes the user with the correct credentials
    ///
    /// :param: username    The username of the RingCentral account
    /// :param: password    The password of the RingCentral account
    func login(username: String, ext: String, password: String) -> Transaction {
        let response = requestToken(self.TOKEN_ENDPOINT,body: [
            "grant_type": "password",
            "username": username,
            "extension": ext,
            "password": password,
            "access_token_ttl": self.ACCESS_TOKEN_TTL,
            "refresh_token_ttl": self.REFRESH_TOKEN_TTL
            ])
        println("Successfull return from requestToken")
        //        let readdata = NSJSONSerialization.JSONObjectWithData(response.getData()!, options: nil, response.getError()) as! NSDictionary
//        println(response.getDict())
        self.auth.setData(response.getDict())
        println("Is access token valid : ",self.auth.accessTokenValid())
        println("The auth data is : ")
        println(response.JSONStringify(response.getDict(), prettyPrinted: true))
        return response
    }
    
   
    /// Refreshes the Auth object so that the accessToken and refreshToken are updated.
    ///
    /// **Caution**: Refreshing an accessToken will deplete it's current time, and will
    /// not be appended to following accessToken.
    func refresh() -> Transaction {
//        let transaction: 
        if(!self.auth.refreshTokenValid()){
              NSException(name: "Refresh token has expired", reason: "reason", userInfo: nil).raise()
        }
        let response = requestToken(self.TOKEN_ENDPOINT,body: [
            "grant_type": "refresh_token",
            "refresh_token": self.auth.refreshToken(),
            "access_token_ttl": self.ACCESS_TOKEN_TTL,
            "refresh_token_ttl": self.REFRESH_TOKEN_TTL
            ])
        println("Successfull return from requestToken")
        //        let readdata = NSJSONSerialization.JSONObjectWithData(response.getData()!, options: nil, response.getError()) as! NSDictionary
        println(response.getDict())
        self.auth.setData(response.getDict())
        println("Is access token valid",self.auth.accessTokenValid())
        println("The auth data is",self.auth.data())
        return response
    }
    
    /// func inflateRequest ()
    ///
    /// @param: request     NSMutableURLRequest
    /// @param: options     list of options
    /// @response: NSMutableURLRequest
    func inflateRequest(path: String, request: NSMutableURLRequest, options: [String: AnyObject]) -> NSMutableURLRequest {
        var check = 0
        if options["skipAuthCheck"] == nil {
            ensureAuthentication()
            let authHeader = self.auth.tokenType() + " " + self.auth.accessToken()
            request.setValue("Authorization", forHTTPHeaderField: authHeader)
            //            check = 1
        }
        //        let url = createUrl(path,check: check,options: ["addServer": true])
        //        let request = NSMutableURLRequest(URL:url)
        return request
    }
    
    
    
    
    /// func sendRequest ()
    ///
    /// @param: request     NSMutableURLRequest
    /// @param: options     list of options
    /// @response: ApiResponse
    func sendRequest(request: NSMutableURLRequest, path: String, options: [String: AnyObject]!, completion: (transaction: Transaction) -> Void) {
        client.send(inflateRequest(path, request: request, options: options)) {
            (t) in
            completion(transaction: t)
            
        }
    }
    
    func sendRequest(request: NSMutableURLRequest, path: String, options: [String: AnyObject]!) -> Transaction {
        return client.send(inflateRequest(path, request: request, options: options))
    }
    
    ///  func requestToken ()
    ///
    /// @param: path    The token endpoint
    /// @param: array   The body
    /// @return ApiResponse
    func requestToken(path: String, body: [String:AnyObject]) -> Transaction {
        let authHeader = "Basic" + " " + self.apiKey()
        var headers: [String: String] = [:]
        headers["Authorization"] = authHeader
        headers["Content-type"] = "application/x-www-form-urlencoded;charset=UTF-8"
        var options: [String: AnyObject] = [:]
        options["skipAuthCheck"] = "true"
        let urlCreated = createUrl(path,options: options)
        let request = self.client.createRequest("POST", url: urlCreated, query: nil, body: body, headers: headers)
        return self.sendRequest(request, path: path, options: options)
    }
    
    
    
    
    /// Base 64 encoding
    func apiKey() -> String {
        let plainData = (self.appKey + ":" + self.appSecret as NSString).dataUsingEncoding(NSUTF8StringEncoding)
        let base64String = plainData!.base64EncodedStringWithOptions(NSDataBase64EncodingOptions(rawValue: 0))
        return base64String
    }
    
    
    
    
    /// Authorizes the user with the correct credentials
    ///
    /// :param: username    The username of the RingCentral account
    /// :param: password    The password of the RingCentral account
    //    func authorize(username: String, password: String, remember: Bool = true) {
    //        let authHolder = Auth(username: username, password: password, server: server)
    //        let feedback = authHolder.login(appKey, secret: appSecret)
    //        if (feedback.1 as! NSHTTPURLResponse).statusCode / 100 == 2 {
    //            self.auth = authHolder
    //        }
    //    }
    //
    
    
    /// Authorizes the user with the correct credentials (with extra ext)
    ///
    /// :param: username    The username of the RingCentral account
    /// :param: password    The password of the RingCentral account
    //    /// :param: ext         The extension of the RingCentral account
    //    func authorize(username: String, ext: String, password: String) {
    //        let authHolder = Auth(username: username, ext: ext, password: password, server: self.server)
    //        let feedback = authHolder.login(appKey, secret: appSecret)
    //        if (feedback.1 as! NSHTTPURLResponse).statusCode / 100 == 2 {
    //            self.auth = authHolder
    //        }
    //    }
    
    
    /// Refreshes the Auth object so that the accessToken and refreshToken are updated.
    ///
    /// **Caution**: Refreshing an accessToken will deplete it's current time, and will
    /// not be appended to following accessToken.
    //    func refresh() {
    //        if let holder: Auth = self.auth {
    //            self.auth!.refresh()
    //        } else {
    //            notAuthorized()
    //        }
    //    }
    
    /// Refreshes the Auth object so that the accessToken and refreshToken are updated.
    ///
    /// **Caution**: Refreshing an accessToken will deplete it's current time, and will
//    /// not be appended to following accessToken.
//    func refresh () -> Transaction {
//        var error: NSError?
//        if (auth.refreshTokenValid() == false) {
//            NSException.raise("Exception", format:"Refresh token has expired", arguments:getVaList([(error!)]))
//        }
//        let response = requestToken(self.TOKEN_ENDPOINT,body: [
//            "grant_type": "refresh_token",
//            "refresh_token": self.auth.refreshToken(),
//            "access_token_ttl": self.ACCESS_TOKEN_TTL,
//            "refresh_token_ttl": self.REFRESH_TOKEN_TTL
//            ])
//        self.auth.setData(response.jsonAsArray)
//        return response
//        
//        
//    }
    
    
    
    /// Logs the user out of the current account.
    ///
    /// Kills the current accessToken and refreshToken.
    func logout() -> Transaction {
        let response = requestToken(self.TOKEN_ENDPOINT,body: [
            "token": self.auth.accessToken()
            ])
        self.auth.reset()
        return response
    }
    
    
    /// Returns whether or not the current accessToken is valid.
    ///
    /// :return: A boolean to check the validity of token.
    func isTokenValid() -> Bool {
        return false
    }
    
    
    /// Returns whether or not the current Platform has been authorized with a user.
    ///
    /// :return: A boolean to check the validity of authorization.
    func isAuthorized() -> Bool {
        return auth.isAccessTokenValid()
    }
    
    /// Tells the user that the platform is not yet authorized.
    ///
    ///
    func notAuthorized() {
        
    }
    
    /// Tells the user if the accessToken is valed
    ///
    ///
    func ensureAuthentication() {
        if (!self.auth.accessTokenValid()) {
            refresh()
        }
    }
    
    
        // My methods ( Generic HTTP methods )
        func get(url: String, query: [String: String]? = nil, headers: [String: String]? = nil, body: [String: String]? = nil, options: [String: String]? = nil, completion: (transaction: Transaction) -> Void) {
            
            let urlCreated = createUrl(url,options: options!)
            
            sendRequest(self.client.createRequest("GET", url: url, query: query, body: body!, headers: headers!), path: url, options: options!) {
                (t) in
                completion(transaction: t)
    
            }
    
        }
    
    // Generic Method calls  ( HT
    
    // Generic Method Calls
    
    /// HTTP request method for GET
    ///
    /// :param: url         URL for GET request
    /// :param: query       List of queries for GET request
//    func get(url: String, query: [String: String] = ["": ""]) {
//        apiCall([
//            "method": "GET",
//            "url": url,
//            "query": query
//            ])
//    }
//    
//    /// HTTP request method for PUT
//    ///
//    /// :param: url         URL for PUT request
//    /// :param: body        Body for PUT request
//    func put(url: String, body: String = "") {
//        apiCall([
//            "method": "PUT",
//            "url": url,
//            "body": body
//            ])
//    }
//    
//    /// HTTP request method for POST
//    ///
//    /// :param: url         URL for POST request
//    /// :param: body        Body for POST request
//    func post(url: String, body: String = "") {
//        apiCall([
//            "method": "POST",
//            "url": url,
//            "body": body
//            ])
//    }
//    
//    /// HTTP request method for DELETE
//    ///
//    /// :param: url         URL for DELETE request
//    func delete(url: String) {
//        apiCall([
//            "method": "DELETE",
//            "url": url,
//            ])
//    }
//    
//    /// Generic HTTP request
//    ///
//    /// :param: options     List of options for HTTP request
//    func apiCall(options: [String: AnyObject]) {
//        var method = ""
//        var url = ""
//        var headers: [String: String] = ["": ""]
//        var query: [String: String]?
//        var body: AnyObject = ""
//        if let m = options["method"] as? String {
//            method = m
//        }
//        if let u = options["url"] as? String {
//            url = self.server + u
//        }
//        if let h = options["headers"] as? [String: String] {
//            headers = h
//        }
//        if let q = options["query"] as? [String: String] {
//            query = q
//        }
//        if let b = options["body"] {
//            if let check = b as? NSDictionary {
//                body = check
//            } else {
//                body = b as! String
//            }
//        }
//        var request = Request(method: method, url: url, headers: headers, query: query, body: body)
//        
//        request.setHeader("Authorization", value: "Bearer" + " " + auth.accessToken())
//        request.send()
//    }
    
    /// Generic HTTP request with completion handler
    ///
    /// :param: options         List of options for HTTP request
    /// :param: completion      Completion handler for HTTP request
//    func apiCall(options: [String: AnyObject], completion: (data: NSData?, response: NSURLResponse?, error: NSError?) -> Void) {
//        var method = ""
//        var url = ""
//        var headers: [String: String] = ["": ""]
//        var query: [String: String]?
//        var body: AnyObject = ""
//        if let m = options["method"] as? String {
//            method = m
//        }
//        if let u = options["url"] as? String {
//            url = self.server + u
//        }
//        if let h = options["headers"] as? [String: String] {
//            headers = h
//        }
//        if let q = options["query"] as? [String: String] {
//            query = q
//        }
//        if let b = options["body"] {
//            if let check = b as? NSDictionary {
//                body = check
//            } else {
//                body = b as! String
//            }
//        }
//        var request = Request(method: method, url: url, headers: headers, query: query, body: body)
//        request.setHeader("Authorization", value: "Bearer" + " " + auth.accessToken())
//        request.send() {
//            (data, response, error) in
//            completion(data: data, response: response, error: error)
//        }
//        
//    }
//    
//    // ringout
//    func testApiCall() {
//        apiCall([
//            "method": "POST",
//            "url": "/restapi/v1.0/account/~/extension/~/ringout",
//            "body": ["to": ["phoneNumber": "14088861168"],
//                "from": ["phoneNumber": "14088861168"],
//                "callerId": ["phoneNumber": "13464448343"],
//                "playPrompt": "true"]
//            ])
//        sleep(5)
//        
//    }
//    
//    // fax
//    func testApiCall2() {
//        apiCall([
//            "method": "POST",
//            "url": "/restapi/v1.0/account/~/extension/~/fax",
//            "body": "--Boundary_1_14413901_1361871080888\n" +
//                "Content-Type: application/json\n" +
//                "\n" +
//                "{\n" +
//                "  \"to\":[{\"phoneNumber\":\"13464448343\"}],\n" +
//                "  \"faxResolution\":\"High\",\n" +
//                "  \"sendTime\":\"2013-02-26T09:31:20.882Z\"\n" +
//                "}\n" +
//                "\n" +
//                "--Boundary_1_14413901_1361871080888\n" +
//                "Content-Type: text/plain\n" +
//                "\n" +
//                "Hello, World!\n" +
//                "\n" +
//            "--Boundary_1_14413901_1361871080888--",
//            "headers": ["Content-Type": "multipart/mixed;boundary=Boundary_1_14413901_1361871080888"]
//            ]) {
//                (data, response, error) in
//                println(response)
//                println(error)
//                println(NSJSONSerialization.JSONObjectWithData(data!, options: nil, error: nil) as! NSDictionary)
//        }
//        sleep(5)
//    }
//    
//    // subscription
//    func testApiCall3() {
//        apiCall([
//            "method": "POST",
//            "url": "/restapi/v1.0/subscription",
//            "body": [
//                "eventFilters": [
//                    "/restapi/v1.0/account/~/extension/~/presence",
//                    "/restapi/v1.0/account/~/extension/~/message-store"
//                ],
//                "deliveryMode": [
//                    "transportType": "PubNub",
//                    "encryption": "false"
//                ]
//            ]
//            ]) {
//                (data, response, error) in
//                println(response)
//                println(error)
//                println(NSJSONSerialization.JSONObjectWithData(data!, options: nil, error: nil) as! NSDictionary)
//        }
//        sleep(5)
//    }
//    
//    func testSubCall() {
//        self.subscription = Subscription(platform: self)
//        subscription!.register()
//        
//    }
//    
//    func testSMS() {
//        apiCall([
//            "method": "POST",
//            "url": "/restapi/v1.0/account/~/extension/~/sms",
//            "body": "{" +
//                "\"to\": [{\"phoneNumber\": " +
//                "\"" + "18315941779" + "\"}]," +
//                "\"from\": {\"phoneNumber\": \"" + "15856234190" +
//                "\"}," + "\"text\": \"" + "tetestingxt" + "\"" + "}"
//            ]) {
//                (data, response, error) in
//                println(response)
//                println(error)
//                println(NSJSONSerialization.JSONObjectWithData(data!, options: nil, error: nil) as! NSDictionary)
//        }
//        sleep(5)
//    }
    
}


