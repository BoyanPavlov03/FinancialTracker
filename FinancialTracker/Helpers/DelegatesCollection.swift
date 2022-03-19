//
//  DelegatesCollection.swift
//  FinancialTracker
//
//  Created by Boyan Pavlov on 4.02.22.
//

import Foundation

/// One-to-many delegate releationships
class DelegatesCollection<T>: Sequence {
    
    private lazy var weakDelegates = [WeakContainer]()
    
    var delegates: [T] {
        weakDelegates = weakDelegates.filter { $0.get() != nil }
        // swiftlint:disable:next force_cast
        return weakDelegates.map { $0.get() as! T }
    }
    
    public init() { }
    
    func add(delegate: T) {
        var exists = false
        for currentDelegate in weakDelegates {
            if currentDelegate.get() === (delegate as AnyObject) {
                exists = true
                break
            }
        }
        
        if !exists {
            weakDelegates.append(WeakContainer(value: delegate as AnyObject))
        }
    }
    
    func remove(delegate: T) {
        var iterator = 0
        for currentDelegate in weakDelegates {
            if currentDelegate.get() == nil || currentDelegate.get() === (delegate as AnyObject) {
                weakDelegates.remove(at: iterator)
                break
            }
            
            iterator += 1
        }
    }
    
    func makeIterator() -> IndexingIterator<[T]> {
        return delegates.makeIterator()
    }
}

class WeakContainer {
    
    private weak var value: AnyObject?
    
    public init(value: AnyObject) {
        self.value = value
    }
    
    func get() -> AnyObject? {
        return self.value
    }
}
