//
//  AddPlantInteractor.swift
//  identifier-ios (iOS)
//
//  Created by Pete Li on 16/1/2022.
//

import UIKit
import Vision
import PLKit

public class AddPlantInteractor {
    func addLabel(fromName name: String) async throws -> Plant {
        let amPlant = AMPlant(userIds: [authVM.userId!], labelInfo: AMLabelInfo(name: name))
        try await amPlant.create()
        return Plant(data: amPlant)
    }

    func addLabel(fromImage image: UIImage) async throws -> Plant {
        let formattedImage = formatImage(image)

        // 1. parse image
        let amPlant = try await makeAMPlant(fromImage: formattedImage)

        // 2. upload image
        let s3Key = amPlant.labelInfo.originImage!.s3key!
        try await backend.upload(key: s3Key, uiImage: formattedImage)

        // 3. save to DB
        try await amPlant.create()

        return Plant(data: amPlant)
    }

    private func formatImage(_ image: UIImage) -> UIImage {
        PlatformImageSize.scaling(image, to: .large)
    }

    private func makeAMPlant(fromImage image: UIImage) async throws -> AMPlant {
        try await withCheckedThrowingContinuation { continuation in
            guard let cgImage = image.cgImage else {
                continuation.resume(throwing: PKError.general)
                return
            }

            VisionWrapper().request(cgImage) { result in
                switch result {
                case let .success(recognizedResult):
                    var labelInfo = self.parse(recognizedResult: recognizedResult)

                    let s3Key = "\(K.S3Key.uploadBucket)/\(Date().timeIntervalSince1970.int)"
                    let originImage = AMAsset(s3key: s3Key, size: image.size)
                    labelInfo.originImage = originImage

                    let diary = AMDiary(date: .now(), content: "", assets: [originImage])
                    continuation.resume(returning: AMPlant(userIds: [authVM.userId!],
                                                           labelInfo: labelInfo,
                                                           coverImage: labelInfo.originImage,
                                                           diaries: [diary]))

                case let .failure(error):
                    continuation.resume(throwing: error)
                }
            }
        }

    }

    func parse(recognizedResult: [VNRecognizedTextObservation]) -> AMLabelInfo {
        print(">>>Start: makeLabel: \(recognizedResult.map(\.topString))")
        var recognizedResult = recognizedResult
        let name = findName(recognizedResult)
        let positions = dropKeyWords(LabelInfo.Position.self, in: &recognizedResult, if: { $0.topString!.count < 20 })
        let containers = dropKeyWords(LabelInfo.Container.self, in: &recognizedResult, if: { $0.topString!.count < 20 })

        var infoNumbers: [LabelInfo.InfoNumber: String] = [:]
        LabelInfo.InfoNumber.allCases.forEach { infoNumberToTry in
            if let foundInfoNumber = dropInfoNumber(infoNumberToTry, &recognizedResult) {
                infoNumbers[infoNumberToTry] = foundInfoNumber
            }
        }

        // paragraphs should be last
        let paragraphs = findParagraphs(recognizedResult)

        let ret = AMLabelInfo(
            originImage: nil,
            name: name!.name,
            positions: positions.map(\.data),
            containers: containers.map(\.data),
            paragraphs: paragraphs,
            infoNumbers: infoNumbers.map { AMInfoNumberObject(infoNumber: $0.key.data, value: $0.value) }
        )

        print("<<<End: makeLabel: \(anyToString(ret))")
        return ret
    }
}

extension AddPlantInteractor {
    private func findParagraphs(_ recognizedText: [VNRecognizedTextObservation]) -> [String] {
        var recognizedText = recognizedText

        var paragraphs: [(Int, String)] = []
        while case let .success(para) = dropParagraph(&recognizedText) {
            paragraphs.append(para)
        }

        let ret = paragraphs
            .sorted { $0.0 < $1.0 }
            .map { $0.1 }

        return ret
    }

