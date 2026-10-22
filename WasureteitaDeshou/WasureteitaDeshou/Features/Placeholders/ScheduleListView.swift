import SwiftUI

/// 第3〜4段階で本実装。第1段階はナビ枠のみ。
struct ScheduleListView: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView {
                Label("予定一覧", systemImage: "list.bullet")
            } description: {
                Text("登録した用事がここに並びます。\n編集・削除・手動完了は第3〜4段階で実装します。")
                    .font(.system(size: 18))
                    .multilineTextAlignment(.center)
            }
            .navigationTitle("予定一覧")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

#Preview {
    ScheduleListView()
}
