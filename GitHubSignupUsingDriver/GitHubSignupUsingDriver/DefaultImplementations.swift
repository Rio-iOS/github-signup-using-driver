import RxSwift
import Foundation

/// この教材のユーザー名・パスワードの入力条件を検証するサービス。
final class GitHubDefaultValidationService: GitHubValidationService {

    private let api: GitHubAPI

    static let shared = GitHubDefaultValidationService(api: GitHubDefaultAPI.shared)

    init(api: GitHubAPI) {
        self.api = api
    }

    // validation

    private let minimumPasswordLength = 5

    func validateUsername(_ username: String) -> Observable<ValidationResult> {
        if username.isEmpty {
            return .just(.empty)
        }

        // この教材では英数字のみをユーザー名として扱う。GitHubの入力規則全体の再現ではない。
        if username.rangeOfCharacter(from: CharacterSet.alphanumerics.inverted) != nil {
            return .just(.failed(message: "Username can only numbers or digits"))
        }

        let loadingValue = ValidationResult.validating

        return api
            .isUsernameAvailable(username)
            .map { available in
                if available {
                    return .ok(message: "Username available")
                } else {
                    return .failed(message: "Username already taken")
                }
            }
            .startWith(loadingValue)
    }

    func validatePassword(_ password: String) -> ValidationResult {
        let numberOfCharacters = password.count
        if numberOfCharacters == 0 {
            return .empty
        }

        if numberOfCharacters < minimumPasswordLength {
            return .failed(message: "Password must be at least \(minimumPasswordLength) characters")
        }

        return .ok(message: "Password acceptable")
    }

    func validateRepeatedPassword(_ password: String, repeatedPassword: String) -> ValidationResult {
        if repeatedPassword.count == 0 {
            return .empty
        }

        if repeatedPassword == password {
            return .ok(message: "Passsword repeated")
        } else {
            return .failed(message: "Password different")
        }
    }
}

/// ユーザー名の簡易確認にはHTTP通信を使い、登録操作にはモック結果を返す実装。
final class GitHubDefaultAPI: GitHubAPI {
    private let session: Foundation.URLSession

    static let shared = GitHubDefaultAPI(
        session: Foundation.URLSession.shared
    )

    init(session: Foundation.URLSession) {
        self.session = session
    }

    func isUsernameAvailable(_ username: String) -> Observable<Bool> {
        // ユーザーの公開ページへ実際にGETし、404のときだけ利用可能とみなす簡易判定。

        let url = URL(string: "https://github.com/\(username.urlPathEncoded)")!
        let request = URLRequest(url: url)
        return session.rx.response(request: request)
            .map { pair in
                return pair.response.statusCode == 404
            }
            .catchAndReturn(false)
    }

    func signUp(_ username: String, password: String) -> Observable<Bool> {
        // 実際の登録は行わず、ランダムな成否を1秒後に返す。
        let signupResult = arc4random() % 5 == 0 ? false : true

        return Observable.just(signupResult)
            .delay(.seconds(1), scheduler: MainScheduler.instance)
    }


}
