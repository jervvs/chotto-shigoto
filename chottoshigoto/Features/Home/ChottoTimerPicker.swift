import SwiftUI

struct ChottoTimerPicker: View {
    @Binding var selectedMinutes: Int

    let minimumMinutes = 1
    let maximumMinutes = 180

    private let tickWidth: CGFloat = 14
    private let containerHeight: CGFloat = 140

    @State private var scrollPosition: Int = 25

    var body: some View {
        VStack(spacing: 0) {
            GeometryReader { geometry in
                let centerX = geometry.size.width / 2

                ScrollViewReader { proxy in
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 0) {
                            ForEach(minimumMinutes...maximumMinutes, id: \.self) { minute in
                                TickMark(
                                    minute: minute,
                                    isSelected: minute == scrollPosition
                                )
                                .frame(width: tickWidth)
                                .id(minute)
                            }
                        }
                        .scrollTargetLayout()
                    }
                    .scrollPosition(id: Binding(
                        get: { scrollPosition },
                        set: { if let v = $0 { scrollPosition = v } }
                    ))
                    .scrollTargetBehavior(.viewAligned)
                    .scrollBounceBehavior(.basedOnSize)
                    .safeAreaPadding(.horizontal, centerX - tickWidth / 2)
                    .sensoryFeedback(.selection, trigger: scrollPosition)
                    .overlay(alignment: .bottom) {
                        VStack(spacing: 0) {
                            Triangle()
                                .fill(Color.chottoSage)
                                .frame(width: 10, height: 7)
                            Rectangle()
                                .fill(Color.chottoSage)
                                .frame(width: 2, height: 10)
                        }
                        .offset(y: -8)
                        .allowsHitTesting(false)
                    }
                    .overlay(alignment: .leading) {
                        LinearGradient(
                            colors: [Color.chottoCream, .clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(width: 50)
                        .allowsHitTesting(false)
                    }
                    .overlay(alignment: .trailing) {
                        LinearGradient(
                            colors: [Color.chottoCream, .clear],
                            startPoint: .trailing,
                            endPoint: .leading
                        )
                        .frame(width: 50)
                        .allowsHitTesting(false)
                    }
                    .onAppear {
                        proxy.scrollTo(selectedMinutes, anchor: .center)
                    }
                }
            }
            .frame(height: containerHeight)
            .clipped()
        }
        .onChange(of: scrollPosition) { _, newValue in
            selectedMinutes = newValue
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Focus duration")
        .accessibilityValue("\(selectedMinutes) minutes")
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment:
                scrollPosition = min(scrollPosition + 1, maximumMinutes)
            case .decrement:
                scrollPosition = max(scrollPosition - 1, minimumMinutes)
            @unknown default:
                break
            }
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
