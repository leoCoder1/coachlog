import SwiftData
import SwiftUI

enum BodyMetricDirection {
    case lowerIsBetter
    case higherIsBetter
    case neutral
}

struct BodyMetricChange: Identifiable {
    var title: String
    var startValue: Double
    var latestValue: Double
    var unit: String
    var direction: BodyMetricDirection

    var id: String { title }

    var delta: Double {
        latestValue - startValue
    }

    var isPositive: Bool {
        switch direction {
        case .lowerIsBetter:
            delta < 0
        case .higherIsBetter:
            delta > 0
        case .neutral:
            abs(delta) <= 0.1
        }
    }

    var signedDeltaText: String {
        let sign = delta > 0 ? "+" : ""
        return "\(sign)\(delta.formatted(.number.precision(.fractionLength(0...1)))) \(unit)"
    }
}

enum BodyMeasurementInsights {
    static let checkInIntervalDays = 21

    static func latestMeasurement(from measurements: [BodyMeasurement]) -> BodyMeasurement? {
        measurements.sorted { $0.date > $1.date }.first
    }

    static func isCheckInDue(_ measurements: [BodyMeasurement], referenceDate: Date = .now) -> Bool {
        guard let latest = latestMeasurement(from: measurements) else { return true }
        return daysSince(latest.date, referenceDate: referenceDate) >= checkInIntervalDays
    }

    static func daysUntilNextCheckIn(_ measurements: [BodyMeasurement], referenceDate: Date = .now) -> Int {
        guard let latest = latestMeasurement(from: measurements) else { return 0 }
        return max(0, checkInIntervalDays - daysSince(latest.date, referenceDate: referenceDate))
    }

    static func lastUpdatedText(_ measurements: [BodyMeasurement], referenceDate: Date = .now) -> String {
        guard let latest = latestMeasurement(from: measurements) else {
            return "No baseline yet"
        }

        let days = daysSince(latest.date, referenceDate: referenceDate)
        if days == 0 {
            return "Updated today"
        }
        if days == 1 {
            return "Updated yesterday"
        }
        return "Updated \(days) days ago"
    }

    static func metricChanges(
        from measurements: [BodyMeasurement],
        lengthUnit: LengthUnitPreference = .inches
    ) -> [BodyMetricChange] {
        let sortedMeasurements = measurements.sorted { $0.date < $1.date }
        guard let first = sortedMeasurements.first,
              let latest = sortedMeasurements.last,
              first.id != latest.id else {
            return []
        }

        let specs: [(String, (BodyMeasurement) -> Double?, BodyMetricDirection)] = [
            ("Waist", { $0.waist }, .lowerIsBetter),
            ("Abdomen", { $0.abdomen ?? $0.waist }, .lowerIsBetter),
            ("Chest", { $0.chest }, .higherIsBetter),
            ("Biceps", { $0.arm }, .higherIsBetter),
            ("Thigh", { $0.thigh }, .higherIsBetter),
            ("Shoulders", { $0.shoulders }, .higherIsBetter)
        ]

        return specs.compactMap { title, value, direction in
            guard let startValue = value(first),
                  let latestValue = value(latest),
                  abs(latestValue - startValue) >= 0.05 else {
                return nil
            }

            return BodyMetricChange(
                title: title,
                startValue: lengthUnit.displayLength(fromInches: startValue),
                latestValue: lengthUnit.displayLength(fromInches: latestValue),
                unit: lengthUnit.unitLabel,
                direction: direction
            )
        }
    }

    private static func daysSince(_ date: Date, referenceDate: Date) -> Int {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: date)
        let end = calendar.startOfDay(for: referenceDate)
        return max(0, calendar.dateComponents([.day], from: start, to: end).day ?? 0)
    }
}

struct BodyMeasurementReminderCard: View {
    var measurements: [BodyMeasurement]
    var onOpen: () -> Void
    @AppStorage(UnitPreferenceKeys.lengthUnit) private var lengthUnitRaw = LengthUnitPreference.inches.rawValue

    private var lengthUnit: LengthUnitPreference {
        LengthUnitPreference(rawValue: lengthUnitRaw) ?? .inches
    }

    private var isDue: Bool {
        BodyMeasurementInsights.isCheckInDue(measurements)
    }

