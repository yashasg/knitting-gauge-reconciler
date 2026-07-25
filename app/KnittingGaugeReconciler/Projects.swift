// swiftlint:disable file_length
import Foundation
import Observation
import SwiftUI
import SwiftData
enum ProjectType: String, CaseIterable, Codable, Identifiable {
    case headwear, tops, bottoms, footwear, other
    var id: Self { self }
    var label: String { rawValue.capitalized }
    var description: String {
        switch self {
        case .headwear: "Beanies, toques, slouchy hats, and sun hats"
        case .tops: "Sweaters, pullovers, cardigans, ponchos, vests, and tanks"
        case .bottoms: "Skirts, pants, shorts, and leggings"
        case .footwear: "Crew socks, ankle socks, and knee-highs"
        case .other: "Blankets, shawls, bags, toys, and custom projects"
        }
    }

    var defaultSymbolName: String {
        switch self {
        case .headwear: "crown"
        case .tops: "tshirt.fill"
        case .bottoms: "figure.stand"
        case .footwear: "shoe"
        case .other: "square.grid.2x2"
        }
    }

    var constructions: [ProjectConstruction] {
        switch self {
        case .tops:
            [.circularYokeRaglan, .setInSleeve, .dropShoulder]
        case .bottoms:
            [.skirt, .pantsShortsLeggings]
        case .headwear, .footwear, .other:
            []
        }
    }
}

enum ProjectConstruction: String, CaseIterable, Codable, Identifiable {
    case circularYokeRaglan, setInSleeve, dropShoulder
    case skirt, pantsShortsLeggings
    var id: Self { self }
    var label: String {
        switch self {
        case .circularYokeRaglan: "Circular Yoke / Raglan"
        case .setInSleeve: "Set-in Sleeve"
        case .dropShoulder: "Drop Shoulder"
        case .skirt: "Skirt"
        case .pantsShortsLeggings: "Pants / Shorts / Leggings"
        }
    }

    var detail: String {
        switch self {
        case .circularYokeRaglan:
            "Evenly distributed shaping across the yoke or four raglan lines."
        case .setInSleeve:
            "Curved bind-off and decrease-rate shaping for the armhole."
        case .dropShoulder:
            "Straight construction with no armhole shaping."
        case .skirt:
            "Waist-to-hem length without a crotch or leg split."
        case .pantsShortsLeggings:
            "Rise and leg length with a crotch split."
        }
    }
}

enum ProjectCrownShape: String, CaseIterable, Codable, Identifiable {
    case round, faceted
    var id: Self { self }
    var label: String {
        switch self {
        case .round: "Round"
        case .faceted: "Pentagon / Hexagon"
        }
    }
}

enum ProjectMeasurementAxis: String, Codable {
    case horizontal
    case vertical

    var resultLabel: String {
        switch self {
        case .horizontal: "stitches"
        case .vertical: "rows"
        }
    }
}

enum ProjectMeasurementKind: String, Codable, Identifiable {
    private struct Metadata {
        let label: String
        let landmarks: String
        let axis: ProjectMeasurementAxis
    }

    case neckOpeningCircumference, chestCircumference, upperSleeveCircumference
    case cuffCircumference, crossBackWidth, upperArmCircumference
    case waistCircumference, hipCircumference, hemCircumference
    case thighCircumference, legOpeningCircumference
    case hatCircumference, footCircumference, sockCuffCircumference, customWidth
    case yokeRaglanDepth, armholeDepthSetIn, armholeDepthDrop
    case bodyLength, sleeveLength, sleeveCapDepth, shoulderToCuffLength
    case waistToHipDepth, rise, legLength, crownDepth
    case footLength, sockHeight, heelDepth, customDepth

    var id: Self { self }
    var label: String { metadata.label }
    var landmarks: String { metadata.landmarks }
    var axis: ProjectMeasurementAxis { metadata.axis }
    var valueRange: ClosedRange<Int> { 1...500 }

