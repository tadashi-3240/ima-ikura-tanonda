import SwiftUI

/// fullScreenCover(item:) 用。表示のたびに新しい id で確実に開く（中身の text が本体）。
private struct ResolvePresentation: Identifiable {
    let id: UUID
    let text: String

    init(text: String) {
        self.id = UUID()
        self.text = text
    }
}

/// 登録タブの主画面。大きなテキスト入力が主役。
/// 音声は iOS キーボードのマイク（音声入力）を使う。アプリ独自の Speech 認識はしない。
/// 「次へ」は TabView 内 NavigationStack push ではなく fullScreenCover で出す（実機で push が不安定なため）。
struct RegistrationInputView: View {
    @EnvironmentObject private var draftStore: DraftUtteranceStore
    @FocusState private var isEditorFocused: Bool
    @State private var presentedResolve: ResolvePresentation?
    /// 起動直後の一回だけキーボードを出す。cover 表示中は触らない。
    @State private var didPerformInitialFocus = false

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

                Button(action: goNext) {
                    Text("次へ")
                        .font(.system(size: 22, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                }
                .buttonStyle(.borderedProminent)
                .tint(Color("BrandAccent"))
                .disabled(draftStore.draftText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                if !draftStore.confirmedText.isEmpty && presentedResolve == nil {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("前回確定した文章")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.secondary)
                        Text(draftStore.confirmedText)
                            .font(.system(size: 20, weight: .medium))
                        Button("この文章で場所を決める") {
                            presentResolve(text: draftStore.confirmedText)
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
                performInitialFocusIfNeeded()
            }
        }
        .fullScreenCover(item: $presentedResolve) { presentation in
            NavigationStack {
                PlaceResolveView(rawText: presentation.text) {
                    presentedResolve = nil
                }
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("閉じる") {
                            presentedResolve = nil
                        }
                        .font(.system(size: 17))
                    }
                }
            }
        }
    }

    private func goNext() {
        draftStore.confirmDraft()
        let text = draftStore.confirmedText
        guard !text.isEmpty else { return }
        presentResolve(text: text)
    }

    private func presentResolve(text: String) {
        isEditorFocused = false
        presentedResolve = ResolvePresentation(text: text)
    }

    private func performInitialFocusIfNeeded() {
        guard !didPerformInitialFocus, presentedResolve == nil else { return }
        didPerformInitialFocus = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            guard presentedResolve == nil else { return }
            isEditorFocused = true
        }
    }
}

#Preview {
    RegistrationInputView()
        .environmentObject(DraftUtteranceStore())
        .environmentObject(ReminderStore())
}