    private var changes: [BodyMetricChange] {
        Array(BodyMeasurementInsights.metricChanges(from: measurements, lengthUnit: lengthUnit).prefix(3))
    }

    var body: some View {
        CoachCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 12) {
                    Image(systemName: isDue ? "figure.stand.measurement.vertical" : "chart.line.uptrend.xyaxis")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(Color.coachAccent)
                        .frame(width: 28)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(isDue ? "Measurement Check-In" : "Body Feedback")
                            .font(.headline)

                        Text(statusText)
                            .font(.caption)
                            .foregroundStyle(Color.coachSecondaryText)
                    }

                    Spacer()

                    Text(isDue ? "Due" : "On Track")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(isDue ? Color.coachWarm : Color.freshness(.ready))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background((isDue ? Color.coachWarm : Color.freshness(.ready)).opacity(0.16))
                        .clipShape(Capsule())
                }

                if changes.isEmpty {
                    Text("Build a baseline now, then AI Coach will compare waist, abdomen, chest, biceps, and thigh every few weeks.")
                        .font(.subheadline)
                        .foregroundStyle(Color.coachSecondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    HStack(spacing: 8) {
                        ForEach(changes) { change in
                            BodyMetricChangePill(change: change)
                        }
                    }
                }

                actionButton
            }
        }
    }

    @ViewBuilder
    private var actionButton: some View {
        if isDue {
            Button(action: onOpen) {
                buttonLabel("Update Measurements")
            }
            .buttonStyle(CoachPrimaryButtonStyle())
        } else {
            Button(action: onOpen) {
                buttonLabel("Open Body Check-In")
            }
            .buttonStyle(CoachSecondaryButtonStyle())
        }
    }

    private func buttonLabel(_ title: String) -> some View {
        Label(title, systemImage: "ruler")
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
    }

    private var statusText: String {
        guard BodyMeasurementInsights.latestMeasurement(from: measurements) != nil else {
            return "Start with a baseline"
        }

        if isDue {
            return "\(BodyMeasurementInsights.lastUpdatedText(measurements)). Time for the 3-week update."
        }

        let days = BodyMeasurementInsights.daysUntilNextCheckIn(measurements)
        return "\(BodyMeasurementInsights.lastUpdatedText(measurements)). Next check-in in \(days) day\(days == 1 ? "" : "s")."
    }
}

struct BodyMeasurementCheckInView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \BodyMeasurement.date, order: .reverse) private var measurements: [BodyMeasurement]

    @State private var draft: BodyMeasurementDraft
    @State private var selectedPart: BodyMeasurementPart?
    @AppStorage(UnitPreferenceKeys.weightUnit) private var weightUnitRaw = WeightUnitPreference.pounds.rawValue
    @AppStorage(UnitPreferenceKeys.lengthUnit) private var lengthUnitRaw = LengthUnitPreference.inches.rawValue

    init(latestMeasurement: BodyMeasurement?) {
        _draft = State(initialValue: BodyMeasurementDraft(from: latestMeasurement))
    }

    private var weightUnit: WeightUnitPreference {
        WeightUnitPreference(rawValue: weightUnitRaw) ?? .pounds
    }

    private var lengthUnit: LengthUnitPreference {
        LengthUnitPreference(rawValue: lengthUnitRaw) ?? .inches
    }

    var body: some View {
        NavigationStack {
            ZStack {
                CoachScreenBackground()

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        header
                        BodyMeasurementBoard(
                            draft: $draft,
                            selectedPart: $selectedPart,
                            weightUnit: weightUnit,
                            lengthUnit: lengthUnit
                        )
                        recentChanges
                        saveButton
                    }
                    .padding()
                    .padding(.bottom, 24)
                }
            }
            .navigationTitle("Body Check-In")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .sheet(item: $selectedPart) { part in
                MeasurementWheelSheet(
                    part: part,
                    draft: $draft,
                    weightUnit: weightUnit,
                    lengthUnit: lengthUnit
                ) {
                    selectedPart = nil
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private var header: some View {
        CoachCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label("3-Week Measurement Loop", systemImage: "calendar.badge.clock")
                        .font(.headline)

                    Spacer()
                }

                Text("Track the signals that photos and scale weight miss: waist and abdomen trending down, chest and biceps trending up.")
                    .font(.subheadline)
                    .foregroundStyle(Color.coachSecondaryText)
                    .fixedSize(horizontal: false, vertical: true)

                DatePicker("Date", selection: $draft.date, displayedComponents: .date)
                    .datePickerStyle(.compact)
            }
        }
    }

    @ViewBuilder
    private var recentChanges: some View {
        let changes = BodyMeasurementInsights.metricChanges(from: measurements, lengthUnit: lengthUnit)

        if !changes.isEmpty {
            CoachCard {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Progress Signals")
                        .font(.headline)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                        ForEach(changes.prefix(4)) { change in
                            BodyMetricDeltaTile(change: change)
                        }
                    }
                }
            }
        }
    }

    private var saveButton: some View {
        Button {
            saveMeasurement()
            dismiss()
        } label: {
            Label("Save Check-In", systemImage: "checkmark")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
        }
        .buttonStyle(CoachPrimaryButtonStyle())
    }

    private func saveMeasurement() {
        if let sameDay = measurements.first(where: { Calendar.current.isDate($0.date, inSameDayAs: draft.date) }) {
            draft.apply(to: sameDay)
        } else {
            modelContext.insert(draft.makeMeasurement())
        }

        try? modelContext.save()
    }
}

