import SwiftUI

/// 登録タブの主画面。大きなテキスト入力が主役。
/// 音声は iOS キーボードのマイク（音声入力）を使う。アプリ独自の Speech 認識はしない。
struct RegistrationInputView: View {
    @EnvironmentObject private var draftStore: DraftUtteranceStore
    @FocusState private var isEditorFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                Text("用事を入力")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(.secondary)

                Text("キーボードのマイクから話して入力できます。例：金古のセブンイレブンで牛乳を買う")
                    .font(.system(size: 17))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                ZStack(alignment: .topLeading) {
                    if draftStore.draftText.isEmpty {
                        Text("ここに入力してください")
                            .font(.system(size: 24))
                            .foregroundStyle(.tertiary)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 20)
                            .allowsHitTesting(false)
                    }

                    TextEditor(text: $draftStore.draftText)
                        .font(.system(size: 24))
                        .scrollContentBackground(.hidden)
                        .padding(12)
                        .focused($isEditorFocused)
                        .frame(minHeight: 200, maxHeight: 280)
                        .accessibilityLabel("用事の入力欄")
                }
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color(.secondarySystemBackground))
                )

                Button(action: confirm) {
                    Text("次へ")
                        .font(.system(size: 22, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                }
                .buttonStyle(.borderedProminent)
                .tint(Color("BrandAccent"))
                .disabled(draftStore.draftText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                if !draftStore.confirmedText.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("確定した文章")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.secondary)
                        Text(draftStore.confirmedText)
                            .font(.system(size: 22, weight: .medium))
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text("場所と用事の解析・地図検索はこれから追加します。")
                            .font(.system(size: 15))
                            .foregroundStyle(.tertiary)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color(.tertiarySystemBackground))
                    )
                }

                Spacer(minLength: 0)
            }
            .padding(24)
            .navigationTitle("忘れていたでしょう")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("完了") {
                        isEditorFocused = false
                    }
                    .font(.system(size: 17, weight: .semibold))
                }
            }
            .onAppear {
                // 起動後に入力欄へフォーカスし、キーボード（マイク）を出しやすくする
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                    isEditorFocused = true
                }
            }
        }
    }

    private func confirm() {
        draftStore.confirmDraft()
        isEditorFocused = false
    }
}

#Preview {
    RegistrationInputView()
        .environmentObject(DraftUtteranceStore())
}
