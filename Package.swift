// swift-tools-version: 5.9
import PackageDescription
let package = Package(name: "SignUpCore", platforms: [.macOS(.v12)], dependencies: [
    .package(url: "https://github.com/ReactiveX/RxSwift.git", exact: "6.7.1")
], targets: [
    .target(name: "SignUpCore", dependencies: [.product(name: "RxSwift", package: "RxSwift"), .product(name: "RxCocoa", package: "RxSwift")], path: "GitHubSignupUsingDriver/GitHubSignupUsingDriver", exclude: ["Service/String+URL.swift","GitHubSignUpViewController.swift","Assets.xcassets","Base.lproj","AppDelegate.swift","BindingExtensions.swift","Info.plist","SceneDelegate.swift"], sources: ["Protocols.swift","DefaultImplementations.swift","GitHubSignUpViewModel.swift","Service/ActivityIndicator.swift","Service/Wireframe.swift"]),
    .testTarget(name: "SignUpCoreTests", dependencies: ["SignUpCore"], path: "GitHubSignupUsingDriver/GitHubSignupUsingDriverTests")
])
