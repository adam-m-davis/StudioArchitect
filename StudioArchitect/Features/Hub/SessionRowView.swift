import SwiftUI

struct SessionRowView: View {
    let session: Session

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        return f
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(session.name)
                        .font(.headline)
                    Text(session.type.displayName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(Self.dateFormatter.string(from: session.shootDate))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            StageProgressView(stage: session.currentStage)
        }
        .padding(.vertical, 4)
    }
}

struct StageProgressView: View {
    let stage: Session.SessionStage

    private let stages = Session.SessionStage.allCases

    var body: some View {
        HStack(spacing: 4) {
            ForEach(stages, id: \.self) { s in
                Capsule()
                    .fill(s.stepIndex <= stage.stepIndex ? Color.accentColor : Color.secondary.opacity(0.2))
                    .frame(height: 4)
            }
        }
    }
}
