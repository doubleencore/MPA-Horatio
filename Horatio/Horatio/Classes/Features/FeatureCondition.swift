//
//  Copyright © 2016 Kevin Tatroe. All rights reserved.
//  See LICENSE.txt for this sample’s licensing information

import Foundation


/**
 Determines whether a feature is currently available to a given `FeatureSubject`.
*/
public protocol FeatureCondition {
    func isMet(_ subject: FeatureSubject?) -> Bool
}


/**
 Feature is available conditionally before, after, or during certain dates.
*/
public class DateFeatureCondition: FeatureCondition {
    
    private let startDate: Date?
    private let endDate: Date?
    
    // MARK: - Initialization

    public init(startDate: Date? = nil, endDate: Date? = nil) {
        self.startDate = startDate
        self.endDate = endDate
    }
    
    // MARK: - Protocols
    
    // MARK: - <FeatureCondition>
    
    public func isMet(_ subject: FeatureSubject?) -> Bool {
        let currentDate = Date()
        
        if let startDate = startDate {
            if currentDate.compare(startDate) == ComparisonResult.orderedAscending {
                return false
            }
        }
        
        if let endDate = endDate {
            if currentDate.compare(endDate) == ComparisonResult.orderedDescending {
                return false
            }
        }
        
        return true
    }
}


/**
 Feature is available based on the inverse of another condition. (Outside of a certain
 range of dates, for example).
*/
public class InverseFeatureCondition: FeatureCondition {
    
    private let condition: FeatureCondition
    
    // MARK: - Initialization
    
    public init(condition: FeatureCondition) {
        self.condition = condition
    }
    
    
    // MARK: - Protocols
    
    // MARK: - <FeatureCondition>
    
    public func isMet(_ subject: FeatureSubject?) -> Bool {
        return !condition.isMet(subject)
    }
}


/**
 Feature is available only when two other conditions are met.
*/
public class AndFeatureCondition: FeatureCondition {
    
    private let lhs: FeatureCondition
    private let rhs: FeatureCondition
    
    // MARK: - Initialization

    public init(lhs: FeatureCondition, rhs: FeatureCondition) {
        self.lhs = lhs
        self.rhs = rhs
    }
    
    
    // MARK: - Protocols
    
    // MARK: - <FeatureCondition>
    
    public func isMet(_ subject: FeatureSubject?) -> Bool {
        return lhs.isMet(subject) && rhs.isMet(subject)
    }
}