struct BodyMeasurementDraft: Equatable {
    var date: Date
    var weight: Double
    var neck: Double
    var shoulders: Double
    var chest: Double
    var waist: Double
    var abdomen: Double
    var hip: Double
    var biceps: Double
    var thigh: Double
    var calf: Double

    init(from measurement: BodyMeasurement?) {
        date = .now
        weight = Self.normalized(measurement?.weight ?? 180, for: .weight)
        neck = Self.normalized(measurement?.neck ?? 15, for: .neck)
        shoulders = Self.normalized(measurement?.shoulders ?? 42, for: .shoulders)
        chest = Self.normalized(measurement?.chest ?? 40, for: .chest)
        waist = Self.normalized(measurement?.waist ?? 34, for: .waist)
        abdomen = Self.normalized(measurement?.abdomen ?? measurement?.waist ?? 35, for: .abdomen)
        hip = Self.normalized(measurement?.hip ?? 40, for: .hip)
        biceps = Self.normalized(measurement?.arm ?? 14, for: .biceps)
        thigh = Self.normalized(measurement?.thigh ?? 22, for: .thigh)
        calf = Self.normalized(measurement?.calf ?? 14, for: .calf)
    }

    func value(for part: BodyMeasurementPart) -> Double {
        switch part {
        case .weight: weight
        case .neck: neck
        case .shoulders: shoulders
        case .chest: chest
        case .waist: waist
        case .abdomen: abdomen
        case .hip: hip
        case .biceps: biceps
        case .thigh: thigh
        case .calf: calf
        }
    }

    mutating func setValue(_ value: Double, for part: BodyMeasurementPart) {
        let value = Self.normalized(value, for: part)

        switch part {
        case .weight: weight = value
        case .neck: neck = value
        case .shoulders: shoulders = value
        case .chest: chest = value
        case .waist: waist = value
        case .abdomen: abdomen = value
        case .hip: hip = value
        case .biceps: biceps = value
        case .thigh: thigh = value
        case .calf: calf = value
        }
    }

    func makeMeasurement() -> BodyMeasurement {
        BodyMeasurement(
            date: date,
            weight: weight,
            waist: waist,
            chest: chest,
            arm: biceps,
            thigh: thigh,
            neck: neck,
            shoulders: shoulders,
            abdomen: abdomen,
            hip: hip,
            calf: calf
        )
    }

    func apply(to measurement: BodyMeasurement) {
        measurement.date = date
        measurement.weight = weight
        measurement.waist = waist
        measurement.chest = chest
        measurement.arm = biceps
        measurement.thigh = thigh
        measurement.neck = neck
        measurement.shoulders = shoulders
        measurement.abdomen = abdomen
        measurement.hip = hip
        measurement.calf = calf
    }

    private static func normalized(_ value: Double, for part: BodyMeasurementPart) -> Double {
        let steppedValue = (value / part.canonicalStep).rounded() * part.canonicalStep
        return min(max(steppedValue, part.canonicalRange.lowerBound), part.canonicalRange.upperBound)
    }
}

