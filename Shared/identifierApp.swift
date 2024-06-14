//
//  identifier_iosApp.swift
//  Shared
//
//  Created by Pete Li on 10/1/2022.
//

import SwiftUI
import PLKit

@main
struct IdentifierApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    @ObservedObject var sharedUI = PKUI()

    private let appDependencies: AppDependencies = AppDependencies()

    var body: some Scene {
        WindowGroup {
            appDependencies.rootView()
                .environmentObject(sharedUI)
            // TidyTODO: Remove global alert, fullScreenCover in App since it will refresh the whole app
                .alert(item: $sharedUI.alert, content: PKAlertItem.makeAlert)
                .fullScreenCover(isPresented: Binding(get: { sharedUI.fullScreenCoverView.isNotNil },
                                                      set: {
                    if !$0 { sharedUI.fullScreenCoverView = nil }
                }), content: { sharedUI.fullScreenCoverView })
        }
    }
}