    /**
     * Steps:
     * 1. Find the 1st sentence and 2nd sentence
     * 2. Join 1st...2nd senntences
     * 3. Remove invalid characters: '*', '\', ';' etc.
     *
     * #1:
     * For the 1st sentence:
     * 1.1.1 Start with capital case, but not all upperCased
     * 1.1.2 index should before the 2nd sentence
     * 1.1.3 left/right end should be near 2nd sentence
     * If more than 1 candidate:
     * 1.1.4 Looks like a sentence: Longer than X, contains ' ' or '.'
     * 1.1.5 the longest
     *
     * For the 2nd sentence:
     * 1.2.1 End with "."
     * 1.2.2 No text on the right
     * If more than 1 candidate:
     * 1.2.3 Looks like a sentence(see^)
     * 1.2.4 Has the most space on the right (means most less on the left)
     *
     * #2:
     * 2.1 validate: if found 1 candidate
     * 2.2 validate if height is similar and Y is continious(line spacing)
     * 2.3 join
     *
     * #3:
     * Remove invalidCharsInSentence
     */
    private func dropParagraph(_ recognizedText: inout [VNRecognizedTextObservation]) -> Result<(idxOf1stSentence: Int, paragraph: String), PKError> {
        print(">>>>Start: dropParagraph")

        let lengthOfSentenceShould = 5  // a word
        let invalidCharsInSentence = ["\\", ";", "*"]

        // #1.2
        // #1.2.1
        var candidates2nd = recognizedText.filter { isPeriodEnd($0) }
        // #1.2.2
        candidates2nd = candidates2nd.filter { candidate in
            let rcFormatted = CGRect(origin: CGPoint(x: candidate.boundingBox.midX, y: candidate.boundingBox.midY),
                                    size: CGSize(width: 1, height: 0.001))

            // intersect boundingBox && greater index
            let idxCandidate = recognizedText.firstIndex(of: candidate)!
            let textsOnTheRight = recognizedText.enumerated()
                .filter { idx, txt in
                    txt.boundingBox.intersects(rcFormatted) && idxCandidate < idx
                }

            return textsOnTheRight.isEmpty
        }

        // #1.2.3
        candidates2nd = candidates2nd.filterIf(\.isNotEmpty) { $0.topString!.count >= lengthOfSentenceShould }
        candidates2nd = candidates2nd.filterIf(\.isNotEmpty) {
            $0.topString!.contains(" ") || isPeriodEnd($0)
        }

        // #1.2.4
        candidates2nd.sortIf(\.isNotEmpty) { $0.boundingBox.maxX < $1.boundingBox.maxX }

        // #1.2: end
        guard let sentence2nd = candidates2nd.first else { return .failure(.notFound) }
        var idxSentence2nd = recognizedText.firstIndex(of: sentence2nd)!
        print("####1.2: Found 2nd sentence: \(sentence2nd.topString!)")

        // #1.1
        var candidates1st = recognizedText.enumerated().filter {
            guard $0.element.topString.isNotEmpty else { return false }

            let el = $0.element

            // #1.1.1
            if el.topString!.first!.isLetter {
                guard isCapitalizedFirstButNotAll($0.element.topString) else { return false }
            }

            // #1.1.2
            guard $0.offset <= idxSentence2nd else { return false }

            // #1.1.3
            let leftSentence2nd = sentence2nd.boundingBox.minX
            let rightSentence2nd = sentence2nd.boundingBox.maxX
            guard abs(el.boundingBox.minX - leftSentence2nd) <= 0.2 ||
                    abs(el.boundingBox.maxX - rightSentence2nd) <= 0.2 else {
                        return false
                    }

            return true
        }
            .map { $0.element }

        // #1.1.4
        candidates1st = candidates1st.filterIf(\.isNotEmpty) { $0.topString!.count >= lengthOfSentenceShould }
        candidates1st = candidates1st.filterIf(\.isNotEmpty) { $0.topString!.contains(" ") }

        // #1.1.5
        candidates1st.sortIf(\.isNotEmpty) { $0.boundingBox.minX < $1.boundingBox.minX }

        // #1.1: end
        guard let sentence1st = candidates1st.first else { return .failure(.notFound) }
        var idxSentence1st = recognizedText.firstIndex(of: sentence1st)!
        print("####1.1: Found 1st sentence: \(sentence1st.topString!)")

        var idxToExclude: [Int] = []

        // #2
        print("####2: Start validate")
        let sameSentence = candidates1st.first(where: { candidate1st in
            candidates2nd.contains(where: { $0.topString == candidate1st.topString })
        })
        if sameSentence.isNotNil {  // #2.1
            idxSentence1st = recognizedText.firstIndex(of: sameSentence!)!
            idxSentence2nd = idxSentence1st

        } else {    // #2.2
            print("####2.2")

            let hSentence1st = sentence1st.boundingBox.height
            for idx in (idxSentence1st + 1)...idxSentence2nd {
                // iterate from idxSentence1st, each sentence should has similar height and continious Y(from bottom)
                let itSentence = recognizedText[idx]
                let isSimilarHeight = abs(itSentence.boundingBox.height - hSentence1st) <= 0.025

                let strideBack = stride(from: idx - 1, to: idxSentence1st, by: -1)

                var idxLastSentence = idx - 1
                for idxBack in strideBack {
                    if !idxToExclude.contains(idxBack) {
                        idxLastSentence = idxBack
                        break
                    }
                }
                let lastSentence = recognizedText[idxLastSentence]// ?? itSentence

                let lineSapcing = 0.02
                let isContiniousYVer = abs(itSentence.boundingBox.maxY - lastSentence.boundingBox.minY) < lineSapcing
                let isContiniousYHor = abs(itSentence.boundingBox.minY - lastSentence.boundingBox.minY) < lineSapcing || abs(itSentence.boundingBox.maxY - lastSentence.boundingBox.maxY) < lineSapcing
                let isContiniousY = isContiniousYHor || isContiniousYVer

                if !isHorizontalBlock(itSentence) { // skip if not horizontal, like vertical code
                    idxToExclude.append(idx)
                    continue

                } else if !isSimilarHeight || !isContiniousY {
                    // find the last sentence that contains '.' if the new 2nd sentence doesn't
                    var newIdxSentence2nd = idx - 1

                    for idxBack in strideBack {
                        if isPeriodEnd(recognizedText[idxBack]) {
                            newIdxSentence2nd = idxBack
                            break   // when newIdxSentence2nd contains '.'
                        }
                    }

                    idxSentence2nd = newIdxSentence2nd
                    break   // when reach a line that has different height or not continious Y
                }
            }
        }

        var candidateRet: [VNRecognizedTextObservation] = []
        for idx in idxSentence1st...idxSentence2nd {
            if !idxToExclude.contains(idx) {
                candidateRet.append(recognizedText[idx])
            }
        }

        // drop
        candidateRet.forEach {
            recognizedText.remove(at: recognizedText.firstIndex(of: $0)!)
        }

        var ret = candidateRet.map { $0.topString! }
            .joined(separator: " ")   // #2.3

        // #3
        invalidCharsInSentence.forEach {
            ret = ret.replacingOccurrences(of: $0, with: "", options: .literal, range: nil)
        }

        print("<<<<End: dropParagraph: \(ret)")
        return .success((idxSentence1st, ret))
    }

