import SwiftUI

/// 登録フロー内のナビ先。text をそのまま識別子に使い、毎回 UUID は付けない。
private enum RegistrationRoute: Hashable {
    case placeResolve(String)
}

/// 登録タブの主画面。大きなテキスト入力が主役。
/// 音声は iOS キーボードのマイク（音声入力）を使う。アプリ独自の Speech 認識はしない。
struct RegistrationInputView: View {
    @EnvironmentObject private var draftStore: DraftUtteranceStore
    @FocusState private var isEditorFocused: Bool
    @State private var path = NavigationPath()
    /// 起動直後の一回だけキーボードを出す。遷移中・復帰時は触らない。
    @State private var didPerformInitialFocus = false

    private var isOnRoot: Bool {
        path.isEmpty
    }

    var body: some View {
        NavigationStack(path: $path) {
            rootContent
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
                .navigationDestination(for: RegistrationRoute.self) { route in
                    switch route {
                    case .placeResolve(let text):
                        PlaceResolveView(rawText: text) {
                            if !path.isEmpty {
                                path.removeLast()
                            }
                        }
                    }
                }
                .onAppear {
                    performInitialFocusIfNeeded()
                }
                .onChange(of: path.count) { _, newCount in
                    if newCount > 0 {
                        isEditorFocused = false
                    }
                }
        }
    }

    private var rootContent: some View {
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

            Button(action: goNext) {
                Text("次へ")
                    .font(.system(size: 22, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
            }
            .buttonStyle(.borderedProminent)
            .tint(Color("BrandAccent"))
            .disabled(draftStore.draftText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

            if !draftStore.confirmedText.isEmpty && isOnRoot {
                VStack(alignment: .leading, spacing: 8) {
                    Text("前回確定した文章")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.secondary)
                    Text(draftStore.confirmedText)
                        .font(.system(size: 20, weight: .medium))
                    Button("この文章で場所を決める") {
                        pushResolve(text: draftStore.confirmedText)
                    }
                    .font(.system(size: 17, weight: .semibold))
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
    }

    private func goNext() {
        draftStore.confirmDraft()
        let text = draftStore.confirmedText
        guard !text.isEmpty else { return }
        pushResolve(text: text)
    }

    /// キーボードを閉じてから path に積む。遷移を最優先する。
    private func pushResolve(text: String) {
        isEditorFocused = false
        // 同じ文でも再度「次へ」できるよう、いったんルートへ戻してから積む
        path = NavigationPath()
        Task { @MainActor in
            // フォーカス解除のレイアウト更新のあとに push（同時更新で destination が落ちるのを避ける）
            path.append(RegistrationRoute.placeResolve(text))
        }
    }

    private func performInitialFocusIfNeeded() {
        guard !didPerformInitialFocus, isOnRoot else { return }
        didPerformInitialFocus = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            guard isOnRoot else { return }
            isEditorFocused = true
        }
    }
}

#Preview {
    RegistrationInputView()
        .environmentObject(DraftUtteranceStore())
        .environmentObject(ReminderStore())
}
