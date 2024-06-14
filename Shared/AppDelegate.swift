//
//  AppDelegate.swift
//  identifier-ios
//
//  Created by Pete Li on 9/3/2022.
//

import UIKit
import Amplify
import PLKit

class AppDelegate: NSObject, UIApplicationDelegate {
    private var firebaseProjectId: String? {
        PKUtils.googleServiceInfo()["PROJECT_ID"] as? String
    }
    var tosURL: URL? { URL(string: "https://\(firebaseProjectId ?? "").firebaseapp.com") }
    var privacyURL: URL? { URL(string: "https://\(firebaseProjectId ?? "").firebaseapp.com") }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        pk.delegate = self

        _ = backend

        authVM.application(application, didFinishLaunchingWithOptions: launchOptions)

        return true
    }

    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        authVM.application(app, open: url, options: options)
    }
}

extension AppDelegate: PLKitDelegate {
    func amplifyModels() -> AmplifyModelRegistration {
        AmplifyModels()
    }
}
