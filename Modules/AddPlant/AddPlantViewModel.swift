//
//  AddPlantViewModel.swift
//  identifier-ios (iOS)
//
//  Created by Pete Li on 16/2/2022.
//

import Foundation
import UIKit
import PLKit

class AddPlantViewModel: ObservableObject {
    weak var delegate: AddModuleDelegate?

    private let interactor = AddPlantInteractor()

    func addLabel(fromImage image: UIImage) async {
        do {
            let newPlant = try await interactor.addLabel(fromImage: image)
            self.delegate?.addModuleDidCreatePlant(newPlant)
        } catch {
            E(error.localizedDescription)
        }
    }

    @discardableResult
    func addLabel(fromName name: String) async -> Plant? {
        do {
            let newPlant = try await interactor.addLabel(fromName: name)
            self.delegate?.addModuleDidCreatePlant(newPlant)

            return newPlant
        } catch {
            E(error.localizedDescription)
            return nil
        }
    }
}

class FakeBackend {
    // Testing: diary ui
//    let diaries: [Diary] = [Diary(data: AMDiary(date: .now(), content: "1")),
//                            Diary(data: AMDiary(date: .now(), content: "2")),
//                            Diary(data: AMDiary(date: .now(), content: "3")),
//                            Diary(data: AMDiary(date: .now(), content: "4")),
//                            Diary(data: AMDiary(date: .now(), content: "5")),
//                            Diary(data: AMDiary(date: .now(), content: "6"))]
    
    static var plants: [Plant] {
        samples
            .sorted(by: { $0.key < $1.key })
            .map({
                let originalImage = UIImage(named: $0.key) ?? UIImage(named: "monstera")!
                let diary = AMDiary(date: .now(), title: "today is a nice day", content: "1st time watering", tags: [AMTag(title: "tag tag")])
                let data = AMPlant(userIds: [""], labelInfo: $0.value, diaries: [diary])
                return Plant(data: data, assets: [
                    Asset(data: AMAsset(s3key: "", size: originalImage.size), downloadedData: originalImage.jpegData(compressionQuality: 0.1)!)
                ])
            })
    }

