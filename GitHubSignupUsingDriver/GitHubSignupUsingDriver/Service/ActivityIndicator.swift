import RxSwift
import RxCocoa
import Foundation

private struct ActivityToken<E>: ObservableConvertibleType, Disposable {
    private let source: Observable<E>
    private let cancellation: Cancelable
    
    init(source: Observable<E>, disposeAction: @escaping () -> Void) {
        self.source = source
        cancellation = Disposables.create(with: disposeAction)
    }
    
    func dispose() {
        cancellation.dispose()
    }
    
    func asObservable() -> Observable<E> {
        source
    }
}

final class ActivityIndicator: SharedSequenceConvertibleType {
    
    typealias Element = Bool
    typealias SharingStrategy = DriverSharingStrategy
    
    private let lock = NSRecursiveLock()
    private let relay = BehaviorRelay(value: 0)
    private let loading: SharedSequence<SharingStrategy, Bool>
    
    init() {
        loading = relay.asDriver()
            .map { $0 > 0}
            .distinctUntilChanged()
    }
    
    fileprivate func trackActivityOfObservable<Source: ObservableConvertibleType>(_ source: Source) -> Observable<Source.Element> {
        return Observable.using({ () -> ActivityToken<Source.Element> in self.increment()
            return ActivityToken(source: source.asObservable(), disposeAction: self.decrement)
        }) { t in
            return t.asObservable()
        }
    }
    
    private func increment() {
        lock.lock()
        relay.accept(relay.value + 1)
        lock.unlock()
    }
    
    private func decrement() {
        lock.lock()
        relay.accept(relay.value - 1)
        lock.unlock()
    }
    
    func asSharedSequence() -> RxCocoa.SharedSequence<RxCocoa.DriverSharingStrategy, Bool> {
        loading
    }
}

extension ObservableConvertibleType {
    func trackActivity(_ activityIndicator: ActivityIndicator) -> Observable<Element> {
        activityIndicator.trackActivityOfObservable(self)
    }
}
