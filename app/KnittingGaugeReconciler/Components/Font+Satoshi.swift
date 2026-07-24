import CoreText
import SwiftUI
import UIKit

enum SatoshiVariableFont {
    enum Weight: Int {
        case regular = 400
        case semibold = 600
        case bold = 700

        var uiFontWeight: UIFont.Weight {
            switch self {
            case .regular: .regular
            case .semibold: .semibold
            case .bold: .bold
            }
        }
    }

    static let familyName = "Satoshi Variable"
    static let regularPostScriptName = "SatoshiVariable-Bold_Regular"
    static let italicPostScriptName = "SatoshiVariable-BoldItalic_Italic"
    static let weightAxisIdentifier = 0x7767_6874

    static func scaledFont(
        size: CGFloat,
        textStyle: UIFont.TextStyle,
        weight: Weight,
        fontName: String = regularPostScriptName
    ) -> UIFont {
        let metrics = UIFontMetrics(forTextStyle: textStyle)
        let uiFontWeight = weight.uiFontWeight
        guard let font = UIFont(name: fontName, size: size) else {
            return metrics.scaledFont(
                for: .systemFont(ofSize: size, weight: uiFontWeight)
            )
        }

        let descriptor = font.fontDescriptor.addingAttributes([
            UIFontDescriptor.AttributeName(rawValue: kCTFontVariationAttribute as String): [
                weightAxisIdentifier: weight.rawValue,
            ],
        ])
        return metrics.scaledFont(for: UIFont(descriptor: descriptor, size: size))
    }
}

extension Font {
    static let satoshiLargeTitle = satoshi(size: 34, relativeTo: .largeTitle, weight: .bold)
    static let satoshiTitle = satoshi(size: 28, relativeTo: .title, weight: .bold)
    static let satoshiTitle2 = satoshi(size: 22, relativeTo: .title2, weight: .bold)
    static let satoshiTitle3 = satoshi(size: 20, relativeTo: .title3, weight: .semibold)
    static let satoshiHeadline = satoshi(size: 17, relativeTo: .headline, weight: .semibold)
    static let satoshiBody = satoshi(size: 17, relativeTo: .body)
    static let satoshiCallout = satoshi(size: 16, relativeTo: .callout)
    static let satoshiSubheadline = satoshi(size: 15, relativeTo: .subheadline)
    static let satoshiFootnote = satoshi(size: 13, relativeTo: .footnote)
    static let satoshiCaption = satoshi(size: 12, relativeTo: .caption)
    static let satoshiCaption2 = satoshi(size: 11, relativeTo: .caption2)

    private static func satoshi(
        size: CGFloat,
        relativeTo textStyle: Font.TextStyle,
        weight: Font.Weight = .regular
    ) -> Font {
        .custom(SatoshiVariableFont.familyName, size: size, relativeTo: textStyle)
            .weight(weight)
    }
}
