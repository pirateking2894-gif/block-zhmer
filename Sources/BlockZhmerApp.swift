import SwiftUI
import Foundation

// MARK: - Model

struct BrickType: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var name: String
    var lengthCm: Double
    var widthCm: Double
    var heightCm: Double

    static let standard = BrickType(name: "Standard", lengthCm: 19, widthCm: 9, heightCm: 9)
}

enum CalcMode: String, CaseIterable, Identifiable {
    case room = "Whole Room"
    case wall = "Single Wall"
    var id: String { rawValue }

    func localized(_ lang: AppLanguage) -> String {
        switch self {
        case .room: return LocKey.wholeRoom.text(lang)
        case .wall: return LocKey.singleWall.text(lang)
        }
    }
}

// MARK: - Localization

enum AppLanguage: String, CaseIterable, Identifiable {
    case en, ku
    var id: String { rawValue }
    var shortLabel: String { self == .en ? "EN" : "KU" }
}

enum LocKey {
    case wholeRoom, singleWall
    case roomDimensions, wallDimensions
    case widthLabel, lengthLabel, heightLabel
    case brickSize, brickType
    case saveAsNewBrickType
    case wasteAllowance
    case bricksNeeded
    case covers
    case brickTypes
    case builtIn
    case yourBrickTypes
    case done
    case saveBrickTypeTitle
    case namePlaceholder
    case cancel
    case save
    case saveMessage

    func text(_ lang: AppLanguage) -> String {
        switch (self, lang) {
        case (.wholeRoom, .en): return "Whole Room"
        case (.wholeRoom, .ku): return "ژوورێکی تەواو"
        case (.singleWall, .en): return "Single Wall"
        case (.singleWall, .ku): return "دیوارێک"
        case (.roomDimensions, .en): return "Room Dimensions"
        case (.roomDimensions, .ku): return "ڕەهەندەکانی ژوور"
        case (.wallDimensions, .en): return "Wall Dimensions"
        case (.wallDimensions, .ku): return "ڕەهەندەکانی دیوارێک"
        case (.widthLabel, .en): return "Width"
        case (.widthLabel, .ku): return "پانی"
        case (.lengthLabel, .en): return "Length"
        case (.lengthLabel, .ku): return "درێژی"
        case (.heightLabel, .en): return "Height"
        case (.heightLabel, .ku): return "بەرزی"
        case (.brickSize, .en): return "Brick Size"
        case (.brickSize, .ku): return "Mقەبارەی بلۆک"
        case (.brickType, .en): return "Brick type"
        case (.brickType, .ku): return "جۆری بلۆک"
        case (.saveAsNewBrickType, .en): return "Save as New Brick Type"
        case (.saveAsNewBrickType, .ku): return "وەکو بلۆکێکی نوێ تۆماریبکە"
        case (.wasteAllowance, .en): return "Waste allowance"
        case (.wasteAllowance, .ku): return "ڕێژەی بەفیڕۆچوون"
        case (.bricksNeeded, .en): return "BRICKS NEEDED"
        case (.bricksNeeded, .ku): return "بلۆکی پێویست"
        case (.covers, .en): return "Covers"
        case (.covers, .ku): return "ڕووبەری"
        case (.brickTypes, .en): return "Brick Types"
        case (.brickTypes, .ku): return "جۆری بلۆک"
        case (.builtIn, .en): return "Built-in"
        case (.builtIn, .ku): return "کەرپوچی ستاندارد"
        case (.yourBrickTypes, .en): return "Your Brick Types"
        case (.yourBrickTypes, .ku): return "جۆرەکانی بلۆک"
        case (.done, .en): return "Done"
        case (.done, .ku): return "بەڵێ"
        case (.saveBrickTypeTitle, .en): return "Save Brick Type"
        case (.saveBrickTypeTitle, .ku): return "جۆری بلۆک تۆماربکە"
        case (.namePlaceholder, .en): return "Name"
        case (.namePlaceholder, .ku): return "ناو"
        case (.cancel, .en): return "Cancel"
        case (.cancel, .ku): return "پاژگەزبوونەوە"
        case (.save, .en): return "Save"
        case (.save, .ku): return "تۆماربکە"
        case (.saveMessage, .en): return "Give this brick size a name to save it for later."
        case (.saveMessage, .ku): return "ناوێک بدە بەم بلۆکە "
        }
    }
}

