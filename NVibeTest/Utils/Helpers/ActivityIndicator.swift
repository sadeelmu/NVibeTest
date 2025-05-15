//
//  ActivityIndicator.swift
//  NVibeTest
//
//  Created by Sadeel Muwahed on 15/05/2025.
//

import Foundation
import RxSwift
import RxCocoa

/// Utility to track activity (loading) state for Rx streams.
final class ActivityIndicator: SharedSequenceConvertibleType {
    typealias Element = Bool
    typealias SharingStrategy = DriverSharingStrategy

    private let _lock = NSRecursiveLock()
    private let _relay = BehaviorRelay(value: 0)
    private let _loading: SharedSequence<SharingStrategy, Bool>

    init() {
        _loading = _relay
            .asDriver()
            .map { $0 > 0 }
            .distinctUntilChanged()
    }

    func trackActivityOfObservable<O: ObservableConvertibleType>(_ source: O) -> Observable<O.Element> {
        return Observable.using({ () -> ActivityToken<O.Element> in
            self.increment()
            return ActivityToken(source: source.asObservable(), disposeAction: self.decrement)
        }) { t in
            t.asObservable()
        }
    }

    private func increment() {
        _lock.lock()
        _relay.accept(_relay.value + 1)
        _lock.unlock()
    }

    private func decrement() {
        _lock.lock()
        _relay.accept(_relay.value - 1)
        _lock.unlock()
    }

    func asSharedSequence() -> SharedSequence<SharingStrategy, Element> {
        return _loading
    }
}

private struct ActivityToken<Element>: ObservableConvertibleType, Disposable {
    private let _source: Observable<Element>
    private let _dispose: Cancelable

    init(source: Observable<Element>, disposeAction: @escaping () -> Void) {
        _source = source
        _dispose = Disposables.create(with: disposeAction)
    }

    func dispose() {
        _dispose.dispose()
    }

    func asObservable() -> Observable<Element> {
        return _source
    }
}

extension ObservableConvertibleType {
    /// Tracks the activity using the given ActivityIndicator.
    func trackActivity(_ activityIndicator: ActivityIndicator) -> Observable<Element> {
        return activityIndicator.trackActivityOfObservable(self)
    }
}
