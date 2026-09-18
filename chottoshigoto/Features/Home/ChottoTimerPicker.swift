import SwiftUI
import UIKit

struct ChottoTimerPicker: View {
    @Binding var selectedMinutes: Int

    let minimumMinutes = 1
    let maximumMinutes = 180

    private let pointsPerMinute: CGFloat = 14
    private let containerHeight: CGFloat = 140

    @State private var lastHapticMinute: Int = 0

    private var minuteOffset: CGFloat {
        CGFloat(selectedMinutes - minimumMinutes) * pointsPerMinute
    }

    var body: some View {
        VStack(spacing: 0) {
            // Ruler area
            GeometryReader { geometry in
                let centerX = geometry.size.width / 2

                ZStack {
                    // Tick marks (scrollable content)
                    HStack(spacing: 0) {
                        ForEach(minimumMinutes...maximumMinutes, id: \.self) { minute in
                            TickMark(
                                minute: minute,
                                isSelected: minute == selectedMinutes
                            )
                            .frame(width: pointsPerMinute)
                        }
                    }
                    .offset(x: centerX - minuteOffset - pointsPerMinute / 2)

                    // Fixed center indicator
                    VStack(spacing: 0) {
                        Triangle()
                            .fill(Color.chottoSage)
                            .frame(width: 10, height: 7)
                        Rectangle()
                            .fill(Color.chottoSage)
                            .frame(width: 2, height: 10)
                    }
                    .position(x: centerX, y: containerHeight - 16)

                    // Left fade
                    LinearGradient(
                        colors: [Color.chottoCream, .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: 50)
                    .allowsHitTesting(false)

                    // Right fade
                    LinearGradient(
                        colors: [Color.chottoCream, .clear],
                        startPoint: .trailing,
                        endPoint: .leading
                    )
                    .frame(width: 50)
                    .position(x: geometry.size.width - 25, y: 0)
                    .allowsHitTesting(false)
                }
                .frame(height: containerHeight)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 1)
                        .onChanged { value in
                            let delta = -value.translation.width / pointsPerMinute
                            let minuteDelta = Int(round(delta))
                            let proposed = min(
                                max(selectedMinutes + minuteDelta, minimumMinutes),
                                maximumMinutes
                            )
                            if proposed != selectedMinutes {
                                triggerHaptic(for: proposed)
                                selectedMinutes = proposed
                            }
                        }
                        .onEnded { _ in
                            let haptic = UIImpactFeedbackGenerator(style: .light)
                            haptic.impactOccurred()
                        }
                )
            }
            .frame(height: containerHeight)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Focus duration")
        .accessibilityValue("\(selectedMinutes) minutes")
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment:
                selectedMinutes = min(selectedMinutes + 1, maximumMinutes)
            case .decrement:
                selectedMinutes = max(selectedMinutes - 1, minimumMinutes)
            @unknown default:
                break
            }
        }
    }

    private func triggerHaptic(for minute: Int) {
        if minute != lastHapticMinute {
            lastHapticMinute = minute
            let generator = UISelectionFeedbackGenerator()
            generator.selectionChanged()
        }
    }
}

// MARK: - Tick Mark

private struct TickMark: View {
    let minute: Int
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 0) {
            if minute % 5 == 0 {
                // Major tick with label
                Text("\(minute)")
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundStyle(isSelected ? Color.chottoSageDeep : .secondary)
                    .frame(height: 14)

                Rectangle()
                    .fill(isSelected ? Color.chottoSageDeep : Color.chottoCharcoal.opacity(0.6))
                    .frame(width: 2, height: 32)
            } else if minute % 15 == 0 {
                // Medium tick
                Rectangle()
                    .fill(isSelected ? Color.chottoSageDeep : Color.chottoCharcoal.opacity(0.4))
                    .frame(width: 1.5, height: 24)
                    .padding(.top, 14 + 8)
            } else {
                // Small tick
                Rectangle()
                    .fill(isSelected ? Color.chottoSageDeep : Color.chottoCharcoal.opacity(0.25))
                    .frame(width: 1, height: 12)
                    .padding(.top, 14 + 20)
            }
        }
        .frame(width: 20)
    }
}

// MARK: - Triangle

private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State var minutes: Int = 25
        var body: some View {
            ChottoTimerPicker(selectedMinutes: $minutes)
                .padding()
                .background(Color.chottoCream)
        }
    }
    return PreviewWrapper()
}