// MARK: - Calculator

enum BrickCalculator {
    static func wallArea(widthM: Double, heightM: Double) -> Double {
        max(widthM, 0) * max(heightM, 0)
    }

    static func roomWallArea(widthM: Double, lengthM: Double, heightM: Double) -> Double {
        let perimeter = 2 * (max(widthM, 0) + max(lengthM, 0))
        return perimeter * max(heightM, 0)
    }

    static func bricksNeeded(areaM2: Double, brick: BrickType, wastePercent: Double) -> Int {
        let faceCm2 = brick.lengthCm * brick.heightCm
        guard faceCm2 > 0, areaM2 > 0 else { return 0 }
        let areaCm2 = areaM2 * 10_000
        let raw = areaCm2 / faceCm2
        let withWaste = raw * (1 + max(wastePercent, 0) / 100)
        return Int(withWaste.rounded(.up))
    }
}

// MARK: - Persistence

final class BrickStore: ObservableObject {
    @Published var customBricks: [BrickType] = [] {
        didSet { persist() }
    }

    private let storageKey = "com.blockzhmer.customBricks"

    init() {
        restore()
    }

    var allBricks: [BrickType] {
        [BrickType.standard] + customBricks
    }

    func delete(at offsets: IndexSet) {
        customBricks.remove(atOffsets: offsets)
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(customBricks) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }

    private func restore() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([BrickType].self, from: data) else { return }
        customBricks = decoded
    }
}

// MARK: - Helpers

func parseDouble(_ s: String) -> Double {
    Double(s.replacingOccurrences(of: ",", with: ".")) ?? 0
}

func trimmedNumber(_ value: Double) -> String {
    value.truncatingRemainder(dividingBy: 1) == 0
        ? String(format: "%.0f", value)
        : String(format: "%.2f", value)
}

enum Field: Hashable {
    case roomWidth, roomLength, roomHeight
    case wallWidth, wallHeight
    case brickL, brickW, brickH
}

// MARK: - Reusable UI

struct CardBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(18)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
            )
    }
}

extension View {
    func card() -> some View { modifier(CardBackground()) }
}

struct DimField: View {
    let label: String
    let unit: String
    @Binding var text: String
    var focused: FocusState<Field?>.Binding
    var field: Field

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            HStack {
                TextField("0", text: $text)
                    .keyboardType(.decimalPad)
                    .focused(focused, equals: field)
                    .font(.system(.title3, design: .rounded, weight: .semibold))
                Text(unit)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color.primary.opacity(0.06), in: RoundedRectangle(cornerRadius: 14))
        }
    }
}

struct LanguageToggle: View {
    @Binding var language: AppLanguage
    @Namespace private var pillSpace

    var body: some View {
        HStack(spacing: 2) {
            ForEach(AppLanguage.allCases) { lang in
                Text(lang.shortLabel)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(language == lang ? .white : .secondary)
                    .frame(width: 32, height: 24)
                    .background {
                        if language == lang {
                            Capsule()
                                .fill(LinearGradient(colors: [.orange, .pink], startPoint: .leading, endPoint: .trailing))
                                .matchedGeometryEffect(id: "pill", in: pillSpace)
                        }
                    }
                    .contentShape(Capsule())
                    .onTapGesture {
                        withAnimation(.spring(response: 0.32, dampingFraction: 0.75)) {
                            language = lang
                        }
                    }
            }
        }
        .padding(3)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(Capsule().strokeBorder(Color.white.opacity(0.12), lineWidth: 1))
    }
}

// MARK: - Main View

struct ContentView: View {
    @StateObject private var store = BrickStore()
    @AppStorage("appLanguage") private var languageRaw: String = AppLanguage.en.rawValue
    private var language: AppLanguage { AppLanguage(rawValue: languageRaw) ?? .en }
    private var languageBinding: Binding<AppLanguage> {
        Binding(get: { language }, set: { languageRaw = $0.rawValue })
    }