enum BodyMeasurementPart: String, CaseIterable, Identifiable {
    case weight = "Weight"
    case neck = "Neck"
    case shoulders = "Shoulders"
    case chest = "Chest"
    case waist = "Waist"
    case abdomen = "Abdomen"
    case hip = "Hip"
    case biceps = "Biceps"
    case thigh = "Thigh"
    case calf = "Calf"

    var id: String { rawValue }

    func unit(weightUnit: WeightUnitPreference, lengthUnit: LengthUnitPreference) -> String {
        self == .weight ? weightUnit.unitLabel : lengthUnit.unitLabel
    }

    var canonicalStep: Double {
        self == .weight ? 0.5 : 0.25
    }

    var canonicalRange: ClosedRange<Double> {
        switch self {
        case .weight: 80...400
        case .neck: 10...24
        case .shoulders: 28...64
        case .chest: 24...64
        case .waist: 20...70
        case .abdomen: 20...80
        case .hip: 28...70
        case .biceps: 8...28
        case .thigh: 14...40
        case .calf: 10...26
        }
    }

    func displayValue(
        fromCanonical value: Double,
        weightUnit: WeightUnitPreference,
        lengthUnit: LengthUnitPreference
    ) -> Double {
        if self == .weight {
            return weightUnit.roundedDisplayWeight(fromPounds: value, step: weightUnit.bodyWeightStep)
        }

        return lengthUnit.roundedDisplayLength(fromInches: value)
    }

    func canonicalValue(
        fromDisplay value: Double,
        weightUnit: WeightUnitPreference,
        lengthUnit: LengthUnitPreference
    ) -> Double {
        if self == .weight {
            return weightUnit.pounds(fromDisplayWeight: value)
        }

        return lengthUnit.inches(fromDisplayLength: value)
    }

    func displayValues(
        weightUnit: WeightUnitPreference,
        lengthUnit: LengthUnitPreference
    ) -> [Double] {
        if self == .weight {
            return weightUnit.displayWeightValues(fromPoundsRange: canonicalRange, step: weightUnit.bodyWeightStep)
        }

        return lengthUnit.displayLengthValues(fromInchesRange: canonicalRange)
    }

    func formattedValue(
        _ canonicalValue: Double,
        weightUnit: WeightUnitPreference,
        lengthUnit: LengthUnitPreference
    ) -> String {
        if self == .weight {
            return weightUnit.formattedWeight(canonicalValue)
        }

        return lengthUnit.formattedLength(canonicalValue)
    }

    static let leftColumn: [BodyMeasurementPart] = [.neck, .chest, .abdomen, .biceps, .thigh]
    static let rightColumn: [BodyMeasurementPart] = [.shoulders, .waist, .hip, .calf, .weight]
}

private struct BodyMeasurementBoard: View {
    @Binding var draft: BodyMeasurementDraft
    @Binding var selectedPart: BodyMeasurementPart?
    var weightUnit: WeightUnitPreference
    var lengthUnit: LengthUnitPreference

    var body: some View {
        CoachCard(padding: 12) {
            VStack(spacing: 12) {
                HStack(alignment: .center, spacing: 10) {
                    measurementColumn(BodyMeasurementPart.leftColumn)

                    BodySilhouetteView(selectedPart: selectedPart)
                        .frame(width: 76, height: 260)

                    measurementColumn(BodyMeasurementPart.rightColumn)
                }

                ratioCard
            }
        }
    }