    private var metadata: Metadata {
        switch self {
        case .neckOpeningCircumference:
            Metadata(
                label: "Neck Opening",
                landmarks: "Finished opening circumference",
                axis: .horizontal
            )
        case .chestCircumference:
            Metadata(
                label: "Chest / Body",
                landmarks: "Finished circumference at the underarm",
                axis: .horizontal
            )
        case .upperSleeveCircumference:
            Metadata(
                label: "Upper Sleeve",
                landmarks: "Finished sleeve circumference at the underarm",
                axis: .horizontal
            )
        case .cuffCircumference:
            Metadata(
                label: "Cuff",
                landmarks: "Finished sleeve-opening circumference",
                axis: .horizontal
            )
        case .crossBackWidth:
            Metadata(
                label: "Cross-back Width",
                landmarks: "Armhole to armhole across the back",
                axis: .horizontal
            )
        case .upperArmCircumference:
            Metadata(
                label: "Upper Arm",
                landmarks: "Finished circumference at the widest upper arm",
                axis: .horizontal
            )
        case .waistCircumference:
            Metadata(
                label: "Waist",
                landmarks: "Finished circumference at the wearing waist",
                axis: .horizontal
            )
        case .hipCircumference:
            Metadata(
                label: "Hip / Seat",
                landmarks: "Finished circumference at the fullest hip",
                axis: .horizontal
            )
        case .hemCircumference:
            Metadata(
                label: "Hem",
                landmarks: "Finished lower-edge circumference",
                axis: .horizontal
            )
        case .thighCircumference:
            Metadata(
                label: "Upper Thigh",
                landmarks: "Finished circumference for one leg",
                axis: .horizontal
            )
        case .legOpeningCircumference:
            Metadata(
                label: "Leg Opening",
                landmarks: "Finished circumference for one leg opening",
                axis: .horizontal
            )
        case .hatCircumference:
            Metadata(
                label: "Hat Circumference",
                landmarks: "Finished unstretched circumference after blocking",
                axis: .horizontal
            )
        case .footCircumference:
            Metadata(
                label: "Foot Circumference",
                landmarks: "Finished circumference at the ball of the foot",
                axis: .horizontal
            )
        case .sockCuffCircumference:
            Metadata(
                label: "Cuff / Leg Circumference",
                landmarks: "Finished circumference at the sock opening",
                axis: .horizontal
            )
        case .customWidth:
            Metadata(
                label: "Width / Circumference",
                landmarks: "Your chosen horizontal dimension",
                axis: .horizontal
            )
        case .yokeRaglanDepth:
            Metadata(
                label: "Yoke / Raglan Depth",
                landmarks: "Neckline to underarm or body-sleeve split",
                axis: .vertical
            )
        case .armholeDepthSetIn, .armholeDepthDrop:
            Metadata(
                label: "Armhole Depth",
                landmarks: "Shoulder to underarm",
                axis: .vertical
            )
        case .bodyLength:
            Metadata(
                label: "Body Length",
                landmarks: "Underarm or waist to hem",
                axis: .vertical
            )
        case .sleeveLength:
            Metadata(
                label: "Sleeve Length",
                landmarks: "Underarm to cuff",
                axis: .vertical
            )
        case .sleeveCapDepth:
            Metadata(
                label: "Sleeve-cap Depth",
                landmarks: "Top of sleeve cap to underarm",
                axis: .vertical
            )
        case .shoulderToCuffLength:
            Metadata(
                label: "Shoulder to Cuff",
                landmarks: "Dropped shoulder seam to cuff",
                axis: .vertical
            )
        case .waistToHipDepth:
            Metadata(
                label: "Waist-to-hip Depth",
                landmarks: "Waist to the fullest hip",
                axis: .vertical
            )
        case .rise:
            Metadata(
                label: "Rise",
                landmarks: "Waist to crotch split",
                axis: .vertical
            )
        case .legLength:
            Metadata(
                label: "Leg Length",
                landmarks: "Crotch split to hem",
                axis: .vertical
            )
        case .crownDepth:
            Metadata(
                label: "Hat Depth",
                landmarks: "Lower edge to crown top",
                axis: .vertical
            )
        case .footLength:
            Metadata(
                label: "Foot Length",
                landmarks: "Heel to finished toe",
                axis: .vertical
            )
        case .sockHeight:
            Metadata(
                label: "Sock Height",
                landmarks: "Heel landmark to top of cuff",
                axis: .vertical
            )
        case .heelDepth:
            Metadata(
                label: "Heel Depth",
                landmarks: "Depth to and through the heel turn",
                axis: .vertical
            )
        case .customDepth:
            Metadata(
                label: "Length / Depth",
                landmarks: "Your chosen vertical dimension",
                axis: .vertical
            )
        }
    }
}