    @State private var mode: CalcMode = .room

    @State private var roomWidth = ""
    @State private var roomLength = ""
    @State private var roomHeight = ""

    @State private var wallWidth = ""
    @State private var wallHeight = ""

    @State private var selectedBrickID: UUID = BrickType.standard.id
    @State private var brickLength = trimmedNumber(BrickType.standard.lengthCm)
    @State private var brickWidth = trimmedNumber(BrickType.standard.widthCm)
    @State private var brickHeight = trimmedNumber(BrickType.standard.heightCm)

    @State private var wastePercent: Double = 5

    @State private var showManager = false
    @State private var showSaveAlert = false
    @State private var newBrickName = ""

    @FocusState private var focusedField: Field?

    private var areaM2: Double {
        switch mode {
        case .wall:
            return BrickCalculator.wallArea(widthM: parseDouble(wallWidth), heightM: parseDouble(wallHeight))
        case .room:
            return BrickCalculator.roomWallArea(widthM: parseDouble(roomWidth), lengthM: parseDouble(roomLength), heightM: parseDouble(roomHeight))
        }
    }

    private var currentBrick: BrickType {
        BrickType(name: "current", lengthCm: parseDouble(brickLength), widthCm: parseDouble(brickWidth), heightCm: parseDouble(brickHeight))
    }

    private var bricksNeeded: Int {
        BrickCalculator.bricksNeeded(areaM2: areaM2, brick: currentBrick, wastePercent: wastePercent)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color(red: 0.06, green: 0.07, blue: 0.11), Color(red: 0.12, green: 0.09, blue: 0.18)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 18) {
                        Picker("Mode", selection: $mode) {
                            ForEach(CalcMode.allCases) { m in
                                Text(m.localized(language)).tag(m)
                            }
                        }
                        .pickerStyle(.segmented)

                        dimensionsCard
                        brickCard
                        resultCard
                    }
                    .padding(20)
                    .padding(.top, 8)
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .navigationTitle("Block Zhmêr")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    LanguageToggle(language: languageBinding)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showManager = true
                    } label: {
                        Image(systemName: "square.stack.3d.up")
                    }
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button(LocKey.done.text(language)) { focusedField = nil }
                }
            }
            .sheet(isPresented: $showManager) {
                BrickManagerView(store: store) { picked in
                    selectedBrickID = picked.id
                    brickLength = trimmedNumber(picked.lengthCm)
                    brickWidth = trimmedNumber(picked.widthCm)
                    brickHeight = trimmedNumber(picked.heightCm)
                }
            }
            .alert(LocKey.saveBrickTypeTitle.text(language), isPresented: $showSaveAlert) {
                TextField(LocKey.namePlaceholder.text(language), text: $newBrickName)
                Button(LocKey.cancel.text(language), role: .cancel) { }
                Button(LocKey.save.text(language)) {
                    let brick = BrickType(name: newBrickName.isEmpty ? "Custom" : newBrickName,
                                           lengthCm: parseDouble(brickLength),
                                           widthCm: parseDouble(brickWidth),
                                           heightCm: parseDouble(brickHeight))
                    store.customBricks.append(brick)
                    selectedBrickID = brick.id
                    newBrickName = ""
                }
            } message: {
                Text(LocKey.saveMessage.text(language))
            }
        }
        .preferredColorScheme(.dark)
        .tint(.orange)
    }

    private var dimensionsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label(mode == .room ? LocKey.roomDimensions.text(language) : LocKey.wallDimensions.text(language), systemImage: "ruler")
                .font(.headline)

            if mode == .room {
                HStack(spacing: 12) {
                    DimField(label: LocKey.widthLabel.text(language), unit: "m", text: $roomWidth, focused: $focusedField, field: .roomWidth)
                    DimField(label: LocKey.lengthLabel.text(language), unit: "m", text: $roomLength, focused: $focusedField, field: .roomLength)
                }
                DimField(label: LocKey.heightLabel.text(language), unit: "m", text: $roomHeight, focused: $focusedField, field: .roomHeight)
            } else {
                HStack(spacing: 12) {
                    DimField(label: LocKey.widthLabel.text(language), unit: "m", text: $wallWidth, focused: $focusedField, field: .wallWidth)
                    DimField(label: LocKey.heightLabel.text(language), unit: "m", text: $wallHeight, focused: $focusedField, field: .wallHeight)
                }
            }
        }
        .card()
    }

    private var brickCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label(LocKey.brickSize.text(language), systemImage: "cube")
                .font(.headline)

            Picker(LocKey.brickType.text(language), selection: $selectedBrickID) {
                ForEach(store.allBricks) { b in
                    Text(b.name).tag(b.id)
                }
            }
            .pickerStyle(.menu)
            .onChange(of: selectedBrickID) { _, newID in
                if let b = store.allBricks.first(where: { $0.id == newID }) {
                    brickLength = trimmedNumber(b.lengthCm)
                    brickWidth = trimmedNumber(b.widthCm)
                    brickHeight = trimmedNumber(b.heightCm)
                }
            }

            HStack(spacing: 12) {
                DimField(label: LocKey.lengthLabel.text(language), unit: "cm", text: $brickLength, focused: $focusedField, field: .brickL)
                DimField(label: LocKey.widthLabel.text(language), unit: "cm", text: $brickWidth, focused: $focusedField, field: .brickW)
                DimField(label: LocKey.heightLabel.text(language), unit: "cm", text: $brickHeight, focused: $focusedField, field: .brickH)
            }

            Button {
                showSaveAlert = true
            } label: {
                Label(LocKey.saveAsNewBrickType.text(language), systemImage: "plus.circle")
                    .font(.subheadline.weight(.medium))
            }
            .buttonStyle(.borderless)

            VStack(alignment: .leading, spacing: 6) {
                Text("\(LocKey.wasteAllowance.text(language)): \(Int(wastePercent))%")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Slider(value: $wastePercent, in: 0...25, step: 1)
            }
        }
        .card()
    }

    private var resultCard: some View {
        VStack(spacing: 8) {
            Text(LocKey.bricksNeeded.text(language))
                .font(.caption)
                .tracking(2)
                .foregroundStyle(.secondary)
            Text("\(bricksNeeded)")
                .font(.system(size: 56, weight: .bold, design: .rounded))
                .foregroundStyle(
                    LinearGradient(colors: [.orange, .pink], startPoint: .leading, endPoint: .trailing)
                )
            Text("\(LocKey.covers.text(language)) \(String(format: "%.2f", areaM2)) m²")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .card()
    }
}

