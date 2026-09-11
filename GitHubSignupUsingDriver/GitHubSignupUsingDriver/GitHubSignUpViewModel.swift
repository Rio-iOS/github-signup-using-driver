import RxSwift
import RxCocoa

/// 入力ストリームを検証結果・送信状態・登録結果へ変換するMVVMの表示層。
final class GitHubSignUpViewModel {
    let validatedUsername: Driver<ValidationResult>
    let validatedPassword: Driver<ValidationResult>
    let validatedPasswordRepeated: Driver<ValidationResult>
    
    // 入力条件を満たし、登録処理中でないときにボタンを有効にする。
    let isSignUpEnabled: Driver<Bool>
    
    // モック登録の結果。実際のGitHub認証状態を表すものではありません。
    let signedIn: Driver<Bool>
    
    // 登録操作に対応するObservableの購読が継続しているか。
    let signingIn: Driver<Bool>
    
    init(
        input: (
            username: Driver<String>,
            password: Driver<String>,
            repeatedPassword: Driver<String>,
            signUpTaps: Signal<()>
        ),
        dependency: (
            signUpUseCase: SignUpUseCase,
            validationService: GitHubValidationService,
            wireframe: Wireframe
        )
    ) {
        let signUpUseCase = dependency.signUpUseCase
        let validationService = dependency.validationService
        let wireframe = dependency.wireframe
        
        // Observableをsubscribeせず出力へ変換している
        
        // Driverは共有とメインスレッドへの配送を保証するため、同じ設定をここで重ねる必要はない。
        validatedUsername = input.username
            .flatMapLatest({ username in
                return validationService.validateUsername(username)
                    .asDriver(onErrorJustReturn: .failed(message: "Error contacting server"))
            })
       
        // Observableのmapオペレータによる変換と同じように、Driverもmapにより変換できる
        // Driverは接続中の購読を共有し、新しい購読者へ最新の1件を再送する。
        validatedPassword = input.password
            .map({ password in
                return validationService.validatePassword(password)
            })
        
        validatedPasswordRepeated = Driver.combineLatest(
            input.password,
            input.repeatedPassword,
            resultSelector: validationService.validateRepeatedPassword
        )
        
        let signingIn = ActivityIndicator()
        self.signingIn = signingIn.asDriver()
        
        let usernameAndPassword = Driver.combineLatest(
            input.username,
            input.password
        ) {
            (username: $0, password: $1)
        }
        
        signedIn = input.signUpTaps.withLatestFrom(usernameAndPassword)
            .flatMapLatest { pair in
                return signUpUseCase.execute(username: pair.username, password: pair.password)
                    .trackActivity(signingIn)
                    .asDriver(onErrorJustReturn: false)
            }
            .flatMapLatest{ loggedIn -> Driver<Bool> in
                let message = loggedIn ? "Mock: Signed in to GitHub." : "Mock: Sign in to GitHub failed"
                return wireframe.promptFor(
                    message,
                    cancelAction: "OK",
                    actions: []
                )
                .map { _ in
                    loggedIn
                }
                .asDriver(onErrorJustReturn: false)
            }
        
        isSignUpEnabled = Driver.combineLatest(
            validatedUsername,
            validatedPassword,
            validatedPasswordRepeated,
            signingIn) { username, password, repeatPassword, signingIn in
                username.isValid &&
                password.isValid &&
                repeatPassword.isValid &&
                !signingIn
            }
            .distinctUntilChanged()
    }
}
