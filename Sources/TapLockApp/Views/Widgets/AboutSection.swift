import SwiftUI

struct AboutSection: View {
    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 4) {
                Text("Built with")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary.opacity(0.5))
                Text("❤️")
                    .font(.system(size: 9))
                Text("for")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary.opacity(0.5))
                Image(systemName: "laptopcomputer")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary.opacity(0.5))
                Text("users")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary.opacity(0.5))
            }

            HStack(spacing: 5) {
                Link(destination: URL(string: "https://github.com/ugurcandede")!) {
                    Text("ugurcandede")
                        .font(.system(size: 10, weight: .medium))
                }

                Text("·")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary.opacity(0.3))

                Link(destination: URL(string: "https://github.com/ugurcandede/taplock-app")!) {
                    HStack(spacing: 3) {
                        Image(systemName: "tag")
                            .font(.system(size: 8))
                        Text(
                            "v\(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ".dev")"
                        )
                            .font(.system(size: 10))
                    }
                }
            }
        }
        .padding(.vertical, 10)
    }
}
