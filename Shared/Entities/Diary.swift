//
//  Diary.swift
//  identifier-ios (iOS)
//
//  Created by Pete Li on 4/4/2022.
//

import Foundation
import Combine
import PLKit

class Diary: ObservableObject, Identifiable {
    var id: String {
        data.date.iso8601String
    }

    let data: AMDiary

    @Published var assets: [Asset] = []
    var amAssets: [AMAsset] {
        data.assets ?? []
    }

    init(data: AMDiary) {
        self.data = data

        Task {
            await prepare()
        }
    }

    private lazy var dateFormatter: DateFormatter = {
        let fmt = DateFormatter()
        fmt.dateFormat = DateFormatter.dateFormat(fromTemplate: "dMMM", options: 0, locale: .current)
        return fmt
    }()

    var displayDate: String {
        dateFormatter.string(from: data.date.foundationDate)
    }

    var displayContent: String {
        data.content
    }

    private func prepare() async {
        if let assets = data.assets {
            for image in assets {
                try? await image.downloadAndCache()
            }

            onMain {
                self.assets = assets.compactMap { $0.cached() }
            }
        }
    }
}
