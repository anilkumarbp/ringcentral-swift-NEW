//
//  SDK.swift
//  src
//
//  Created by Anil Kumar BP on 10/27/15.
//  Copyright (c) 2015 Anil Kumar BP. All rights reserved.
//

import Foundation

import Foundation

// Object representation of a Standard Development Kit for RingCentral
class SDK {
    
    // Set constants for SANDBOX and PRODUCTION servers.
    static var VERSION: String = ""
    static var RC_SERVER_PRODUCTION: String = "https://platform.ringcentral.com"
    static var RC_SERVER_SANDBOX: String = "https://platform.devtest.ringcentral.com"
    
    // Platform variable, version, and current Subscriptions
    var platform: Platform
//    var subscription: Subscription?
    let server: String
    var client: Client
    var serverVersion: String!
    var versionString: String!
    var logger: Bool = false
    
    
    
    init(appKey: String, appSecret: String, server: String) {
        self.client = Client()
        platform = Platform(appKey: appKey, appSecret: appSecret, server: server)
        self.server = server
        //      setVersion()
    }
    
    /// Sets version to the version of the current SDK
    private func setVersion() {
        let url = NSURL(string: server + "/restapi/")
        
        // Sets up the request
        let request = NSMutableURLRequest(URL: url!)
        request.HTTPMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        var response: NSURLResponse?
        var error: NSError?
        let data = NSURLConnection.sendSynchronousRequest(request, returningResponse: &response, error: &error)
        
        let readdata = NSJSONSerialization.JSONObjectWithData(data!, options: nil, error: nil) as! NSDictionary
        
        let dict = NSJSONSerialization.JSONObjectWithData(data!, options: nil, error: nil) as! NSDictionary
        self.serverVersion = dict["serverVersion"] as! String
        self.versionString = (dict["apiVersions"] as! NSArray)[0]["versionString"] as! String
        
    }
    
    /// Returns the server version.
    ///
    /// :returns: String of current version
    func getServerVersion() -> String {
        return serverVersion
    }
    
    
    
    /// Returns the Platform with the specified appKey and appSecret.
    ///
    /// :returns: A Platform to access the methods of the SDK
    func getPlatform() -> Platform {
        return self.platform
    }
    
    
    
    /// Returns the current Subscription.
    ///
    /// :returns: A Subscription that the user is currently following
//    func getSubscription() -> Subscription? {
//        return self.subscription
//    }
    
    
    
}