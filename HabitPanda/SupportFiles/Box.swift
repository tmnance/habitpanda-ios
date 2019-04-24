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
    var listener: Listener?

    var value: T {
        didSet {
            listener?(value)
        }
    }

    init(_ value: T) {
        self.value = value
    }

    func bind(listener: Listener?) {
        self.listener = listener
        listener?(value)
    }
}
