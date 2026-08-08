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

// MARK: - Main View

struct ContentView: View {
    @StateObject private var store = BrickStore()

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
                                Text(m.rawValue).tag(m)
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
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showManager = true
                    } label: {
                        Image(systemName: "square.stack.3d.up")
                    }
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { focusedField = nil }
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
            .alert("Save Brick Type", isPresented: $showSaveAlert) {
                TextField("Name", text: $newBrickName)
                Button("Cancel", role: .cancel) { }
                Button("Save") {
                    let brick = BrickType(name: newBrickName.isEmpty ? "Custom" : newBrickName,
                                           lengthCm: parseDouble(brickLength),
                                           widthCm: parseDouble(brickWidth),
                                           heightCm: parseDouble(brickHeight))
                    store.customBricks.append(brick)
                    selectedBrickID = brick.id
                    newBrickName = ""
                }
            } message: {
                Text("Give this brick size a name to save it for later.")
            }
        }
        .preferredColorScheme(.dark)
        .tint(.orange)
    }

    private var dimensionsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label(mode == .room ? "Room Dimensions" : "Wall Dimensions", systemImage: "ruler")
                .font(.headline)

            if mode == .room {
                HStack(spacing: 12) {
                    DimField(label: "Width", unit: "m", text: $roomWidth, focused: $focusedField, field: .roomWidth)
                    DimField(label: "Length", unit: "m", text: $roomLength, focused: $focusedField, field: .roomLength)
                }
                DimField(label: "Height", unit: "m", text: $roomHeight, focused: $focusedField, field: .roomHeight)
            } else {
                HStack(spacing: 12) {
                    DimField(label: "Width", unit: "m", text: $wallWidth, focused: $focusedField, field: .wallWidth)
                    DimField(label: "Height", unit: "m", text: $wallHeight, focused: $focusedField, field: .wallHeight)
                }
            }
        }
        .card()
    }

    private var brickCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Brick Size", systemImage: "cube")
                .font(.headline)

            Picker("Brick type", selection: $selectedBrickID) {
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
                DimField(label: "Length", unit: "cm", text: $brickLength, focused: $focusedField, field: .brickL)
                DimField(label: "Width", unit: "cm", text: $brickWidth, focused: $focusedField, field: .brickW)
                DimField(label: "Height", unit: "cm", text: $brickHeight, focused: $focusedField, field: .brickH)
            }

            Button {
                showSaveAlert = true
            } label: {
                Label("Save as New Brick Type", systemImage: "plus.circle")
                    .font(.subheadline.weight(.medium))
            }
            .buttonStyle(.borderless)

            VStack(alignment: .leading, spacing: 6) {
                Text("Waste allowance: \(Int(wastePercent))%")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Slider(value: $wastePercent, in: 0...25, step: 1)
            }
        }
        .card()
    }

    private var resultCard: some View {
        VStack(spacing: 8) {
            Text("BRICKS NEEDED")
                .font(.caption)
                .tracking(2)
                .foregroundStyle(.secondary)
            Text("\(bricksNeeded)")
                .font(.system(size: 56, weight: .bold, design: .rounded))
                .foregroundStyle(
                    LinearGradient(colors: [.orange, .pink], startPoint: .leading, endPoint: .trailing)
                )
            Text(String(format: "Covers %.2f m²", areaM2))
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

    var body: some View {
        NavigationStack {
            List {
                Section("Built-in") {
                    Button {
                        onPick(BrickType.standard)
                        dismiss()
                    } label: {
                        row(for: BrickType.standard)
                    }
                }
                if !store.customBricks.isEmpty {
                    Section("Your Brick Types") {
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
            .navigationTitle("Brick Types")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
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
