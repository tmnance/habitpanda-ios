//
//  Box.swift
//  HabitPanda
//
//  Created by Tim Nance on 4/23/19.
//  Copyright © 2019 Tim Nance. All rights reserved.
//

import Foundation

class Box<T> {
    typealias Listener = (T) -> Void
    private var listener: Listener?

    var value: T {
        didSet {
            triggerListener()
        }
    }

    init(_ value: T) {
        self.value = value
    }

    func bind(listener: Listener?) {
        self.listener = listener
        triggerListener()
    }

    private func triggerListener() {
        guard let listener = listener else {
            return
        }
        if BoxHelper.delayListenerInvocation {
            BoxHelper.delayedListenerQueue.append({
                listener(self.value)
            })
        } else {
            listener(value)
        }
    }
}

struct BoxHelper {
    static func processBeforeListenerInvocation(_ block: () -> Void) {
        BoxHelper.delayListenerInvocation = true
        block()
        BoxHelper.delayListenerInvocation = false
        BoxHelper.invokeDelayedListeners()
    }
}

private extension BoxHelper {
    static var delayListenerInvocation: Bool = false
    static var delayedListenerQueue: [() -> Void] = []
    static func invokeDelayedListeners() {
        while delayedListenerQueue.count > 0 {
            let listener = delayedListenerQueue.removeFirst()
            listener()
        }
    }
}