    /// Must:
    /// 1. near keywords: "height"
    /// 2. Contains number
    /// 3. Contains unit: UnitLength.centimeters, .meters, .inches, .feet
    /// Maybe:
    /// Contains '-'
    private func locateInfoNumber(_ infoNum: LabelInfo.InfoNumber, _ recognizedText: [VNRecognizedTextObservation]) -> VNRecognizedTextObservation? {
        guard let idxHeight = recognizedText
                .map({ $0.topString!.lowercased() })
                .firstIndexContainsOneOf(infoNum.keywords) else {
                    return nil
                }
        // #1
        let obHeight = recognizedText[idxHeight]
        let rcHeight = obHeight.boundingBox

        // #1: find the text on the left/bottom side of "height"
        // VNRecognizedTextObservation.boundingBox.origin is at the lower-left corner
        // While CGRect is at the top-left corner
        // means need to extend "top" instead of "bottom"
        let rcHeightExtended = rcHeight.inset(by: UIEdgeInsets(top: -0.02, left: 0, bottom: 0, right: 0.02))
        var candidates = recognizedText
            .filter { $0.boundingBox.intersects(rcHeightExtended) }
            .filter(\.topString.isNotEmpty)

        // #2
        candidates = candidates.filter { $0.topString!.rangeOfCharacter(from: .decimalDigits) != nil }

        // #3
        let separater = CharacterSet.whitespaces.union(.decimalDigits)
        candidates = candidates
            .filter {
                $0.topString!
                    .components(separatedBy: separater)
                    .map { $0.lowercased() }
                    .equalsOneOf(infoNum.units)
            }

        // There's a observation contains both keyword and number
        if let idx = candidates.firstIndex(of: obHeight) {
            return candidates[idx]
        }

        candidates = candidates.filterIf(\.hasMultiElements) { $0.topString!.contains("-") }

        return candidates.first
    }

    private func dropInfoNumber(_ infoNum: LabelInfo.InfoNumber, _ recognizedText: inout [VNRecognizedTextObservation]) -> String? {
        dropTopString(locateInfoNumber(infoNum, recognizedText), in: &recognizedText)
    }