struct ProjectMeasurementValue: Codable, Equatable, Identifiable {
    var kind: ProjectMeasurementKind
    var centimeters: String
    var id: ProjectMeasurementKind { kind }
}

struct ProjectMeasurementResult: Equatable, Identifiable {
    let measurement: ProjectMeasurementValue
    let patternCount: Int
    let requiredCount: Int

    var id: ProjectMeasurementKind { measurement.kind }
    var resultLabel: String { measurement.kind.axis.resultLabel }
}

enum ProjectCountConstraint: String, CaseIterable, Codable, Identifiable {
    case wholeNumber
    case evenNumber
    case patternRepeat

    var id: Self { self }
    var label: String {
        switch self {
        case .wholeNumber: "Whole Number"
        case .evenNumber: "Even Number"
        case .patternRepeat: "Pattern Repeat"
        }
    }
    var pickerLabel: String {
        switch self {
        case .wholeNumber: "Whole"
        case .evenNumber: "Even"
        case .patternRepeat: "Repeat"
        }
    }
    var explanation: String {
        switch self {
        case .wholeNumber:
            "Rounds each result up to the next whole stitch or row."
        case .evenNumber:
            "Rounds each result up to the next even stitch or row."
        case .patternRepeat:
            "Rounds stitches and rows up to the next repeat multiple."
        }
    }
}

struct ProjectCountRules: Codable, Equatable {
    static let repeatRange = 1...999
    static let wholeNumber = ProjectCountRules(
        constraint: .wholeNumber,
        stitchRepeat: nil,
        rowRepeat: nil
    )

    var constraint: ProjectCountConstraint
    var stitchRepeat: Int?
    var rowRepeat: Int?

    var summary: String {
        switch constraint {
        case .wholeNumber:
            "Rounded up to whole numbers"
        case .evenNumber:
            "Rounded up to even numbers"
        case .patternRepeat:
            "Rounded up to \(stitchRepeat ?? 1)-stitch and \(rowRepeat ?? 1)-row repeats"
        }
    }

    func requiredCount(for rawCount: Double, axis: ProjectMeasurementAxis) -> Int {
        let multiple: Int
        switch constraint {
        case .wholeNumber:
            multiple = 1
        case .evenNumber:
            multiple = 2
        case .patternRepeat:
            multiple = axis == .horizontal ? stitchRepeat ?? 1 : rowRepeat ?? 1
        }
        let repeatCount = rawCount / Double(multiple)
        let nearestRepeat = repeatCount.rounded()
        let tolerance = max(1, abs(repeatCount)) * Double.ulpOfOne * 16
        let roundedRepeat = abs(repeatCount - nearestRepeat) <= tolerance
            ? nearestRepeat
            : repeatCount.rounded(.up)
        return max(multiple, Int(roundedRepeat) * multiple)
    }
}

enum ProjectColor: String, CaseIterable, Codable, Identifiable {
    case sage, blue, indigo, purple, pink, red
    case orange, yellow, mint, terracotta, graphite
    static let selectableCases = allCases
    var id: Self { self }
    var label: String {
        switch self {
        case .sage: "Sage"
        case .blue: "Blue"
        case .indigo: "Indigo"
        case .purple: "Purple"
        case .pink: "Pink"
        case .red: "Red"
        case .orange: "Orange"
        case .yellow: "Yellow"
        case .mint: "Mint"
        case .terracotta: "Terracotta"
        case .graphite: "Graphite"
        }
    }
    var color: Color {
        switch self {
        case .sage: AppTheme.sage
        case .blue: Color(uiColor: .systemBlue)
        case .indigo: Color(uiColor: .systemIndigo)
        case .purple: Color(uiColor: .systemPurple)
        case .pink: Color(uiColor: .systemPink)
        case .red: Color(uiColor: .systemRed)
        case .orange: Color(uiColor: .systemOrange)
        case .yellow: Color(uiColor: .systemYellow)
        case .mint: Color(uiColor: .systemMint)
        case .terracotta: AppTheme.terracotta
        case .graphite: Color(uiColor: .systemGray)
        }
    }
    var symbolColor: Color {
        switch self {
        case .yellow, .mint: AppTheme.ink
        default: AppTheme.cream
        }
    }
}