    private func measurementColumn(_ parts: [BodyMeasurementPart]) -> some View {
        VStack(spacing: 8) {
            ForEach(parts) { part in
                MeasurementPartButton(
                    part: part,
                    value: draft.value(for: part),
                    weightUnit: weightUnit,
                    lengthUnit: lengthUnit,
                    isSelected: selectedPart == part
                ) {
                    selectedPart = part
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var ratioCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Waist-Hip Ratio")
                    .font(.subheadline.weight(.semibold))

                Text((draft.waist / max(draft.hip, 1)).formatted(.number.precision(.fractionLength(2))))
                    .font(.title3.weight(.semibold))
            }

            Spacer()

            Image(systemName: "info.circle")
                .font(.title3)
                .foregroundStyle(Color.coachSecondaryText)
        }
        .padding(12)
        .background(Color.coachSurfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private struct MeasurementPartButton: View {
    var part: BodyMeasurementPart
    var value: Double
    var weightUnit: WeightUnitPreference
    var lengthUnit: LengthUnitPreference
    var isSelected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 4) {
                Text(part.rawValue)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)

                Text(part.formattedValue(value, weightUnit: weightUnit, lengthUnit: lengthUnit))
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(Color.coachSecondaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
            .padding(.horizontal, 10)
            .background(isSelected ? Color.coachAccent.opacity(0.12) : Color.coachSurfaceElevated)
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(isSelected ? Color.coachAccent : Color.coachBorder, lineWidth: 1)
            }
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(part.rawValue), \(part.formattedValue(value, weightUnit: weightUnit, lengthUnit: lengthUnit))")
    }
}

private struct BodySilhouetteView: View {
    var selectedPart: BodyMeasurementPart?

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let height = proxy.size.height

            ZStack {
                Circle()
                    .fill(Color.coachSurfaceMuted)
                    .frame(width: width * 0.42, height: width * 0.42)
                    .position(x: width / 2, y: height * 0.08)

                Capsule()
                    .fill(Color.coachSurfaceMuted)
                    .frame(width: width * 0.64, height: height * 0.34)
                    .position(x: width / 2, y: height * 0.29)

                Capsule()
                    .fill(Color.coachSurfaceMuted)
                    .frame(width: width * 0.20, height: height * 0.34)
                    .rotationEffect(.degrees(8))
                    .position(x: width * 0.20, y: height * 0.32)

                Capsule()
                    .fill(Color.coachSurfaceMuted)
                    .frame(width: width * 0.20, height: height * 0.34)
                    .rotationEffect(.degrees(-8))
                    .position(x: width * 0.80, y: height * 0.32)

                Capsule()
                    .fill(Color.coachSurfaceMuted)
                    .frame(width: width * 0.23, height: height * 0.42)
                    .position(x: width * 0.40, y: height * 0.68)

                Capsule()
                    .fill(Color.coachSurfaceMuted)
                    .frame(width: width * 0.23, height: height * 0.42)
                    .position(x: width * 0.60, y: height * 0.68)

                highlight(in: proxy.size)
            }
            .opacity(0.92)
        }
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private func highlight(in size: CGSize) -> some View {
        if let selectedPart {
            let width = size.width
            let height = size.height

            switch selectedPart {
            case .weight:
                Circle()
                    .stroke(Color.coachAccent, lineWidth: 2)
                    .frame(width: width * 0.92, height: width * 0.92)
                    .position(x: width / 2, y: height * 0.44)
            case .neck:
                Capsule()
                    .fill(Color.coachAccent)
                    .frame(width: width * 0.30, height: 5)
                    .position(x: width / 2, y: height * 0.15)
            case .shoulders:
                Capsule()
                    .fill(Color.coachAccent)
                    .frame(width: width * 0.86, height: 6)
                    .position(x: width / 2, y: height * 0.20)
            case .chest:
                Capsule()
                    .fill(Color.coachAccent)
                    .frame(width: width * 0.62, height: 18)
                    .position(x: width / 2, y: height * 0.28)
            case .waist:
                Capsule()
                    .fill(Color.coachAccent)
                    .frame(width: width * 0.56, height: 6)
                    .position(x: width / 2, y: height * 0.42)
            case .abdomen:
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.coachAccent)
                    .frame(width: width * 0.48, height: 22)
                    .position(x: width / 2, y: height * 0.36)
            case .hip:
                Capsule()
                    .fill(Color.coachAccent)
                    .frame(width: width * 0.62, height: 8)
                    .position(x: width / 2, y: height * 0.50)
            case .biceps:
                HStack(spacing: width * 0.52) {
                    Capsule()
                        .fill(Color.coachAccent)
                    Capsule()
                        .fill(Color.coachAccent)
                }
                .frame(width: width * 0.88, height: height * 0.18)
                .position(x: width / 2, y: height * 0.31)
            case .thigh:
                HStack(spacing: width * 0.10) {
                    Capsule()
                        .fill(Color.coachAccent)
                    Capsule()
                        .fill(Color.coachAccent)
                }
                .frame(width: width * 0.52, height: height * 0.22)
                .position(x: width / 2, y: height * 0.61)
            case .calf:
                HStack(spacing: width * 0.12) {
                    Capsule()
                        .fill(Color.coachAccent)
                    Capsule()
                        .fill(Color.coachAccent)
                }
                .frame(width: width * 0.48, height: height * 0.20)
                .position(x: width / 2, y: height * 0.80)
            }
        }
    }
}

