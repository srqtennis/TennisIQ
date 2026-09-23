import SwiftUI

struct AboutView: View {
    @EnvironmentObject var purchases: PurchaseStore
    var body: some View {
        List {
            Section("Tennis IQ") {
                Text("Learn the rules, explore tennis history and test your knowledge. Answers include explanations so every round teaches you something.")
                Text("Version \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")")
                    .foregroundStyle(.secondary)
            }
            Section("Help") {
                Text("Daily Rally gives you ten mixed questions. Shot Clock adds a twenty second limit to each answer. Browse the Library to learn at your own pace.")
                Text("For help or to report a question, email michael@srq.tennis. Include the question text and what you think needs correcting.")
                Link("Support website", destination: URL(string: "https://srq.tennis/tennis-iq/support/")!)
                Link("Email support", destination: URL(string: "mailto:michael@srq.tennis?subject=Tennis%20IQ%20support")!)
            }
            Section("Purchases") {
                Text("Daily Rally is free forever. One optional purchase unlocks Shot Clock, Practice, the full Library, local knowledge ratings and badges, result cards and friendly challenge links. There is no subscription.")
                Button("Restore Purchases") { Task { await purchases.restore() } }
                    .disabled(purchases.isLoading)
                    .accessibilityIdentifier("restore-purchases")
                if let message = purchases.message { Text(message).foregroundStyle(.secondary) }
            }
            Section {
                NavigationLink("Privacy policy") { PrivacyView() }
                Link("Privacy policy online", destination: URL(string: "https://srq.tennis/tennis-iq/privacy/")!)
            }
            Section("Independent tennis knowledge") {
                Text("Tennis IQ is an independent quiz app. It is not affiliated with or endorsed by the ITF, ATP, WTA or Grand Slam tournaments. Coaching tips depend on the situation; historical records use the cutoff stated in each question.")
            }
        }
        .navigationTitle("About & Support")
    }
}

struct PrivacyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Tennis IQ Privacy Policy").font(.title2.bold())
                Text("Tennis IQ works without an account. The app does not send your scores or gameplay to us and does not include advertising, tracking or third party analytics.")
                Text("Stored on your device").font(.headline)
                Text("Your scores, completed rounds, answer history, knowledge rating and earned badges are saved in the app’s local storage. Apple’s device backup services may include this data according to your device settings. Deleting the app, rather than offloading it, removes its local data; restoring a backup may restore that data.")
                Text("If you contact support").font(.headline)
                Text("If you email michael@srq.tennis, we receive your email address and the information you choose to include. We use this information to respond and resolve your request. Email is handled by our email provider. Do not send sensitive information. You can ask us to delete support correspondence, subject to any legal retention requirements.")
                Text("Sharing and challenges").font(.headline)
                Text("Result cards contain the round result and your local knowledge rating. Challenge links contain question identifiers and a version check, not your name or answers. Nothing is sent automatically. If you choose to share, the recipient and sharing service receive what you send under their own policies.")
                Text("Purchases").font(.headline)
                Text("Apple processes the optional in-app purchase. We do not receive your payment card details. The app uses Apple’s verified purchase information to unlock paid features and restore access. Apple handles purchase information under its own privacy policy.")
                Text("Your choices").font(.headline)
                Text("No personal information is required to play. We do not sell gameplay data or use it for advertising. These practices apply to all players, including children. A parent or guardian can contact us about a child’s support correspondence.")
                Text("Changes and contact").font(.headline)
                Text("If the app’s data practices change, we will update this policy. Questions about privacy can be sent to michael@srq.tennis.")
            }
            .padding(20)
        }
        .navigationTitle("Privacy")
        .navigationBarTitleDisplayMode(.inline)
    }
}