struct KnittingProject: Codable, Equatable, Identifiable {
    var id: UUID
    var name: String
    var symbolName: String
    var color: ProjectColor
    var type: ProjectType
    var construction: ProjectConstruction?
    var crownShape: ProjectCrownShape?
    var crownSections: Int?
    var customLandmarks: String
    var gaugeValues: GaugeFormValues
    var measurementUnit: MeasurementUnit
    var measurements: [ProjectMeasurementValue]
    var countRules: ProjectCountRules?
    var notes: String?
    var patternDetailsExpanded: Bool
    var createdAt: Date
    var updatedAt: Date
    var subtitle: String {
        if let construction {
            return "\(type.label) · \(construction.label)"
        }
        if type == .headwear, let crownShape {
            return "\(type.label) · \(crownShape.label)"
        }
        return type.label
    }
    func measurementValue(for kind: ProjectMeasurementKind) -> String {
        measurements.first { $0.kind == kind }?.centimeters ?? ""
    }

    var gaugeInputs: GaugeInputs? {
        GaugeFormDraft(values: gaugeValues, unit: measurementUnit).inputs
    }

    var gaugeResult: GaugeMathResult? {
        gaugeInputs.map(GaugeMath.compute)
    }

    var measurementResults: [ProjectMeasurementResult] {
        guard let inputs = gaugeInputs else { return [] }
        let rules = countRules ?? .wholeNumber
        return measurements.compactMap { measurement in
            guard let centimeters = Double(measurement.centimeters) else { return nil }
            let patternGauge = measurement.kind.axis == .horizontal
                ? inputs.patternStitches
                : inputs.patternRows
            let swatchGauge = measurement.kind.axis == .horizontal
                ? inputs.yourStitches
                : inputs.yourRows
            return ProjectMeasurementResult(
                measurement: measurement,
                patternCount: rules.requiredCount(
                    for: centimeters * patternGauge / 10,
                    axis: measurement.kind.axis
                ),
                requiredCount: rules.requiredCount(
                    for: centimeters * swatchGauge / 10,
                    axis: measurement.kind.axis
                )
            )
        }
    }
}

struct ProjectDraft: Equatable {
    var name = ""
    var symbolName = ProjectType.tops.defaultSymbolName
    var color: ProjectColor = .sage
    var type: ProjectType = .tops
    var construction: ProjectConstruction? = .circularYokeRaglan
    var crownShape: ProjectCrownShape = .round
    var crownSections = 5
    var customLandmarks = ""
    var notes = ""
    var gaugeValues = GaugeFormValues()
    var measurementUnit: MeasurementUnit = .centimeters
    var measurementValues: [ProjectMeasurementKind: String] = [:]
    var countConstraint: ProjectCountConstraint = .wholeNumber
    var stitchRepeat = ""
    var rowRepeat = ""

    init() {}

    init(project: KnittingProject) {
        name = project.name
        symbolName = ProjectIcons.symbols(for: project.type).contains(project.symbolName)
            ? project.symbolName
            : project.type.defaultSymbolName
        color = project.color
        type = project.type
        construction = project.construction
        crownShape = project.crownShape ?? .round
        crownSections = project.crownSections ?? 5
        customLandmarks = project.customLandmarks
        notes = project.notes ?? ""
        gaugeValues = project.gaugeValues
        measurementUnit = project.measurementUnit
        measurementValues = Dictionary(
            uniqueKeysWithValues: project.measurements.map { ($0.kind, $0.centimeters) }
        )
        let countRules = project.countRules ?? .wholeNumber
        countConstraint = countRules.constraint
        stitchRepeat = countRules.stitchRepeat.map(String.init) ?? ""
        rowRepeat = countRules.rowRepeat.map(String.init) ?? ""
    }

