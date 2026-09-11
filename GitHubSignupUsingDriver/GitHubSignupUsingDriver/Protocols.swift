//
//  Protocols.swift
//  GitHubSignupUsingDriver
//
//  Created by 藤門莉生 on 2023/02/14.
//

import RxSwift
import RxCocoa

enum ValidationResult {
    case ok(message: String)
    case empty
    case validating
    case failed(message: String)
}

protocol GitHubAPI {
    func isUsernameAvailable(_ username: String) -> Observable<Bool>
    func signUp(_ username: String, password: String) -> Observable<Bool>
}

protocol GitHubValidationService {
    func validateUsername(_ username: String) -> Observable<ValidationResult>
    func validatePassword(_ password: String) -> ValidationResult
    func validateRepeatedPassword(_ password: String, repeatedPassword: String) -> ValidationResult
}

extension ValidationResult {
    var isValid: Bool {
        switch self {
        case .ok:
            return true
        default:
            return false
        }
    }
}

/// Application boundary for the sample's mock registration operation.
final class SignUpUseCase {
    private let repository: GitHubAPI

    init(repository: GitHubAPI) {
        self.repository = repository
    }

    func execute(username: String, password: String) -> Observable<Bool> {
        repository.signUp(username, password: password)
    }
}
