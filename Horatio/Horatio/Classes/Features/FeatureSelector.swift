//
//  Copyright © 2016 Kevin Tatroe. All rights reserved.
//  See LICENSE.txt for this sample’s licensing information

import Foundation


/**
 Returns a value in the range [0, 1) for mapping a `FeatureSubject` to a specific
 `FeatureVariant` out of possible variants within an active `Feature`.
*/
public protocol FeatureSelector {
    /// Returns the selector's mapped value in the range [0, 1) for a given subject and feature.
    func select(_ feature: Feature, subject: FeatureSubject?) -> Double?
}


/**
 Weights a subject to a variant evenly(ish) and randomly(ish) across all possible
 `FeatureVariant` values.
*/
public class WeightedFeatureSelector: FeatureSelector {
    // MARK: - Protocols
    
    // MARK: <FeatureSelector>
    
    public func select(_ feature: Feature, subject: FeatureSubject? = nil) -> Double? {
        guard let subject = subject else { return nil }

        let hashValue = "\(feature.identifier).\(subject.identifier)".hashValue

        return normalize(hashValue)
    }


    // MARK: - Private
    
    private func normalize(_ value: Int) -> Double {
        return Double(value) / Double(Int.max)
    }
}


/**
 Weights a subject to a particular, hard-coded selector value.
*/
public class FixedFeatureSelector: FeatureSelector {
    
    private let weight: Double
    
    // MARK: - Initialization

    public init(weight: Double) {
        self.weight = weight
    }

    // MARK: - Protocols
    
    // MARK: <FeatureSelector>

    public func select(_ feature: Feature, subject: FeatureSubject?) -> Double? {
        return weight
    }
}
