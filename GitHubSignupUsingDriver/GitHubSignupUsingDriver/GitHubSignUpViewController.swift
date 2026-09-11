//
//  ViewController.swift
//  GitHubSignupUsingDriver
//
//  Created by 藤門莉生 on 2023/02/13.
//

import UIKit
import RxSwift
import RxCocoa

final class GitHubSignUpViewController: UIViewController {

    // ViewControllerの実装1. 出力としてのプロパティを宣言
    @IBOutlet private weak var usernameTextField: UITextField!
    @IBOutlet private weak var usernameValidationLabel: UILabel!
    @IBOutlet private weak var passwordTextField: UITextField!
    @IBOutlet private weak var passwordValidationLabel: UILabel!
    @IBOutlet private weak var confirmationTextField: UITextField!
    @IBOutlet private weak var confirmationValidationLabel: UILabel!
    @IBOutlet private weak var signUpButton: UIButton!
    @IBOutlet private weak var activityIndicatorView: UIActivityIndicatorView!
    
    let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // ViewControllerの実装2. ViewModelを初期化
        let viewModel = GitHubSignUpViewModel(
            input: (
                // ViewControllerの実装2_1
                username: usernameTextField.rx.text.orEmpty.asDriver(),
                password: passwordTextField.rx.text.orEmpty.asDriver(),
                repeatedPassword: confirmationTextField.rx.text.orEmpty.asDriver(),
                
                // ViewControllerの実装2_2
                // タップイベントをObservableのストリームではなく、Signalというストリームに変換
                // Signalの特性
                // - Driverの特性にさらにreplayされないという特性を持っている
                //   - replayされない：過去のイベントを一切保持せず、その値も保持していない
                //   - Driverは、購読直後にもし最新のイベントがあれば、そのイベントを流そうとするが、Signalはそのような動作はしない。UIButtonのタップイベントに向いている
                //   - replayしないという挙動があることを型で表現することは、コードの意図を人へ伝えるという点においてとても意味のあること
                signUpTaps: signUpButton.rx.tap.asSignal()
            ),
            dependency: (
                signUpUseCase: SignUpUseCase(repository: GitHubDefaultAPI.shared),
                validationService: GitHubDefaultValidationService.shared,
                wireframe: DefaultWireframe(viewController: self)
            )
        )
        
        // ViewControllerの実装3. ViewModelからの出力からViewにbind
        // ViewControllerの実装3_1
        // Driverを使ってバインドを実施する場合、subscribeやbindメソッドではなくdriveメソッドを使う
        viewModel.isSignUpEnabled
            .drive(onNext: { [weak self] valid in
                self?.signUpButton.isEnabled = valid
                self?.signUpButton.alpha = valid ? 1.0 : 0.5
            })
            .disposed(by: disposeBag)
        
        // ViewControllerの実装3_2
        // Driverを使ってバインドを実施する場合、subscribeやbindメソッドではなくdriveメソッドを使う
        viewModel.validatedUsername
            .drive(usernameValidationLabel.rx.validationResult)
            .disposed(by: disposeBag)
        
        viewModel.validatedPassword
            .drive(passwordValidationLabel.rx.validationResult)
            .disposed(by: disposeBag)
        
        viewModel.validatedPasswordRepeated
            .drive(confirmationValidationLabel.rx.validationResult)
            .disposed(by: disposeBag)
        
        viewModel.signingIn
            .drive(activityIndicatorView.rx.isAnimating)
            .disposed(by: disposeBag)
        
        viewModel.signedIn
            .drive(onNext: { signedIn in
                print("User signed in \(signedIn)")
            })
            .disposed(by: disposeBag)
        
        let tapBackground = UITapGestureRecognizer()
        tapBackground.rx.event
            .subscribe(onNext: { [weak self] _ in
                self?.view.endEditing(true)
            })
            .disposed(by: disposeBag)
        view.addGestureRecognizer(tapBackground)
    }


}