    var measurementKinds: [ProjectMeasurementKind] {
        switch type {
        case .tops:
            switch construction {
            case .circularYokeRaglan:
                [
                    .neckOpeningCircumference, .chestCircumference,
                    .upperSleeveCircumference, .cuffCircumference,
                    .yokeRaglanDepth, .bodyLength, .sleeveLength,
                ]
            case .setInSleeve:
                [
                    .chestCircumference, .crossBackWidth, .upperArmCircumference,
                    .cuffCircumference, .bodyLength, .armholeDepthSetIn,
                    .sleeveLength, .sleeveCapDepth,
                ]
            case .dropShoulder:
                [
                    .chestCircumference, .upperSleeveCircumference,
                    .cuffCircumference, .bodyLength, .armholeDepthDrop,
                    .shoulderToCuffLength,
                ]
            case .skirt, .pantsShortsLeggings, nil: []
            }
        case .bottoms:
            switch construction {
            case .skirt:
                [
                    .waistCircumference, .hipCircumference, .hemCircumference,
                    .waistToHipDepth, .bodyLength,
                ]
            case .pantsShortsLeggings:
                [
                    .waistCircumference, .hipCircumference, .thighCircumference,
                    .legOpeningCircumference, .waistToHipDepth, .rise, .legLength,
                ]
            case .circularYokeRaglan, .setInSleeve, .dropShoulder, nil: []
            }
        case .headwear:
            [.hatCircumference, .crownDepth]
        case .footwear:
            [
                .footCircumference, .sockCuffCircumference,
                .footLength, .sockHeight, .heelDepth,
            ]
        case .other:
            [.customWidth, .customDepth]
        }
    }

    var enteredMeasurementKinds: [ProjectMeasurementKind] {
        measurementKinds.filter {
            !measurementValue(for: $0)
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .isEmpty
        }
    }

    var hasMeasurementValues: Bool {
        !enteredMeasurementKinds.isEmpty
    }
    var isIdentityValid: Bool {
        !trimmedName.isEmpty && ProjectIcons.symbols(for: type).contains(symbolName)
    }

    var isConstructionValid: Bool {
        if type == .tops || type == .bottoms {
            return type.constructions.contains { $0 == construction }
        }
        if type == .headwear, crownShape == .faceted {
            return crownSections == 5 || crownSections == 6
        }
        return true
    }

    var isGaugeValid: Bool {
        [
            GaugeFormField.patternStitches, .patternRows, .yourStitches, .yourRows,
        ].allSatisfy {
            if case .success(let value?) = GaugeMath.validate(gaugeValues[$0], for: $0.mathField) {
                return value > 0
            }
            return false
        }
    }

    var isMeasurementsValid: Bool {
        enteredMeasurementKinds.allSatisfy(isMeasurementValid) && validatedCountRules != nil
    }

    var validatedCountRules: ProjectCountRules? {
        guard countConstraint == .patternRepeat else {
            return ProjectCountRules(
                constraint: countConstraint,
                stitchRepeat: nil,
                rowRepeat: nil
            )
        }
        guard let stitchRepeat = validRepeat(stitchRepeat),
              let rowRepeat = validRepeat(rowRepeat) else {
            return nil
        }
        return ProjectCountRules(
            constraint: countConstraint,
            stitchRepeat: stitchRepeat,
            rowRepeat: rowRepeat
        )
    }

