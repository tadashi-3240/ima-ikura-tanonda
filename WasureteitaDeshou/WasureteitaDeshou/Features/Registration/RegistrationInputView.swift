import SwiftUI

private enum RegistrationStep: Equatable {
    case input
    case resolve(String)
}

/// 登録タブの主画面。大きなテキスト入力が主役。
/// 音声は iOS キーボードのマイク（音声入力）を使う。アプリ独自の Speech 認識はしない。
/// 「次へ」は cover / sheet / NavigationPath を使わず、同じタブ内でステップ切替する。
struct RegistrationInputView: View {
    @EnvironmentObject private var draftStore: DraftUtteranceStore
    @EnvironmentObject private var reminderStore: ReminderStore
    @FocusState private var isEditorFocused: Bool
    @State private var step: RegistrationStep = .input
    /// 起動直後の一回だけキーボードを出す。resolve 表示中は触らない。
    @State private var didPerformInitialFocus = false

    var body: some View {
        NavigationStack {
            Group {
                switch step {
                case .input:
                    inputContent
                case .resolve(let text):
                    PlaceResolveView(rawText: text) {
                        step = .input
                    }
                }
            }
            .navigationTitle(step == .input ? "忘れていたでしょう" : "内容の確認")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                if case .resolve = step {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("戻る") {
                            isEditorFocused = false
                            step = .input
                        }
                        .font(.system(size: 17))
                    }
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("完了") {
                        isEditorFocused = false
                    }
                    .font(.system(size: 17, weight: .semibold))
                }
            }
        }
        .onAppear {
            performInitialFocusIfNeeded()
        }
        .onChange(of: step) { _, newStep in
            if case .resolve = newStep {
                isEditorFocused = false
            }
        }
    }

    private var inputContent: some View {
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

            if !draftStore.confirmedText.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("前回確定した文章")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.secondary)
                    Text(draftStore.confirmedText)
                        .font(.system(size: 20, weight: .medium))
                    Button("この文章で場所を決める") {
                        isEditorFocused = false
                        step = .resolve(draftStore.confirmedText)
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

    /// disabled 以外では return せず、必ず resolve ステップへ進む。
    private func goNext() {
        draftStore.confirmDraft()
        isEditorFocused = false
        let trimmed = draftStore.confirmedText
        step = .resolve(trimmed)
    }

    private func performInitialFocusIfNeeded() {
        guard !didPerformInitialFocus else { return }
        guard case .input = step else { return }
        didPerformInitialFocus = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            guard case .input = step else { return }
            isEditorFocused = true
        }
    }
}

#Preview {
    RegistrationInputView()
        .environmentObject(DraftUtteranceStore())
        .environmentObject(ReminderStore())
}
