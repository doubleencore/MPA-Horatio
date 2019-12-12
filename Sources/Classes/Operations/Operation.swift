/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 This file contains the foundational subclass of NSOperation.
 */

import Foundation

/**
 The subclass of `NSOperation` from which all other operations should be derived.
 This class adds both Conditions and Observers, which allow the operation to define
 extended readiness requirements, as well as notify many interested parties
 about interesting operation state changes
 */
open class Operation: Foundation.Operation {

    // use the KVO mechanism to indicate that changes to "state" affect other properties as well
    override open class func keyPathsForValuesAffectingValue(forKey key: String) -> Set<String> {
        var set = super.keyPathsForValuesAffectingValue(forKey: key)

        switch key {
        case #keyPath(isReady), #keyPath(isExecuting), #keyPath(isFinished), #keyPath(isCancelled):
            set.insert("state")
        default:
            break
        }

        return set
    }

    // MARK: State Management
    
    fileprivate enum State: Int, Comparable {
        /// The initial state of an `Operation`.
        case initialized
        
        /// The `Operation` is ready to begin evaluating conditions.
        case pending
        
        /// The `Operation` is evaluating conditions.
        case evaluatingConditions
        
        /**
         The `Operation`'s conditions have all been satisfied, and it is ready
         to execute.
         */
        case ready
        
        /// The `Operation` is executing.
        case executing
        
        /**
         Execution of the `Operation` has finished, but it has not yet notified
         the queue of this.
         */
        case finishing
        
        /// The `Operation` has finished executing.
        case finished
        
        func canTransitionToState(_ target: State) -> Bool {
            switch (self, target) {
            case (.initialized, .pending):
                return true
            case (.pending, .evaluatingConditions):
                return true
            case (.pending, .finishing):
                return true
            case (.evaluatingConditions, .ready):
                return true
            case (.ready, .executing):
                return true
            case (.ready, .finishing):
                return true
            case (.executing, .finishing):
                return true
            case (.finishing, .finished):
                return true
            default:
                return false
            }
        }
    }
    
    /**
     Indicates that the Operation can now begin to evaluate readiness conditions,
     if appropriate.
     */
    func willEnqueue() {
        state = .pending
    }

    /// Private storage for the `state` property that will be KVO observed.
    fileprivate var _state = State.initialized
    
    /// A lock to guard reads and writes to the `_state` property
    fileprivate let stateLock = NSRecursiveLock()
    
    fileprivate var state: State {
        get {
            return stateLock.withCriticalScope {
                _state
            }
        }

        set(newState) {
            stateLock.withCriticalScope { () -> Void in
                willChangeValue(forKey: "state")

                assert(_state.canTransitionToState(newState), "Performing invalid state transition.")

                if _state != .finished {
                    _state = newState
                }

                didChangeValue(forKey: "state")
            }
        }
    }

    // Here is where we extend our definition of "readiness".
    override open var isReady: Bool {
        var result = false

        stateLock.withCriticalScope { () -> Void in
            switch state {

            case .initialized:
                // If the operation has been cancelled, "isReady" should return true
                result = isCancelled

            case .pending:
                // If the operation has been cancelled, "isReady" should return true
                guard !isCancelled else {
                    result = true
                    return
                }

                // If super isReady, conditions can be evaluated
                if super.isReady {
                    evaluateConditions()
                }

                // Until conditions have been evaluated, "isReady" returns false
                result = false

            case .ready:
                result = super.isReady || isCancelled

            default:
                result = false
            }
        }
        
        return result
    }
    
    var userInitiated: Bool {
        get {
            return qualityOfService == .userInitiated
        }

        set {
            assert(state < .executing, "Cannot modify userInitiated after execution has begun.")

            qualityOfService = newValue ? .userInitiated : .default
        }
    }

    fileprivate(set) open var failed = false

    override open var isExecuting: Bool {
        return state == .executing
    }

    override open var isFinished: Bool {
        return state == .finished
    }
    
    fileprivate func evaluateConditions() {
        assert(state == .pending && !isCancelled, "evaluateConditions() was called out-of-order")
        
        state = .evaluatingConditions

        OperationConditionEvaluator.evaluate(conditions, operation: self) { failures in
            self._internalErrors.append(contentsOf: failures)
            self.state = .ready
        }
    }

    // MARK: Observers and Conditions

    fileprivate(set) var conditions = [OperationCondition]()
    
    public func addCondition(_ condition: OperationCondition) {
        assert(state < .evaluatingConditions, "Cannot modify conditions after execution has begun.")

        conditions.append(condition)
    }

    fileprivate(set) var observers = [OperationObserver]()
    
