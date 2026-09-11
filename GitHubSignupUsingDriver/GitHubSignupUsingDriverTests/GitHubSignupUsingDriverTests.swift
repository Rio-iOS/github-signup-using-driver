import Foundation
import XCTest
import RxSwift
import RxCocoa
#if canImport(SignUpCore)
@testable import SignUpCore
#else
@testable import GitHubSignupUsingDriver
#endif

final class SignUpTests: XCTestCase {
    func testValidationRejectsInvalidInput() {
        let validation = GitHubDefaultValidationService(api: APIStub())
        XCTAssertFalse(validation.validatePassword("").isValid)
        XCTAssertFalse(validation.validatePassword("1234").isValid)
        XCTAssertTrue(validation.validatePassword("12345").isValid)
        XCTAssertFalse(validation.validateRepeatedPassword("12345", repeatedPassword: "12346").isValid)
    }

    func testMockUsesInjectedClockAndDisposalStopsResult() {
        let clock = HistoricalScheduler(initialClock: Date(timeIntervalSince1970: 0))
        var calls = 0
        let api = GitHubDefaultAPI(session: .shared, scheduler: clock, signUpResult: { calls += 1; return .success(false) })
        let operation = api.signUp("rio", password: "12345")
        XCTAssertEqual(calls, 0)
        var results: [Bool] = []
        let first = operation.subscribe(onNext: { results.append($0) })
        XCTAssertEqual(calls, 1)
        clock.advanceTo(Date(timeIntervalSince1970: 0.9))
        XCTAssertTrue(results.isEmpty)
        first.dispose()
        clock.advanceTo(Date(timeIntervalSince1970: 2))
        XCTAssertTrue(results.isEmpty)
        let second = operation.subscribe(onNext: { results.append($0) })
        clock.advanceTo(Date(timeIntervalSince1970: 3))
        XCTAssertEqual(results, [false])
        second.dispose()
    }

    func testInvalidAndRepeatedTapsDoNotStartExtraRequestsAndFailureAllowsRetry() {
        let api = APIStub()
        let username = BehaviorRelay(value: "rio")
        let password = BehaviorRelay(value: "12345")
        let repeated = BehaviorRelay(value: "wrong")
        let taps = PublishRelay<Void>()
        let model = GitHubSignUpViewModel(input: (username: username.asDriver(), password: password.asDriver(), repeatedPassword: repeated.asDriver(), signUpTaps: taps.asSignal()), dependency: (signUpUseCase: SignUpUseCase(repository: api), validationService: GitHubDefaultValidationService(api: api), wireframe: WireframeStub()))
        var results: [Bool] = []
        let subscription = model.signedIn.asObservable().subscribe(onNext: { results.append($0) })
        taps.accept(())
        XCTAssertEqual(api.signUpCalls, 0)
        repeated.accept("12345")
        taps.accept(())
        taps.accept(())
        XCTAssertEqual(api.signUpCalls, 1)
        api.pending.onError(URLError(.timedOut))
        XCTAssertEqual(results, [false])
        api.pending = PublishSubject<Bool>()
        taps.accept(())
        XCTAssertEqual(api.signUpCalls, 2)
        XCTAssertTrue(api.pending.hasObservers)
        subscription.dispose()
        XCTAssertFalse(api.pending.hasObservers)
    }

    func testChangingUsernameDisposesOldValidationAndDoesNotRetainViewModel() {
        let api = APIStub()
        api.availability = PublishSubject<Bool>()
        let username = BehaviorRelay(value: "old")
        let password = BehaviorRelay(value: "12345")
        let taps = PublishRelay<Void>()
        var model: GitHubSignUpViewModel? = GitHubSignUpViewModel(input: (username: username.asDriver(), password: password.asDriver(), repeatedPassword: password.asDriver(), signUpTaps: taps.asSignal()), dependency: (signUpUseCase: SignUpUseCase(repository: api), validationService: GitHubDefaultValidationService(api: api), wireframe: WireframeStub()))
        weak var weakModel = model
        var values: [Bool] = []
        let subscription = model!.validatedUsername.asObservable().subscribe(onNext: { values.append($0.isValid) })
        let old = api.availability!
        api.availability = PublishSubject<Bool>()
        username.accept("new")
        XCTAssertFalse(old.hasObservers)
        old.onNext(true)
        XCTAssertEqual(values.last, false)
        api.availability?.onNext(true)
        XCTAssertEqual(values.last, true)
        subscription.dispose()
        XCTAssertFalse(api.availability!.hasObservers)
        model = nil
        XCTAssertNil(weakModel)
    }
}

private final class APIStub: GitHubAPI {
    var signUpCalls = 0
    var pending = PublishSubject<Bool>()
    var availability: PublishSubject<Bool>?
    func isUsernameAvailable(_ username: String) -> Observable<Bool> { availability?.asObservable() ?? .just(true) }
    func signUp(_ username: String, password: String) -> Observable<Bool> { signUpCalls += 1; return pending }
}

private struct WireframeStub: Wireframe {
    func open(url: URL) {}
    func promptFor<Action: CustomStringConvertible>(_ message: String, cancelAction: Action, actions: [Action]) -> Observable<Action> { .just(cancelAction) }
}
