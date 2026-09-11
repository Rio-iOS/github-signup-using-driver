import RxSwift
import RxCocoa

/// 入力の検証と登録操作を結び、処理中の連打による重複登録を防ぐ表示層。
final class GitHubSignUpViewModel {
    let validatedUsername: Driver<ValidationResult>
    let validatedPassword: Driver<ValidationResult>
    let validatedPasswordRepeated: Driver<ValidationResult>
    let isSignUpEnabled: Driver<Bool>
    let signingIn: Driver<Bool>
    /// アラートの確認後に流れる操作結果。新しい購読者には過去の結果を再送しません。
    let signedIn: Signal<Bool>

    init(
        input: (username: Driver<String>, password: Driver<String>, repeatedPassword: Driver<String>, signUpTaps: Signal<Void>),
        dependency: (signUpUseCase: SignUpUseCase, validationService: GitHubValidationService, wireframe: Wireframe)
    ) {
        let validation = dependency.validationService
        let username = input.username.asObservable()
        let password = input.password.asObservable()
        let repeatedPassword = input.repeatedPassword.asObservable()
        // 新しい名前に切り替わったら、以前の検証結果は表示へ戻さない。
        let validatedUsername = username.distinctUntilChanged()
            .flatMapLatest { validation.validateUsername($0)
                .observe(on: MainScheduler.instance)
                .catchAndReturn(.failed(message: "Error contacting server"))
            }
            .share(replay: 1, scope: .whileConnected)
        let validatedPassword = password.map(validation.validatePassword)
            .share(replay: 1, scope: .whileConnected)
        let validatedPasswordRepeated = Observable.combineLatest(password, repeatedPassword, resultSelector: validation.validateRepeatedPassword)
            .share(replay: 1, scope: .whileConnected)
        let activity = ActivityIndicator()
        let enabled = Observable.combineLatest(validatedUsername, validatedPassword, validatedPasswordRepeated, activity.asObservable()) {
            $0.isValid && $1.isValid && $2.isValid && !$3
        }.distinctUntilChanged().share(replay: 1, scope: .whileConnected)
        self.validatedUsername = validatedUsername.asDriver(onErrorJustReturn: .failed(message: "Invalid input"))
        self.validatedPassword = validatedPassword.asDriver(onErrorJustReturn: .empty)
        self.validatedPasswordRepeated = validatedPasswordRepeated.asDriver(onErrorJustReturn: .empty)
        isSignUpEnabled = enabled.asDriver(onErrorJustReturn: false)
        signingIn = activity.asDriver()

        let credentials = Observable.combineLatest(username, password) { (username: $0, password: $1) }
        // UIの有効状態だけに依存せず、ストリーム内でも検証する。
        // 登録からアラート確認までの間は、次の登録操作を受け付けない。
        signedIn = input.signUpTaps.asObservable()
            .withLatestFrom(enabled).filter { $0 }
            .withLatestFrom(credentials)
            .flatMapFirst { pair in
                dependency.signUpUseCase.execute(username: pair.username, password: pair.password)
                    .observe(on: MainScheduler.instance)
                    .catchAndReturn(false)
                    .flatMap { succeeded in
                        dependency.wireframe.promptFor(
                            succeeded ? "Mock: Signed in to GitHub." : "Mock: Sign in to GitHub failed",
                            cancelAction: "OK", actions: []
                        ).map { _ in succeeded }.catchAndReturn(false)
                    }
                    .trackActivity(activity)
            }
            .asSignal(onErrorJustReturn: false)
    }
}
