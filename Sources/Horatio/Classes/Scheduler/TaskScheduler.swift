//
//  Copyright © 2016 Kevin Tatroe. All rights reserved.
//  See LICENSE.txt for this sample’s licensing information

import Foundation


public protocol ScheduledTaskProvider {
    var identifier: String { get }

    func makeScheduledTasks() -> [Operation]
}


public protocol ScheduledTaskCoordinator {
    func pause()
    func resume()

    func scheduleTasks()

    func addTaskProvider(_ provider: ScheduledTaskProvider)
    func removeTaskProvider(_ provider: ScheduledTaskProvider)
}


open class TimedTaskCoordinator : ScheduledTaskCoordinator {
    struct Behaviors {
        static let TimerInterval: TimeInterval = 10.0
    }

    var providers = [ScheduledTaskProvider]()
    var isActive = false

    var updateTimer: Foundation.Timer?
    fileprivate let serialQueue = DispatchQueue(label: "TimedTaskCoordinator.SerialQueue", attributes: [])


    // MARK: - Initialization

    init() {
        resume()
    }


    deinit {
        pause()
    }


    // MARK: - Protocols

    // MARK: <ScheduledTaskCoordinator>

    public func pause() {
        isActive = false

        updateTimer?.invalidate()
        updateTimer = nil
    }


    public func resume() {
        isActive = true

        DispatchQueue.main.async {
            if self.updateTimer == nil {
                self.updateTimer = Foundation.Timer.scheduledTimer(timeInterval: Behaviors.TimerInterval, target: self, selector: #selector(self.timerFired), userInfo: nil, repeats: true)
            }
            
            if let updateTimer = self.updateTimer {
                updateTimer.fire()
            }
        }
    }


    public func scheduleTasks() {
        guard isActive else { return }
        guard let queue = try? Container.resolve(OperationQueue.self) else { return }

        serialQueue.sync {
            for provider in self.providers {
                for operation in provider.makeScheduledTasks() {
                    queue.addOperation(operation)
                }
            }
        }
    }


    public func addTaskProvider(_ provider: ScheduledTaskProvider) {
        providers.append(provider)
    }


    public func removeTaskProvider(_ provider: ScheduledTaskProvider) {
        guard let index = providers.firstIndex(where: { (testProvider) -> Bool in
            return testProvider.identifier == provider.identifier
        }) else { return }

        providers.remove(at: index)
    }


    // MARK: - Private

    @objc
    fileprivate func timerFired(_ timer: Foundation.Timer) {
        scheduleTasks()
    }
}
