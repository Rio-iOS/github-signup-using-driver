//
//  GitHubSignUpViewModel.swift
//  GitHubSignupUsingDriver
//
//  Created by 藤門莉生 on 2023/02/14.
//

import RxSwift
import RxCocoa

final class GitHubSignUpViewModel {
    // ViewModelの実装1. 出力としてのプロパティを宣言
    let validatedUsername: Driver<ValidationResult>
    let validatedPassword: Driver<ValidationResult>
    let validatedPasswordRepeated: Driver<ValidationResult>
    
    // Is signUp button enabled
    let isSignUpEnabled: Driver<Bool>
    
    // Has user signed in
    let signedIn: Driver<Bool>
    
    // Is signing process in progress
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
        
        // ViewModelの実装2. イニシャライザで
        // Observableをsubscribeせず出力へ変換している
        
        // ViewModelの実装2_2
        // flatMapLatestにおけるObservableとDriverの違いは、observeOn(MainScheduler.instance)によるスレッドの切り替えやshare(repalay: 1)は呼び出していない
        validatedUsername = input.username
            .flatMapLatest({ username in
                return validationService.validateUsername(username)
                    .asDriver(onErrorJustReturn: .failed(message: "Error contacting server"))
            })
       
        // ViewModelの実装2_1
        // Observableのmapオペレータによる変換と同じように、Driverもmapにより変換できる
        // DriverとObservableの違いは、share(replay: 1)メソッドを呼び出さずに済んでいる点
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
