//
//  Wireframe.swift
//  GitHubSignupUsingDriver
//
//  Created by 藤門莉生 on 2023/02/14.
//

import RxSwift

#if os(iOS)
    import UIKit
#elseif os(macOS)
    import Cocoa
#endif

protocol Wireframe {
    func open(url: URL)
    func promptFor<Action: CustomStringConvertible>(_ messge: String, cancelAction: Action, actions: [Action]) -> Observable<Action>
}

class DefaultWireframe: Wireframe {
    static let shared = DefaultWireframe()
    
    func open(url: URL) {
        #if os(iOS)
        UIApplication.shared.open(url)
        #elseif os(macOS)
        NSWorkspace.shared.open(url: url)
        #endif
    }
    
    #if os(iOS)
    private static func rootViewController() -> UIViewController {
        // cheating, I know
        return UIApplication.shared.keyWindow!.rootViewController!
    }
    #endif
    
    func promptFor<Action>(_ messge: String, cancelAction: Action, actions: [Action]) -> RxSwift.Observable<Action> where Action : CustomStringConvertible {
        
        #if os(iOS)
        return Observable.create { observer in
            let alertView = UIAlertController(
                title: "RxExample",
                message: messge,
                preferredStyle: .alert
            )
            
            alertView.addAction(
                UIAlertAction(title: messge, style: .cancel) { _ in
                    observer.on(.next(cancelAction))
                }
            )
            
            for action in actions {
                alertView.addAction(
                    UIAlertAction(title: actions.description, style: .default) { _ in
                        observer.on(.next(action))
                    }
                )
            }
            
            DefaultWireframe.rootViewController().present(alertView, animated: true, completion: nil)
            
            return Disposables.create {
                alertView.dismiss(animated: true, completion: nil)
            }
        }
        
        #elseif os(macOS)
        return Observable.error(NSError(domain: "Unimplemented", code: nil))
        #endif
    }
    
    
}
