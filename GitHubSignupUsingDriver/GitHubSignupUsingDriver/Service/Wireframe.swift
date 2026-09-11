import RxSwift
import UIKit

protocol Wireframe {
    func open(url: URL)
    func promptFor<Action: CustomStringConvertible>(_ message: String, cancelAction: Action, actions: [Action]) -> Observable<Action>
}

/// 表示先を弱参照し、購読の終了に合わせてアラートを閉じる画面操作の実装。
final class DefaultWireframe: Wireframe {
    private weak var viewController: UIViewController?

    init(viewController: UIViewController) {
        self.viewController = viewController
    }

    func open(url: URL) {
        UIApplication.shared.open(url)
    }

    func promptFor<Action: CustomStringConvertible>(_ message: String, cancelAction: Action, actions: [Action]) -> Observable<Action> {
        Observable.create { [weak self] observer in
            guard let viewController = self?.viewController else {
                observer.onCompleted()
                return Disposables.create()
            }
            let alert = UIAlertController(title: "RxExample", message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: cancelAction.description, style: .cancel) { _ in
                observer.onNext(cancelAction)
                observer.onCompleted()
            })
            for action in actions {
                alert.addAction(UIAlertAction(title: action.description, style: .default) { _ in
                    observer.onNext(action)
                    observer.onCompleted()
                })
            }
            viewController.present(alert, animated: true)
            return Disposables.create { [weak alert] in
                alert?.dismiss(animated: false)
            }
        }
        .subscribe(on: MainScheduler.instance)
    }
}