    static let samples = [
        "sample1": AMLabelInfo(originImage: nil, name: "CINERARIA SILVERDUST",
                               positions: [.fullSun, .partShade],
                               containers: [.gardenBed, .pot],
                               paragraphs: ["Senecio maritima.", "The striking leaves of finely cut, silvery white, velvety foliage are superb for adding contrast and texture. Sometimes known as \'Dusty Miller, yellow daisy. like flowers are produced in summer. Pohlmans CINERARIA SILVERDUST iS ideal for-beds, borders, containers and cottage gardens. Once established will be drought tolerant and low maintenance.", "GROWING: Easy to grow, preferring a well drained soil or standard approved potting mix. Through the warmer months mulch around the plants root base to reduce water stress."],
                               infoNumbers: [.info(.height, "25-30CM"),
                                             .info(.flowering, "10-14 WEEKS")]),
        "sample2": AMLabelInfo(originImage: nil, name: "BEGONIA GREEN LEAVED WHITE",
                               positions: [.partShade, .shade],
                               containers: [.gardenBed],
                               paragraphs: ["This green foliage begonia grows. well in heavily shaded areas. An old garden favourite with charming white flowers. Pohlmans BEGONIA GREEN LEAVED.", "WHITE is ideal for bedding, borders, rockeries and containers.", "GROWING: These plants will thrive in a heavily shaded position or a sunnier position provided they are watered regularly in dry weather. Through the wariler months mulch around the plants root base to reduce water stress. Removing spent flowers will prolong bloom period and encourage more flowers.", "Information and picture are a guide only."],
                               infoNumbers: [.info(.height, "15-25CM"),
                                             .info(.flowering, "10-12 WEEKS")]),

        // wrong paragraphs
        "sample3": AMLabelInfo(originImage: nil, name: LabelInfo.PresetPlantName.petuniaNightSky.rawValue,
                               positions: [.fullSun],
                               containers: [.gardenBed, .pot],
                               paragraphs: ["Petunia Night Sky boldly goes where no light years from the usual! This petunia has gone before might be the most distinctive, bloom you\'ve ever seen on this planet with the groundbreaking new colour pattern on a mounded trailing habit. Loves full sun and will bloom from spring through to late summer. Note: Night Sky will flower through the seasons with a varying colour pattern."],
                               infoNumbers: [.info(.width, "45-60CM"),
                                             .info(.height, "25-40CM")]),

        // Wrong paragraph: Paragraph Title inside, "GROWING TIP"
        // Height not quite correct
        "sample4": AMLabelInfo(originImage: nil, name: "CHA CHA",
                               positions: [.fullSun],
                               containers: [.gardenBed, .pot],
                               paragraphs: ["CLOz. \'Pr ) Aid dd a ImproJ/oH SIstOo epin6 pnyday e se Ajuo popuaqui uope. singi put vonewsojul 81/LL L00 LOVE", "Plant in well -drained soil. Use a control release, general purpose GROWING TIPS fertiliser. If growing in containers use a quality potting mix. Do not allow pot to dry out fully. Prune as needed.", "The 5-6cm long, edible fruit of this highly attractive, compact plant turns from white tinged with purpie through to an orange colour when mature. Chilli Cha Cha is the perfect feature plant for garden beds, borders and pots. It is also suitable for short-term indoor display.", "Add mature fruit to Mediterranean USES or Asian-style dishes, or use as a colourful garnish. Wash hands after handling fruit.", "Picking fruit regularly may help to prolong the harvest period.", "Tolerates light frosts."],
                               infoNumbers: [.info(.height, "HEIGHT & SPACING 15cm, 20cm apart.")]),

        "sample5": AMLabelInfo(originImage: nil, name: "Chilli Birdseye",
                               positions: [.fullSun],
                               containers: [.pot],
                               paragraphs: ["Capsicum annuum Packing a real punch for a small chilli, the fruit goes from green to red as it matures. Use fresh or dried.", "Position: Thrives in sunny positions Soil: Well drained Watering: Water regularly Fertilising: Fertilise regularly", "Grow tips: Cultivate soil before planting. Dry out between watering to obtain hottest flavour.", "Caution: Skin/Eye irritant. Wash hands after handling."],
                               infoNumbers: [.info(.harvest, "Harvest: 12-14 weeks")]),

        // Wrong paragraph: Miss Planting guide, reconised wrong
        "sample6": AMLabelInfo(originImage: nil, name: "HERBAL",
                               positions: [.fullSun],
                               containers: [.pot, .gardenBed],
                               paragraphs: ["Rear L Rear R HERBAL 3", "Tea Pack Front L Front R Melissa officinalis, Mentha x piperita, Anthems arvensis, Salvia elegans", "The plants included in this pack are ideal for creating your own herbal tea combinations.", "1. Lemon Balm is i spreading perennial herb grown for its deliciously scented, lemon flavoured leaves.", "The leaves can be used to flavour desserts, fruit salads and herbal teas. garden planting and containers. Ideal for herb gardens, for general 2. Peppermint is a popular perennial herb with its delic purpit -tinged, scented leaves, and is a must for every herb garden. A tasty addition to desserts, fruit salads and herbal teas. Plant in a separate bed or large tub as it can be invasive.", "3. German Chamomile is a sweetly scented herb with decorative tufts of fresh green, highly divided, fern-like foliage. This sun loving annual bears a profusion of white, daisy flowers with bright yellow centres. Dried flowers are infused to make a soothing herbal tea, which can also be used as a hair rinse to lighten hair.", "4. Pineapple Sage is a deliciously fruit-scented, perennial herb with oval flavour to drinks and salads.", "This herb garden favourite produces tall spikes of scarlet blooms in autumn.", "Planting Guide", "Picture and information intended only as 1 guide."],
                               infoNumbers: []),

        "sample7": AMLabelInfo(originImage: nil, name: LabelInfo.PresetPlantName.pomegranate.rawValue,
                               positions: [.fullSun, .partShade],
                               containers: [.pot],
                               paragraphs: ["Punica granatum Pomegranate", "An easy to grow, deciduous, medium sized shrub with attractive, yellow, autumn tones before the leaves fall. Showy, large, double, red flowers appear in early summer followed by edible, red fruit.", "A hardy plant valued for its ornamental appeal and the edible fruit. Grow in containers or as a hedge.", "Requires a warm, sunny, sheltered TOLERANT situation with well drained soil. Little attention is required other than pruning to shape. Fertilise in spring.", "Picture and information intended as guide only."],
                               infoNumbers: [.info(.height, "TO 2M")]),

        "sample8": AMLabelInfo(originImage: nil, name: LabelInfo.PresetPlantName.pelargonium.rawValue,
                               positions: [.fullSun],
                               containers: [.gardenBed],
                               paragraphs: ["Pelargonium x hortorum GERANIUM Vogue Mix thrives in the sun and will give you that colorful Mediterranean look.", "Position: Full sun semi shade", "Growing tip: Water in the morning rather than evening & prune to maintain shape.", "Perfect for containers, borders and garden beds.", "& color may vary according to local conditions."],
                               infoNumbers: [.info(.height, "Height: 25cm approx"),
                                             .info(.flowering, "Flowering: 4-6 weeks")]),

        "sample9": AMLabelInfo(originImage: nil, name: "BASIL",
                               positions: [.fullSun],
                               containers: [.gardenBed, .pot],
                               paragraphs: ["A selection of three Basils including limelight, purple leaf and sweet. With equal performance in garden bed, pot and containers they are ideal for adding to a wide range of salads and cooked dishes.", "Picture and information intended only as a guide.", "Cultivate soil before planting. Dig hole twice the width of the container. Remove plant from the container and place in the hole so the soil level is the same as the surrounding ground. Fill hole firmly and water well, even if the soil is moist. Use premium potting mix if planting in containers."],
                               infoNumbers: []),

        "sample10": AMLabelInfo(originImage: nil, name: LabelInfo.PresetPlantName.dracaenaFragrans.rawValue,
                                positions: [],
                                containers: [],
                                paragraphs: ["Easy-to-grow foliage plant, suitable. for tropical garden planting or as superb houseplant in warm, humid position with filtered light. Keep moist during warm ather and drier during winter.", "Indoors, apply liquid fertiliser through the warmer months and wipe foliage keep dust free."],
                                infoNumbers: [])
    ]
}
