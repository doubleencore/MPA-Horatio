//
//  Copyright © 2016 Kevin Tatroe. All rights reserved.
//  See LICENSE.txt for this sample’s licensing information

import Foundation


/**
 Stores and provides named `Feature` instances. Each application will
 generally have a single `FeatureProvider` active at any given moment,
 but can switch between them as necessary (for example, when switching
 environments).
*/
public protocol FeatureProvider {
    func feature(_ named: String) -> Feature?

    func activeSubject() -> FeatureSubject?
}


/// The availability or value for a `Feature` for the current user.
public enum FeatureValue {
    // Feature is currently unavailable
    case unavailable
    
    // Feature is currently available
    case available
    
    // Feature reports a value, rather than availability
    case value(AnyObject)
}


/**
 Stores information about an application feature.
*/
public protocol Feature {
    var identifier: String { get }

    func value() -> FeatureValue
}


public extension Feature {
    func isAvailable() -> Bool {
        switch value() {
        case .available:
            return true
        default:
            return false
        }
    }
}


/**
 An implementation of `Feature` that provides a static, constant value
 regardless of the active subject.
 */
open class StaticFeature: Feature {
    public let identifier: String

    
    // MARK: - Initialization
    
    public init(identifier: String, value: FeatureValue) {
        self.identifier = identifier
        self.staticValue = value
    }
    
    
    // MARK: - Protocols
    
    // MARK: <StaticFeature>
    
    public func value() -> FeatureValue {
        return staticValue
    }
    
    // MARK: - Private

    fileprivate let staticValue: FeatureValue
}
