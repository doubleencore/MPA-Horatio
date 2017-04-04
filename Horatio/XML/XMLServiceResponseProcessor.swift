//
//  XMLServiceResponseProcessor.swift
//  PGAAmericas
//
//  Created by Alex Samarchi on 7/22/16.
//  Copyright © 2016 PGA Americas. All rights reserved.
//

import Foundation


/**
 Processes XML data in some way — transforming, storing, or otherwise manipulating the data.
 */

public protocol XMLProcessor: XMLParserDelegate {
    func processXMLData(_ request: ServiceRequest, xmlParser: XMLParser, completionBlock: @escaping (_ errors: [NSError]?) -> Void)
}



/**
 Processes JSON data from a response object and returns an error or a terminal processed case.
 A JSON processor takes a specialized processor for parsing JSON (typically, parsing the JSON
 into objects and storing those in a local store).
 */
open class XMLServiceResponseProcessor : ServiceResponseProcessor {
    // MARK: - Properties
    
    let xmlProcessor: XMLProcessor
    
    
    // MARK: - Initialization
    
    
    public init(xmlProcessor: XMLProcessor) {
        self.xmlProcessor = xmlProcessor
    }
    
    
    // MARK: - Protocols
    
    // MARK: <ServiceResponseProcessor>

    public func process(_ request: ServiceRequest, input: ServiceResponseProcessorParam, completionBlock: @escaping (ServiceResponseProcessorParam) -> Void) {
        var xmlParser: XMLParser? = nil
        
        switch input {
        case .stream(let inputStream):
            xmlParser = XMLParser(stream: inputStream)
            
        case .data(_, let inputData):
            xmlParser = XMLParser(data: inputData)
            
        default:
            /// TODO: Should this return an error of "no data to process"?
            completionBlock(input)
        }
        
        guard let validXMLParser = xmlParser else { completionBlock(.processed(false)); return }
        
        xmlProcessor.processXMLData(request, xmlParser: validXMLParser, completionBlock: { (errors: [NSError]?) in
            if let error = errors?.first {
                completionBlock(.error(error))
                return
            }
            
            completionBlock(.processed(true))
        })
    }
}
