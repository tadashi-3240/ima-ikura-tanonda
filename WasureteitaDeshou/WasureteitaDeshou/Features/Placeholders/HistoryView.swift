import SwiftUI

/// 第4段階で本実装。第1段階はナビ枠のみ。
struct HistoryView: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView {
                Label("履歴", systemImage: "clock.arrow.circlepath")
            } description: {
                Text("完了した用事の履歴がここに残ります。\nワンタップ再登録は第4段階で実装します。")
                    .font(.system(size: 18))
                    .multilineTextAlignment(.center)
            }
            .navigationTitle("履歴")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

#Preview {
    HistoryView()
}