    func isMeasurementValid(_ kind: ProjectMeasurementKind) -> Bool {
        let value = measurementValue(for: kind)
        guard !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return true
        }
        guard MeasurementUnit.invalidInchesText(from: value) == nil,
              let number = Double(value) else {
            return false
        }
        return number.rounded(.towardZero) == number &&
            Double(kind.valueRange.lowerBound)...Double(kind.valueRange.upperBound) ~= number
    }

    mutating func selectType(_ newType: ProjectType) {
        type = newType
        construction = newType.constructions.first
        measurementValues = [:]
        customLandmarks = ""
        if !ProjectIcons.symbols(for: newType).contains(symbolName) {
            symbolName = newType.defaultSymbolName
        }
    }

    func makeProject(
        id: UUID = UUID(),
        createdAt: Date? = nil,
        patternDetailsExpanded: Bool = false,
        now: Date = Date()
    ) -> KnittingProject? {
        guard isIdentityValid, isConstructionValid, isGaugeValid, isMeasurementsValid,
              let countRules = validatedCountRules else {
            return nil
        }
        return KnittingProject(
            id: id,
            name: trimmedName,
            symbolName: symbolName,
            color: color,
            type: type,
            construction: construction,
            crownShape: type == .headwear ? crownShape : nil,
            crownSections: type == .headwear && crownShape == .faceted ? crownSections : nil,
            customLandmarks: customLandmarks.trimmingCharacters(in: .whitespacesAndNewlines),
            gaugeValues: gaugeValues,
            measurementUnit: measurementUnit,
            measurements: enteredMeasurementKinds.map {
                ProjectMeasurementValue(kind: $0, centimeters: measurementValue(for: $0))
            },
            countRules: countRules,
            notes: trimmedNotes.isEmpty ? nil : trimmedNotes,
            patternDetailsExpanded: patternDetailsExpanded,
            createdAt: createdAt ?? now,
            updatedAt: now
        )
    }

    func measurementValue(for kind: ProjectMeasurementKind) -> String { measurementValues[kind] ?? "" }
    var trimmedNotes: String { notes.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var trimmedName: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }
    private func validRepeat(_ text: String) -> Int? {
        guard let value = Int(text), ProjectCountRules.repeatRange.contains(value) else {
            return nil
        }
        return value
    }
}
struct ProjectStoreIssue: Identifiable, Equatable {
    enum Kind: Equatable { case load, save }

    let kind: Kind
    let message: String
    var id: String { "\(kind)-\(message)" }
}

@Model
final class StoredProjectRecord {
    @Attribute(.unique) var key: String
    var payload: Data
    var payloadVersion: Int
    var createdAt: Date

    init(key: String, payload: Data, payloadVersion: Int, createdAt: Date) {
        self.key = key
        self.payload = payload
        self.payloadVersion = payloadVersion
        self.createdAt = createdAt
    }
}

private enum ProjectStorageError: Error {
    case unsupportedPayloadVersion
    case mismatchedKey
}

@MainActor
private final class ProjectDatabase {
    private let context: ModelContext
    private let beforeSave: () throws -> Void
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(container: ModelContainer, beforeSave: @escaping () throws -> Void) {
        context = ModelContext(container)
        self.beforeSave = beforeSave
    }

    func load() throws -> [KnittingProject] {
        let descriptor = FetchDescriptor<StoredProjectRecord>(
            sortBy: [
                SortDescriptor(\.createdAt, order: .reverse),
                SortDescriptor(\.key),
            ]
        )
        return try context.fetch(descriptor).map(decode)
    }

    func upsert(_ project: KnittingProject) throws {
        let payload = try encoder.encode(project)
        let key = project.id.uuidString
        let descriptor = FetchDescriptor<StoredProjectRecord>(
            predicate: #Predicate { $0.key == key }
        )
        if let record = try context.fetch(descriptor).first {
            record.payload = payload
            record.payloadVersion = ProjectStore.schemaVersion
            record.createdAt = project.createdAt
        } else {
            context.insert(
                StoredProjectRecord(
                    key: key,
                    payload: payload,
                    payloadVersion: ProjectStore.schemaVersion,
                    createdAt: project.createdAt
                )
            )
        }
        try save()
    }

    func delete(ids: Set<KnittingProject.ID>) throws {
        let records = try context.fetch(FetchDescriptor<StoredProjectRecord>())
        for record in records where UUID(uuidString: record.key).map(ids.contains) == true {
            context.delete(record)
        }
        try save()
    }

    func deleteAll() throws {
        try deleteAllWithoutSaving()
        try save()
    }