// MARK: - Manager

struct BrickManagerView: View {
    @ObservedObject var store: BrickStore
    var onPick: (BrickType) -> Void
    @Environment(\.dismiss) private var dismiss
    @AppStorage("appLanguage") private var languageRaw: String = AppLanguage.en.rawValue
    private var language: AppLanguage { AppLanguage(rawValue: languageRaw) ?? .en }

    var body: some View {
        NavigationStack {
            List {
                Section(LocKey.builtIn.text(language)) {
                    Button {
                        onPick(BrickType.standard)
                        dismiss()
                    } label: {
                        row(for: BrickType.standard)
                    }
                }
                if !store.customBricks.isEmpty {
                    Section(LocKey.yourBrickTypes.text(language)) {
                        ForEach(store.customBricks) { brick in
                            Button {
                                onPick(brick)
                                dismiss()
                            } label: {
                                row(for: brick)
                            }
                        }
                        .onDelete(perform: store.delete)
                    }
                }
            }
            .navigationTitle(LocKey.brickTypes.text(language))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(LocKey.done.text(language)) { dismiss() }
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func row(for brick: BrickType) -> some View {
        HStack {
            VStack(alignment: .leading) {
                Text(brick.name).font(.body.weight(.medium))
                Text("\(trimmedNumber(brick.lengthCm))×\(trimmedNumber(brick.widthCm))×\(trimmedNumber(brick.heightCm)) cm")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .foregroundStyle(.primary)
    }
}

// MARK: - App

@main
struct BlockZhmerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
