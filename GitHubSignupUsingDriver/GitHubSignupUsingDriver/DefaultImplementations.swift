import RxSwift
import RxCocoa
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
            return .just(.failed(message: "Username can only contain letters or numbers"))
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
            return .ok(message: "Passwords match")
        } else {
            return .failed(message: "Password different")
        }
    }
}

/// ユーザー名の簡易確認にはHTTP通信を使い、登録操作にはモック結果を返す実装。
final class GitHubDefaultAPI: GitHubAPI {
    static let shared = GitHubDefaultAPI(session: .shared)
    private let session: URLSession
    private let scheduler: SchedulerType
    private let signUpResult: () -> Result<Bool, Error>

    /// 登録は教材用モックです。成否と時刻を注入でき、既定では1秒後に成功します。
    init(session: URLSession, scheduler: SchedulerType = MainScheduler.instance, signUpResult: @escaping () -> Result<Bool, Error> = { .success(true) }) {
        self.session = session
        self.scheduler = scheduler
        self.signUpResult = signUpResult
    }

    func isUsernameAvailable(_ username: String) -> Observable<Bool> {
        guard !username.isEmpty, username.rangeOfCharacter(from: CharacterSet.alphanumerics.inverted) == nil,
              let baseURL = URL(string: "https://github.com") else {
            return .error(URLError(.badURL))
        }
        let request = URLRequest(url: baseURL.appendingPathComponent(username))
        return session.rx.response(request: request).map { pair in
            switch pair.response.statusCode {
            case 404: return true
            case 200: return false
            default: throw URLError(.badServerResponse)
            }
        }
    }

    func signUp(_ username: String, password: String) -> Observable<Bool> {
        let result = signUpResult
        return Observable.deferred { try .just(result().get()) }
            .delay(.seconds(1), scheduler: scheduler)
    }
}
