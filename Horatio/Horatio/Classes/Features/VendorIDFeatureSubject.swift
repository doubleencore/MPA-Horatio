//
//  Copyright © 2016 Kevin Tatroe. All rights reserved.
//  See LICENSE.txt for this sample’s licensing information

import Foundation
import UIKit


/**
 `FeatureSubject` using the Vendor ID from the iAd framework.
 */
public class VendorIDFeatureSubject: FeatureSubject {
    
    public let identifier: String
    
    // MARK: - Initialization
    
    public init() {
        self.identifier = UIDevice.current.identifierForVendor?.uuidString ?? "<unavailable>"
    }
}
