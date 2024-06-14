//
//  SettingViewModel.swift
//  identifier-ios (iOS)
//
//  Created by Pete Li on 3/4/2022.
//

import Foundation

class SettingViewModel: ObservableObject {
    static let shared = SettingViewModel()
    private init() {}

    @Published var plantAddable = true
}