private struct MeasurementWheelSheet: View {
    var part: BodyMeasurementPart
    @Binding var draft: BodyMeasurementDraft
    var weightUnit: WeightUnitPreference
    var lengthUnit: LengthUnitPreference
    var onDone: () -> Void

    private var value: Binding<Double> {
        Binding(
            get: {
                part.displayValue(
                    fromCanonical: draft.value(for: part),
                    weightUnit: weightUnit,
                    lengthUnit: lengthUnit
                )
            },
            set: {
                draft.setValue(
                    part.canonicalValue(fromDisplay: $0, weightUnit: weightUnit, lengthUnit: lengthUnit),
                    for: part
                )
            }
        )
    }

    private var unitLabel: String {
        part.unit(weightUnit: weightUnit, lengthUnit: lengthUnit)
    }

    private var displayValues: [Double] {
        part.displayValues(weightUnit: weightUnit, lengthUnit: lengthUnit)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                Text(part.formattedValue(draft.value(for: part), weightUnit: weightUnit, lengthUnit: lengthUnit))
                    .font(.system(size: 36, weight: .black, design: .rounded))
                    .contentTransition(.numericText())

                Picker(part.rawValue, selection: value) {
                    ForEach(displayValues, id: \.self) { option in
                        Text("\(option.formatted(.number.precision(.fractionLength(0...1)))) \(unitLabel)")
                            .tag(option)
                    }
                }
                .pickerStyle(.wheel)
                .frame(maxHeight: 190)

                MeasurementRulerPreview(part: part, value: value.wrappedValue)
                    .frame(height: 42)
            }
            .padding(.horizontal, 18)
            .navigationTitle(part.rawValue)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done", action: onDone)
                }
            }
        }
        .presentationDetents([.height(360)])
        .presentationBackground(Color.coachSurface)
        .preferredColorScheme(.dark)
    }
}

private struct MeasurementRulerPreview: View {
    var part: BodyMeasurementPart
    var value: Double

    var body: some View {
        GeometryReader { proxy in
            let tickCount = 25
            let spacing = proxy.size.width / CGFloat(tickCount - 1)

            ZStack(alignment: .top) {
                ForEach(0..<tickCount, id: \.self) { index in
                    Rectangle()
                        .fill(index == tickCount / 2 ? Color.coachAccent : Color.coachBorder)
                        .frame(width: index == tickCount / 2 ? 3 : 1, height: index % 5 == 0 ? 34 : 22)
                        .position(x: CGFloat(index) * spacing, y: 18)
                }

                Image(systemName: "triangle.fill")
                    .font(.caption2)
                    .foregroundStyle(Color.coachAccent)
                    .rotationEffect(.degrees(180))
                    .position(x: proxy.size.width / 2, y: 2)
            }
        }
        .accessibilityHidden(true)
    }
}

private struct BodyMetricChangePill: View {
    var change: BodyMetricChange

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(change.title)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(Color.coachSecondaryText)

            Text(change.signedDeltaText)
                .font(.caption.weight(.bold))
                .foregroundStyle(change.isPositive ? Color.freshness(.ready) : Color.coachWarm)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(CoachGradient.feedback(isPositive: change.isPositive))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke((change.isPositive ? Color.freshness(.ready) : Color.coachWarm).opacity(0.20), lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

struct BodyMetricDeltaTile: View {
    var change: BodyMetricChange

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text(change.title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.coachSecondaryText)

                Spacer()

                Image(systemName: change.isPositive ? "checkmark.circle.fill" : "arrow.triangle.2.circlepath")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(change.isPositive ? Color.freshness(.ready) : Color.coachWarm)
            }

            Text(change.signedDeltaText)
                .font(.headline)
                .foregroundStyle(change.isPositive ? Color.freshness(.ready) : Color.coachWarm)
        }
        .padding(12)
        .background(CoachGradient.feedback(isPositive: change.isPositive))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke((change.isPositive ? Color.freshness(.ready) : Color.coachWarm).opacity(0.20), lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}
