//
//  ServiceRequestDecorator.swift
//  Copyright © 2016 Kevin Tatroe. All rights reserved.
//

/*
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:
 
 * Redistributions of source code must retain the above copyright notice,
 this list of conditions and the following disclaimer.
 
 * Redistributions in binary form must reproduce the above copyright notice,
 this list of conditions and the following disclaimer in the documentation
 and/or other materials provided with the distribution.
 
 * Neither the name Kevin Tatroe nor the names of its contributors may be
 used to endorse or promote products derived from this software without
 specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
 LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.
 */

import Foundation


/**
 Applies changes to the `NSMutableURLRequest` generated by an `ServiceRequest` prior
 to turning the URL request into a fetch.
 */
public protocol ServiceRequestDecorator: class {
    func compose(urlRequest: NSMutableURLRequest)
}


/**
 Adds an HTTP header indicating the response can be Gzip compressed.
 */
public class AcceptGZIPHeadersServiceRequestDecorator : ServiceRequestDecorator {
    // MARK: - Initializers
    
    public init() { }
    
    
    // MARK: - Protocols
    
    // MARK: <ServiceRequestDecorator>
    
    public func compose(urlRequest: NSMutableURLRequest) {
        urlRequest.setValue("gzip", forHTTPHeaderField: "Accept-Encoding")
    }
}


/**
 Applies its parameters either as GET parameters or by building a POST body payload
 as appropriate for the type of request.
 */
public class HTTPParametersBodyServiceRequestDecorator : ServiceRequestDecorator {
    // MARK: - Properties
    
    let type: ServiceEndpointType
    let parameters: [String : String]
    
    
    // MARK: - Initialization
    
    public init(type: ServiceEndpointType, parameters: [String : String]) {
        self.type = type
        self.parameters = parameters
    }
    
    
    // MARK: - Protocols
    
    // MARK: <ServiceRequestDecorator>
    
    public func compose(urlRequest: NSMutableURLRequest) {
        guard parameters.count > 0 else { return }
        
        switch type {
        case .get:
            if let requestURL = urlRequest.URL {
                urlRequest.URL = requestURL.urlByAppendingQueryParameters(parameters)
            }
            
        case .post: fallthrough
        case .put: fallthrough
        case .delete:
            urlRequest.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
            
            var valueStrings = [String]()
            
            for (key, value) in parameters {
                let encodedValue = value.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())
                valueStrings.append("\(key)=\(encodedValue)")
            }
            
            let requestBody = valueStrings.joinWithSeparator("&")
            
            let data = requestBody.dataUsingEncoding(NSUTF8StringEncoding)
            urlRequest.HTTPBody = data
            
        case .header:
            /// TODO: support HEADER requests
            break
        }
    }
}


internal extension NSURL {
    /**
     Provides support for mutating a URL into another by adding query parameters to the
     URL's existing parameters (or by adding query parameters if none already exist).
     */
    func urlByAppendingQueryParameters(parameters: [String : String]?) -> NSURL {
        guard let parameters = parameters else { return self }
        guard let components = NSURLComponents(URL: self, resolvingAgainstBaseURL: false) else { return self }
        
        for (key, value) in parameters {
            let encodedValue = value.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())
            let queryItem = NSURLQueryItem(name: key, value: encodedValue)
            
            if let _ = components.queryItems {
                components.queryItems!.append(queryItem)
            }
            else {
                components.queryItems = [queryItem]
            }
        }
        
        if let url = components.URL {
            return url
        }
        
        return self
    }
}


/**
 Adds HTTP headers indicating the response is expected (and allowed) to be in JSON format.
 */
public class JSONHeadersServiceRequestDecorator : ServiceRequestDecorator {
    public init() {
        
    }
    
    
    // MARK: - Protocols
    
    // MARK: <ServiceRequestDecorator>
    
    public func compose(urlRequest: NSMutableURLRequest) {
        urlRequest.setValue("application/json, text/javascript, */*; q=0.01", forHTTPHeaderField:"Accept")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
    }
}


/**
 Applies its parameters in a JSON object in the body of the HTTP request.
 */
public class JSONBodyParametersServiceRequestDecorator : ServiceRequestDecorator {
    // MARK: - Properties
    
    let parameters: [String : String]
    
    
    // MARK: - Initialization
    
    public init(parameters: [String : String]) {
        self.parameters = parameters
    }
    
    
    // MARK: - Protocols
    
    // MARK: <ServiceRequestDecorator>
    
    public func compose(urlRequest: NSMutableURLRequest) {
        do {
            let data = try NSJSONSerialization.dataWithJSONObject(parameters, options: .PrettyPrinted)
            urlRequest.HTTPBody = data
        }
        catch { }
    }
}
