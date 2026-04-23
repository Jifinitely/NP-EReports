import SwiftUI

extension Color {
    static let npBrandYellow = Color(red: 1.0, green: 0.88, blue: 0.0)
    static let npBackground = Color(uiColor: .systemGroupedBackground)
    static let npSurface = Color(uiColor: .systemBackground)
    static let npSecondarySurface = Color(uiColor: .secondarySystemBackground)
    static let npFieldSurface = Color(uiColor: .tertiarySystemBackground)
}

struct BrandHeaderView: View {
    let title: String

    var body: some View {
        Rectangle()
            .fill(Color.npBrandYellow)
            .frame(height: 54)
            .overlay(
                HStack {
                    BrandLogoView()
                        .padding(.leading, 10)
                    Spacer()
                    Text(title)
                        .font(.title2.bold())
                        .foregroundColor(.black)
                        .padding(.trailing, 24)
                }
            )
    }
}

struct BrandLogoView: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white)

            Image("NPContractingLogo")
                .resizable()
                .interpolation(.high)
                .scaledToFit()
                .padding(.horizontal, 6)
                .padding(.vertical, 4)
        }
        .frame(width: 126, height: 44)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}
