import SwiftUI

struct WheelDoublePickerButton: View {
    var title: String
    var unit: String
    var values: [Double]
    @Binding var value: Double

    @State private var isPresented = false

    var body: some View {
        Button {
            isPresented = true
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.caption)
                        .foregroundStyle(Color.coachSecondaryText)

                    Text("\(value.formatted(.number.precision(.fractionLength(0...1)))) \(unit)")
                        .font(.headline)
                        .foregroundStyle(.primary)
                }

                Spacer()

                Image(systemName: "chevron.up.chevron.down")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.coachSecondaryText)
            }
            .padding(12)
            .frame(maxWidth: .infinity, minHeight: 64)
            .background(Color.coachSurfaceElevated)
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(Color.coachBorder, lineWidth: 1)
            }
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $isPresented) {
            NavigationStack {
                Picker(title, selection: $value) {
                    ForEach(values, id: \.self) { option in
                        Text("\(option.formatted(.number.precision(.fractionLength(0...1)))) \(unit)")
                            .tag(option)
                    }
                }
                .pickerStyle(.wheel)
                .navigationTitle(title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") {
                            isPresented = false
                        }
                    }
                }
            }
            .presentationDetents([.height(320)])
            .presentationBackground(Color.coachSurface)
            .preferredColorScheme(.dark)
        }
    }
}

struct WheelIntPickerButton: View {
    var title: String
    var unit: String
    var values: [Int]
    @Binding var value: Int

    @State private var isPresented = false

    var body: some View {
        Button {
            isPresented = true
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.caption)
                        .foregroundStyle(Color.coachSecondaryText)

                    Text("\(value) \(unit)")
                        .font(.headline)
                        .foregroundStyle(.primary)
                }

                Spacer()

                Image(systemName: "chevron.up.chevron.down")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.coachSecondaryText)
            }
            .padding(12)
            .frame(maxWidth: .infinity, minHeight: 64)
            .background(Color.coachSurfaceElevated)
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(Color.coachBorder, lineWidth: 1)
            }
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $isPresented) {
            NavigationStack {
                Picker(title, selection: $value) {
                    ForEach(values, id: \.self) { option in
                        Text("\(option) \(unit)")
                            .tag(option)
                    }
                }
                .pickerStyle(.wheel)
                .navigationTitle(title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") {
                            isPresented = false
                        }
                    }
                }
            }
            .presentationDetents([.height(320)])
            .presentationBackground(Color.coachSurface)
            .preferredColorScheme(.dark)
        }
    }
}
