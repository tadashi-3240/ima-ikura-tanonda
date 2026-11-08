import SwiftUI

struct DictionaryListView: View {
    @ObservedObject var viewModel: DictionaryViewModel
    @State private var editingEntry: DictionaryEntry?
    @State private var isAdding = false
    @State private var showResetConfirm = false

    var body: some View {
        List {
            if let status = viewModel.statusMessage {
                Section {
                    Text(status)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }

            Section {
                ForEach(viewModel.filteredEntries) { entry in
                    Button {
                        editingEntry = entry
                    } label: {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(entry.correct)
                                .font(.title3.weight(.semibold))
                                .foregroundStyle(.primary)
                            Text("読み: \(entry.reading)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            if !entry.misrecognitions.isEmpty {
                                Text("誤認識: \(entry.displayMisrecognitions)")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                .onDelete(perform: viewModel.delete)
            } header: {
                Text("協豊専用辞書（\(viewModel.filteredEntries.count)件）")
            } footer: {
                Text("ホストで保存すると App Group 経由でキーボードに反映されます。キーボードは再表示で読み直します。フルアクセスを許可してください。")
            }
        }
        .navigationTitle("辞書")
        .searchable(text: $viewModel.searchText, prompt: "正解・読み・誤認識で検索")
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("初期化") { showResetConfirm = true }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    isAdding = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("単語を追加")
            }
        }
        .sheet(isPresented: $isAdding) {
            NavigationStack {
                DictionaryEditView(existing: nil) { entry in
                    viewModel.save(entry)
                }
            }
        }
        .sheet(item: $editingEntry) { entry in
            NavigationStack {
                DictionaryEditView(existing: entry) { updated in
                    viewModel.save(updated)
                }
            }
        }
        .confirmationDialog("初期辞書に戻しますか？", isPresented: $showResetConfirm, titleVisibility: .visible) {
            Button("初期辞書に戻す", role: .destructive) {
                viewModel.resetToSeed()
            }
            Button("キャンセル", role: .cancel) {}
        }
        .onAppear { viewModel.reload() }
    }
}
