//
//  DefaultImplementations.swift
//  GitHubSignupUsingDriver
//
//  Created by 藤門莉生 on 2023/03/06.
//

import RxSwift
import Foundation

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

        // this obviously won't be
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

final class GitHubDefaultAPI: GitHubAPI {
    private let session: Foundation.URLSession

    static let shared = GitHubDefaultAPI(
        session: Foundation.URLSession.shared
    )

    init(session: Foundation.URLSession) {
        self.session = session
    }

    func isUsernameAvailable(_ username: String) -> Observable<Bool> {
        // this is ofc just mock, but good enough

        let url = URL(string: "https://github.com/\(username.urlPathEncoded)")!
        let request = URLRequest(url: url)
        return session.rx.response(request: request)
            .map { pair in
                return pair.response.statusCode == 404
            }
            .catchAndReturn(false)
    }

    func signUp(_ username: String, password: String) -> Observable<Bool> {
        // this is also just a mock
        let signupResult = arc4random() % 5 == 0 ? false : true

        return Observable.just(signupResult)
            .delay(.seconds(1), scheduler: MainScheduler.instance)
    }


}
