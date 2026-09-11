import UIKit
import RxSwift
import RxCocoa

/// 入力をViewModelへ渡し、検証結果と送信状態をUIへバインドする登録画面。
final class GitHubSignUpViewController: UIViewController {

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
        
        let viewModel = GitHubSignUpViewModel(
            input: (
                username: usernameTextField.rx.text.orEmpty.asDriver(),
                password: passwordTextField.rx.text.orEmpty.asDriver(),
                repeatedPassword: confirmationTextField.rx.text.orEmpty.asDriver(),
                
                // タップイベントをObservableのストリームではなく、Signalというストリームに変換
                // Signalは新しい購読へ過去のタップを再送しない。画面状態を表すDriverと使い分ける。
                signUpTaps: signUpButton.rx.tap.asSignal()
            ),
            dependency: (
                signUpUseCase: SignUpUseCase(repository: GitHubDefaultAPI.shared),
                validationService: GitHubDefaultValidationService.shared,
                wireframe: DefaultWireframe(viewController: self)
            )
        )
        
        // Driverを使ってバインドを実施する場合、subscribeやbindメソッドではなくdriveメソッドを使う
        viewModel.isSignUpEnabled
            .drive(onNext: { [weak self] valid in
                self?.signUpButton.isEnabled = valid
                self?.signUpButton.alpha = valid ? 1.0 : 0.5
            })
            .disposed(by: disposeBag)
        
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

