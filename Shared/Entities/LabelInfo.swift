//
//  PlantLabel.swift
//  identifier-ios (iOS)
//
//  Created by Pete Li on 16/1/2022.
//

import PLKit
import UIKit

public class LabelInfo: ObservableObject {
    private(set) var data: AMLabelInfo

    init(data: AMLabelInfo) {
        self.data = data
    }

    var name: LabelName {
        LabelName(textWithKeyword: data.name)!
    }

    var hasUploadedLabel: Bool {
        data.originImage.isNotNil
    }

    var positions: [Position] {
        data.positions?.map { Position(data: $0) } ?? []
    }

    static let displayParagraphSeparator = "\n\n"
    var displayParagraph: String {
        data.paragraphs?.joined(separator: Self.displayParagraphSeparator) ?? ""
    }

    var containers: [Container] {
        data.containers?.map { Container(data: $0) } ?? []
    }

    var infoNumbers: [InfoNumber: String] {
        data.infoNumbers?.reduce(into: [:]) {
            $0[InfoNumber(data: $1.infoNumber)] = $1.value
        } ?? [:]
    }
}

extension LabelInfo {
    enum LabelName: RecognizableByKeyword, Equatable {
        case custom(name: String), preset(name: PresetPlantName)

        var display: String {
            switch self {
            case .custom(let name): return name
            case .preset(let name): return PKUtils.convertToTitleCase(canmelCase: name.rawValue)
            }
        }

        static var allKeywords: [String] {
            PresetPlantName.allKeywords
        }

        var keywords: [String] {
            switch self {
            case .custom(let name): return [name]
            case .preset(let name): return name.keywords
            }
        }

        init?(textWithKeyword: String) {
            if let presetName = PresetPlantName(textWithKeyword: textWithKeyword) {
                self = .preset(name: presetName)
            } else {
                self = .custom(name: textWithKeyword)
            }
        }

        var name: String {
            switch self {
            case .custom(let name): return name
            case .preset(let name): return name.rawValue
            }
        }
    }

    // name should not included in ''
    enum PresetPlantName: String, CaseIterable, RecognizableByKeyword {
        case petuniaNightSky, pomegranate, pelargonium, dracaenaFragrans

        var keywords: [String] {
            var ret = [PKUtils.convertToTitleCase(canmelCase: rawValue).lowercased()]

            switch self {
            case .pomegranate:
                ret.append("punica granatum")
            default: break
            }

            return ret
        }
    }
}

extension LabelInfo {
    enum InfoNumber: String, CaseIterable, Identifiable {
        case width, height
        case flowering
        case harvest

        var keywords: [String] {
            switch self {
            case .width: return ["width"]
            case .height: return ["height"]
            case .flowering: return ["flowering"]
            case .harvest: return ["harvest"]
            }
        }

        var units: [String] {
            switch self {
            case .width, .height:
                let units: [UnitLength] = [.centimeters, .meters, .inches, .feet]
                return units.map { $0.symbol }
            case .flowering, .harvest: return ["weeks"]
            }
        }

        var display: String {
            PKUtils.convertToTitleCase(canmelCase: rawValue).capitalizedFirst
        }

        var icon: UIImage {
            return UIImage(systemName: "questionmark.circle")!
        }

        var id: String { keywords.first! }

        init(data: AmInfoNumber) {
            self = InfoNumber(rawValue: data.rawValue)!
        }

        var data: AmInfoNumber { AmInfoNumber(rawValue: rawValue)! }
    }
}

extension LabelInfo {
    // alias
    enum Position: String, CaseIterable, RecognizableByKeyword {
        case fullSun, partShade, shade

        var keywords: [String] {
            switch self {
            case .fullSun: return ["full sun", "full", "sunny position"]
            case .partShade: return ["part shade"]
            case .shade: return ["shade"]
            }
        }

        static var locateHint: String { "position:" }

        var display: String {
            PKUtils.convertToTitleCase(canmelCase: rawValue).capitalizedFirst
        }

        var icon: UIImage {
            switch self {
            case .fullSun: return UIImage(systemName: "sun.max")!
            case .partShade: return UIImage(systemName: "sun.min")!
            case .shade: return UIImage(systemName: "cloud.sun")!
            }
        }

        init(data: AmPosition) {
            self = Position(rawValue: data.rawValue)!
        }

        var data: AmPosition { AmPosition(rawValue: rawValue)! }
    }
}

extension LabelInfo {
    enum Container: String, CaseIterable, RecognizableByKeyword {
        case gardenBed, pot // border

        var keywords: [String] {
            switch self {
            case .gardenBed: return ["garden bed", "bed"]
            case .pot: return ["pot"]   // container
            }
        }

        var display: String {
            PKUtils.convertToTitleCase(canmelCase: rawValue).capitalizedFirst
        }

        var icon: UIImage {
            switch self {
            case .gardenBed: return UIImage(systemName: "questionmark.circle")!
            case .pot: return UIImage(systemName: "questionmark.circle")!
            }
        }

        init(data: AmContainer) {
            self = Container(rawValue: data.rawValue)!
        }

        var data: AmContainer { AmContainer(rawValue: rawValue)! }
    }
}