    private func decode(_ record: StoredProjectRecord) throws -> KnittingProject {
        guard record.payloadVersion == ProjectStore.schemaVersion else {
            throw ProjectStorageError.unsupportedPayloadVersion
        }
        let project = try decoder.decode(KnittingProject.self, from: record.payload)
        guard record.key == project.id.uuidString else {
            throw ProjectStorageError.mismatchedKey
        }
        return project
    }

    private func deleteAllWithoutSaving() throws {
        for record in try context.fetch(FetchDescriptor<StoredProjectRecord>()) {
            context.delete(record)
        }
    }

    private func save() throws {
        do {
            try beforeSave()
            try context.save()
        } catch {
            context.rollback()
            throw error
        }
    }
}

@MainActor
@Observable
final class ProjectStore {
    static let schemaVersion = 1

    private var database: ProjectDatabase?
    private(set) var projects: [KnittingProject] = []
    var issue: ProjectStoreIssue?

    init(
        modelContainer: ModelContainer? = nil,
        makeModelContainer: () throws -> ModelContainer = {
            try ModelContainer(for: StoredProjectRecord.self)
        },
        beforeSave: @escaping () throws -> Void = {}
    ) {
        do {
            let container = try modelContainer ?? makeModelContainer()
            database = ProjectDatabase(container: container, beforeSave: beforeSave)
            load()
        } catch {
            issue = Self.loadIssue
        }
    }
    func project(id: KnittingProject.ID) -> KnittingProject? { projects.first { $0.id == id } }

    @discardableResult
    func add(_ project: KnittingProject) -> Bool {
        guard persist(project) else { return false }
        projects.insert(project, at: 0)
        return true
    }
    @discardableResult
    func update(_ project: KnittingProject) -> Bool {
        guard let index = projects.firstIndex(where: { $0.id == project.id }) else {
            return false
        }
        guard persist(project) else { return false }
        projects[index] = project
        return true
    }

    @discardableResult
    func updateWorkspace(
        id: KnittingProject.ID,
        gaugeValues: GaugeFormValues,
        unit: MeasurementUnit,
        patternDetailsExpanded: Bool,
        now: Date = Date()
    ) -> Bool {
        guard let index = projects.firstIndex(where: { $0.id == id }) else { return false }
        var project = projects[index]
        project.gaugeValues = gaugeValues
        project.measurementUnit = unit
        project.patternDetailsExpanded = patternDetailsExpanded
        project.updatedAt = now
        return update(project)
    }
    func delete(at offsets: IndexSet) {
        let ids = Set(offsets.map { projects[$0].id })
        guard let database else {
            issue = Self.saveIssue
            return
        }
        do {
            try database.delete(ids: ids)
            projects.remove(atOffsets: offsets)
            clearSaveIssue()
        } catch {
            issue = Self.saveIssue
        }
    }
    func resetArchive() {
        guard let database else {
            issue = Self.saveIssue
            return
        }
        do {
            try database.deleteAll()
            projects = []
            issue = nil
        } catch {
            issue = Self.saveIssue
        }
    }

    private func load() {
        guard let database else { return }
        do {
            projects = try database.load()
        } catch ProjectStorageError.unsupportedPayloadVersion {
            issue = Self.unsupportedVersionIssue
        } catch {
            issue = Self.loadIssue
        }
    }

    private func persist(_ project: KnittingProject) -> Bool {
        guard let database else {
            issue = Self.saveIssue
            return false
        }
        do {
            try database.upsert(project)
            clearSaveIssue()
            return true
        } catch {
            issue = Self.saveIssue
            return false
        }
    }

    private func clearSaveIssue() {
        if issue?.kind == .save { issue = nil }
    }

    private static let unsupportedVersionIssue = ProjectStoreIssue(
        kind: .load,
        message: "These projects were saved by an unsupported data version."
    )
    private static let loadIssue = ProjectStoreIssue(
        kind: .load,
        message: "Saved projects could not be read. Your stored data has not been replaced."
    )
    private static let saveIssue = ProjectStoreIssue(
        kind: .save,
        message: "Your latest project changes could not be saved."
    )
}