    public func addObserver(_ observer: OperationObserver) {
        assert(state <= .executing, "Cannot modify observers after execution has begun.")

        observers.append(observer)
    }

    override open func addDependency(_ operation: Foundation.Operation) {
        assert(state < .executing, "Dependencies cannot be modified after execution has begun.")
        
        super.addDependency(operation)
    }

    // MARK: Execution and Cancellation

    /*
        I think this is where the main problem is.
        Under certain conditions start will be called, but main will not
        causing the state to be .ready - but it's not executing - the queue never restarts it
    */
    override final public func start() {
        // NSOperation.start() contains important logic that shouldn't be bypassed.
        super.start()

        if name == nil {
            self.name = NSStringFromClass(type(of: self))
        }
        
        // TODO: Remove this spammy log
        if let name = self.name {
            NSLog("%@ started", name)
        }

        // If the operation has been cancelled, we still need to enter the "Finished" state.
        if isCancelled {
            finish()
        }
    }
    
    override final public func main() {
        assert(state == .ready, "This operation must be performed on an operation queue.")
        
        if _internalErrors.isEmpty && !isCancelled {
            state = .executing
            
            for observer in observers {
                observer.operationDidStart(self)
            }
            
            execute()
        }
        else {
            finish()
        }
    }

    /**
     `execute()` is the entry point of execution for all `Operation` subclasses.
     If you subclass `Operation` and wish to customize its execution, you would
     do so by overriding the `execute()` method.
     
     At some point, your `Operation` subclass must call one of the "finish"
     methods defined below; this is how you indicate that your operation has
     finished its execution, and that operations dependent on yours can re-evaluate
     their readiness state.
     */
    open func execute() {
        print("\(type(of: self)) must override `execute()`.")

        finish()
    }

    fileprivate var _internalErrors = [Error]()
    public final func cancelWithError(_ error: Error? = nil) {
        if let error = error {
            _internalErrors.append(error)
        }
        
        cancel()
    }

    public final func produceOperation(_ operation: Foundation.Operation) {
        for observer in observers {
            observer.operation(self, didProduceOperation: operation)
        }
    }

    // MARK: Finishing
    
    /**
     Most operations may finish with a single error, if they have one at all.
     This is a convenience method to simplify calling the actual `finish()`
     method. This is also useful if you wish to finish with an error provided
     by the system frameworks. As an example, see `DownloadEarthquakesOperation`
     for how an error from an `NSURLSession` is passed along via the
     `finishWithError()` method.
     */
    public final func finishWithError(_ error: Error?) {
        if let error = error {
            finish([error])
        }
        else {
            finish()
        }
    }
    
    /**
     A private property to ensure we only notify the observers once that the
     operation has finished.
     */
    fileprivate var hasFinishedAlready = false
    public final func finish(_ errors: [Error] = []) {
        if !hasFinishedAlready {
            hasFinishedAlready = true
            state = .finishing
            
            let combinedErrors = _internalErrors + errors
            failed = !combinedErrors.isEmpty
            
            if let name = name {
                if failed {
                    NSLog("%@ failed due to errors", name)
                } else {
                    NSLog("%@ finished", name)
                }
            }
            
            finished(combinedErrors as [NSError])
            
            for observer in observers {
                observer.operationDidFinish(self, errors: combinedErrors)
            }
            
            state = .finished
        }
    }
    
    /**
     Subclasses may override `finished(_:)` if they wish to react to the operation
     finishing with errors. For example, the `LoadModelOperation` implements
     this method to potentially inform the user about an error when trying to
     bring up the Core Data stack.
     */
    open func finished(_ errors: [NSError]) {
        // No op.
    }

    override final public func waitUntilFinished() {
        /*
         Waiting on operations is almost NEVER the right thing to do. It is
         usually superior to use proper locking constructs, such as `dispatch_semaphore_t`
         or `dispatch_group_notify`, or even `NSLocking` objects. Many developers
         use waiting when they should instead be chaining discrete operations
         together using dependencies.
         
         To reinforce this idea, invoking `waitUntilFinished()` will crash your
         app, as incentive for you to find a more appropriate way to express
         the behavior you're wishing to create.
         */
        fatalError("Waiting on operations is an anti-pattern. Remove this ONLY if you're absolutely sure there is No Other Way™.")
    }
    
}

// Simple operator functions to simplify the assertions used above.
private func <(lhs: Operation.State, rhs: Operation.State) -> Bool {
    return lhs.rawValue < rhs.rawValue
}

private func ==(lhs: Operation.State, rhs: Operation.State) -> Bool {
    return lhs.rawValue == rhs.rawValue
}