    private func locateKeyWords<T: RecognizableByKeyword>(_ keyWordType: T.Type, in recognizedText: [VNRecognizedTextObservation]) -> [VNRecognizedTextObservation] {
        /**
         * Commented Steps:
         * 1. Contains keywords
         * 2. If more than one: Starts with locateHint
         * 3. If more than one: short length
         */
//        let r1 = recognizedText.filter(\.topString.isNotEmpty)
//        let r2 = r1.filter { T.allKeywords.contains(where: $0.topString!.lowercased().contains) }
//
//        let r3 = r2.filterIf(\.hasMultiElements) { $0.topString!.hasPrefix(T.locateHint) }
//        let r4 = r3.filterIf(\.hasMultiElements) { $0.topString!.count < 20 }

        let r1 = recognizedText.filter(\.topString.isNotEmpty)
        let r2 = r1.filter { T.allKeywords.contains(where: $0.topString!.lowercased().contains) }
        return r2
    }

    private func dropKeyWords<T: RecognizableByKeyword>(_ keyWordType: T.Type, in recognizedText: inout [VNRecognizedTextObservation], if shouldDrop: (VNRecognizedTextObservation) -> Bool = { _ in true }) -> Set<T> {
        let positions = locateKeyWords(keyWordType, in: recognizedText)

        positions.forEach { toRemove in
            if shouldDrop(toRemove) {
                let idx = recognizedText.firstIndex(of: toRemove)!
                recognizedText.remove(at: idx)
            }
        }

        return Set(positions.compactMap { T(textWithKeyword: $0.topString!) })
    }

    /**
     * 1. Check if it's in the Preset Dictionary
     * 2. Find name if not
     * 2.1 Locate upper
     * 2.2 Capitalized first letter
     * 2.3 Compare if allUpperCased and the height(implying the biggest font)
     */
    private func locateName(_ recognizedTexts: [VNRecognizedTextObservation]) -> VNRecognizedTextObservation? {
        // #1
        let presetNames = LabelInfo.LabelName.allKeywords
        let foundPresetName = recognizedTexts
            .filter(\.topString.isNotEmpty)
            .first(where: { recognizedText in
                presetNames.contains(where: recognizedText.topString!.lowercased().contains)
            })

        if foundPresetName.isNotNil {
            return foundPresetName
        }

        // #2
        let r1 = recognizedTexts.filter({ $0.bottomLeft.y > 0.5 })    // #2.1
        let r2 = r1.filter({ isCapitalizedFirst($0.topString) })  // #2.2
        let r3 = r2.sorted(by: {     // #2.3
            let isAllUpperCased0 = $0.topString!.replacingOccurrences(of: " ", with: "").allSatisfy(\.isUppercase)
            let isAllUpperCased1 = $1.topString!.replacingOccurrences(of: " ", with: "").trimmingCharacters(in: .whitespaces).allSatisfy(\.isUppercase)
            if isAllUpperCased0 && !isAllUpperCased1 {
                return true
            } else if !isAllUpperCased0 && isAllUpperCased1 {
                return false
            } else {
                return $0.boundingBox.height > $1.boundingBox.height
            }

        })
        let r4 = r3.first
        return r4
    }

    private func findName(_ recognizedTexts: [VNRecognizedTextObservation]) -> LabelInfo.LabelName? {
        guard let txt = locateName(recognizedTexts)?.topString else {
            return nil
        }

        return LabelInfo.LabelName(textWithKeyword: txt)
    }
}

// MARK: locate helpers
extension AddPlantInteractor {
    private func isCapitalizedFirst(_ s: String?) -> Bool {
        s?.first?.isUppercase ?? false
    }

    private func isCapitalizedFirstButNotAll(_ s: String?) -> Bool {
        guard s.isNotEmpty else { return false }

        let isAllUpperCased = s!.filter(\.isLetter).allSatisfy(\.isUppercase)

        return isCapitalizedFirst(s) && !isAllUpperCased
    }

    private func isPeriodEnd(_ observation: VNRecognizedTextObservation) -> Bool {
        observation.topString?.last == "."
    }

    private func isHorizontalBlock(_ observation: VNRecognizedTextObservation) -> Bool {
        observation.boundingBox.width > observation.boundingBox.height
    }
}

// MARK: utils
extension AddPlantInteractor {
    private func dropTopString(_ toDrop: VNRecognizedTextObservation?, in recognizedText: inout [VNRecognizedTextObservation]) -> String? {
        guard let toDrop = toDrop,
              let idxRemove = recognizedText.firstIndex(of: toDrop) else { return nil }

        recognizedText.remove(at: idxRemove)

        return toDrop.topString
    }

    @discardableResult
    private func printTexts(_ observations: [VNRecognizedTextObservation]) -> [String] {
        let ret = observations.map { $0.topString! }
        print(ret)
        return ret
    }
}
