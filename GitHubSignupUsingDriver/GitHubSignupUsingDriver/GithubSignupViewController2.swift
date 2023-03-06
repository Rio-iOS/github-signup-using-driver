//
//  ViewController.swift
//  GitHubSignupUsingDriver
//
//  Created by 藤門莉生 on 2023/02/13.
//

import UIKit
import RxSwift
import RxCocoa

class GithubSignupViewController2: UIViewController {

    // ViewControllerの実装1. 出力としてのプロパティを宣言
    @IBOutlet weak var usernameOutlet: UITextField!
    @IBOutlet weak var usernameValidationOutlet: UILabel!
    @IBOutlet weak var passwordOutlet: UITextField!
    @IBOutlet weak var passwordValidationOutlet: UILabel!
    @IBOutlet weak var repeatedPasswordOutlet: UITextField!
    @IBOutlet weak var repeatedPasswordValidationOutlet: UILabel!
    @IBOutlet weak var signupOutlet: UIButton!
    @IBOutlet weak var signingUpOutlet: UIActivityIndicatorView!
    
    let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // ViewControllerの実装2. ViewModelを初期化
        let viewModel = GithubSignupViewModel2(
            input: (
                // ViewControllerの実装2_1
                username: usernameOutlet.rx.text.orEmpty.asDriver(),
                password: passwordOutlet.rx.text.orEmpty.asDriver(),
                repeatedPassword: repeatedPasswordOutlet.rx.text.orEmpty.asDriver(),
                
                // ViewControllerの実装2_2
                // タップイベントをObservableのストリームではなく、Signalというストリームに変換
                // Signalの特性
                // - Driverの特性にさらにreplayされないという特性を持っている
                //   - replayされない：過去のイベントを一切保持せず、その値も保持していない
                //   - Driverは、購読直後にもし最新のイベントがあれば、そのイベントを流そうとするが、Signalはそのような動作はしない。UIButtonのタップイベントに向いている
                //   - replayしないという挙動があることを型で表現することは、コードの意図を人へ伝えるという点においてとても意味のあること
                loginTaps: signupOutlet.rx.tap.asSignal()
            ),
            dependency: (
                API: GitHubDefaultAPI.sharedAPI,
                validationService: GitHubDefaultValidationService.sharedValidationService,
                wireframe: DefaultWireframe.shared
            )
        )
        
        // ViewControllerの実装3. ViewModelからの出力からViewにbind
        // ViewControllerの実装3_1
        // Driverを使ってバインドを実施する場合、subscribeやbindメソッドではなくdriveメソッドを使う
        viewModel.signupEnabled
            .drive(onNext: { [weak self] valid in
                self?.signupOutlet.isEnabled = valid
                self?.signupOutlet.alpha = valid ? 1.0 : 0.5
            })
            .disposed(by: disposeBag)
        
        // ViewControllerの実装3_2
        // Driverを使ってバインドを実施する場合、subscribeやbindメソッドではなくdriveメソッドを使う
        viewModel.validatedUsername
            .drive(usernameValidationOutlet.rx.validationResult)
            .disposed(by: disposeBag)
        
        viewModel.validatedPassword
            .drive(passwordValidationOutlet.rx.validationResult)
            .disposed(by: disposeBag)
        
        viewModel.validatedPasswordRepeated
            .drive(repeatedPasswordValidationOutlet.rx.validationResult)
            .disposed(by: disposeBag)
        
        viewModel.signingIn
            .drive(signingUpOutlet.rx.isAnimating)
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

