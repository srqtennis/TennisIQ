import SwiftUI

/// Renders a local image; ShareLink leaves destination and sending to the user.
@MainActor
struct ResultShareView: View {
    let summary: RoundSummary
    let rating: Int
    let isProvisional: Bool
    @State private var renderedImage: Image?
    @State private var renderFailed = false

    var body: some View {
        VStack(spacing: 12) {
            if let renderedImage {
                renderedImage
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 320)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .accessibilityLabel("Result card: \(summary.correct) of \(summary.total) correct. Knowledge rating \(rating) out of 100\(isProvisional ? ", provisional" : "").")
                ShareLink(item: renderedImage,
                          preview: SharePreview("My Tennis IQ result", image: renderedImage)) {
                    Label("Share result card", systemImage: "square.and.arrow.up")
                }
                .buttonStyle(.borderedProminent)
                .tint(Color(red: 0.89, green: 0.76, blue: 0.42))
                .foregroundStyle(.black)
                .accessibilityIdentifier("share-result-card")
            } else if renderFailed {
                Button("Try preparing share card again", action: renderCard)
                    .accessibilityIdentifier("share-result-card")
            } else {
                ProgressView("Preparing result card")
            }
        }
        .task(id: "\(summary.id)-\(rating)-\(isProvisional)") { renderCard() }
    }

    private func renderCard() {
        let renderer = ImageRenderer(content: ResultCardArtwork(
            correct: summary.correct, total: summary.total, mode: summary.mode,
            rating: rating, isProvisional: isProvisional)
            .environment(\.colorScheme, .dark)
            .environment(\.dynamicTypeSize, .medium))
        renderer.scale = 3 // Fixed 360-point canvas exports at 1080 × 1080 pixels.
        renderer.isOpaque = true
        if let bitmap = renderer.uiImage {
            renderedImage = Image(uiImage: bitmap)
            renderFailed = false
        } else {
            renderedImage = nil
            renderFailed = true
        }
    }
}

private struct ResultCardArtwork: View {
    let correct: Int
    let total: Int
    let mode: String
    let rating: Int
    let isProvisional: Bool

    private let forest = Color(red: 10 / 255, green: 31 / 255, blue: 20 / 255)
    private let gold = Color(red: 0.89, green: 0.76, blue: 0.42)
    private let lime = Color(red: 0.85, green: 0.91, blue: 0.25)
    private var accuracy: Int { total > 0 ? correct * 100 / total : 0 }
    private var modeName: String {
        switch mode {
        case "rally": "Daily Rally"
        case "timed": "Shot Clock"
        case "practice": "Practice"
        case "placement": "Placement"
        case "challenge": "Friendly Challenge"
        default: "Tennis knowledge round"
        }
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                Image("BrandMark")
                    .resizable().scaledToFit().frame(width: 34, height: 34)
                Text("Tennis IQ").font(.system(size: 23, weight: .bold))
                Spacer()
                Image(systemName: "checkmark.seal.fill").foregroundStyle(lime)
            }
            Text(modeName.uppercased())
                .font(.system(size: 12, weight: .semibold)).tracking(2).foregroundStyle(gold)
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text("\(correct)").font(.system(size: 76, weight: .bold, design: .rounded))
                Text("/ \(total)").font(.system(size: 34, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.7))
            }
            .lineLimit(1).minimumScaleFactor(0.6)
            Text("\(accuracy)% accuracy · Questions answered correctly")
                .font(.system(size: 12, weight: .medium))
            Rectangle().fill(gold.opacity(0.4)).frame(height: 1)
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("KNOWLEDGE RATING").font(.system(size: 10, weight: .bold)).tracking(1)
                    Text(isProvisional ? "Provisional · Still building" : "Based on quiz performance")
                        .font(.system(size: 10)).foregroundStyle(.white.opacity(0.7))
                }
                Spacer()
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text("\(rating)").font(.system(size: 32, weight: .bold, design: .rounded))
                    Text("/100").font(.system(size: 12, weight: .semibold))
                }
                .foregroundStyle(gold)
            }
            Text("Know the court. Win the argument.")
                .font(.system(size: 11, weight: .medium)).foregroundStyle(lime)
        }
        .foregroundStyle(.white)
        .padding(24)
        .frame(width: 360, height: 360)
        .background(forest)
        .overlay { RoundedRectangle(cornerRadius: 22).strokeBorder(gold.opacity(0.35), lineWidth: 1).padding(8) }
    }
}

#Preview("Result share card") {
    ResultCardArtwork(correct: 8, total: 10, mode: "rally", rating: 74, isProvisional: true)
}
