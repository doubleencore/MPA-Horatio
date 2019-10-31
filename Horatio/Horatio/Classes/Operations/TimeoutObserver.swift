/*
Copyright (C) 2015 Apple Inc. All Rights Reserved.
See LICENSE.txt for this sample’s licensing information

Abstract:
This file shows how to implement the OperationObserver protocol.
*/

import Foundation

/**
    `TimeoutObserver` is a way to make an `Operation` automatically time out and
    cancel after a specified time interval.
*/
public class TimeoutObserver: OperationObserver {
    // MARK: Properties

    static let timeoutKey = "Timeout"

    private let timeout: TimeInterval

    private var timer: Timer?

    /// Returns the time interval left until this observer will timeout. If the timeout has been canceled, returns nil.
    var timeLeft: TimeInterval? {
        guard let timer = timer else { return timeout }
        guard timer.isValid else { return nil }

        let date = timer.fireDate
        return date.timeIntervalSinceNow
    }

    // MARK: Initialization
    public init(timeout: TimeInterval) {
        self.timeout = timeout
    }

    public func cancel() {
        timer?.invalidate()
    }

    // MARK: OperationObserver
    public func operationDidStart(_ operation: Operation) {
        timer = Timer.scheduledTimer(withTimeInterval: timeout, repeats: false, block: { [weak self, weak operation] _ in
            guard let self = self,
                let operation = operation
            else { return }

            if !operation.isFinished && !operation.isCancelled {
                let error = NSError(code: .executionFailed, userInfo: [
                    type(of: self).timeoutKey: self.timeout
                ])

                operation.cancelWithError(error)
            }
        })
    }

    public func operation(_ operation: Operation, didProduceOperation newOperation: Foundation.Operation) {
        // No op.
    }

    public func operationDidFinish(_ operation: Operation, errors: [Error]) {
        // No op.
    }
}
