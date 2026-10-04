import SwiftUI

struct DictionaryEditView: View {
    @Environment(\.dismiss) private var dismiss

    let existing: DictionaryEntry?
    var onSave: (DictionaryEntry) -> Void

    @State private var correct: String = ""
    @State private var reading: String = ""
    @State private var newCandidate: String = ""
    @State private var bulkText: String = ""
    @State private var candidates: [String] = []

    var body: some View {
        Form {
            Section("正解語") {
                TextField("例: 金古", text: $correct)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }

            Section("読み") {
                TextField("例: かねこ", text: $reading)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }

            Section("誤認識候補") {
                ForEach(candidates, id: \.self) { item in
                    HStack {
                        Text(item)
                        Spacer()
                        Button("削除", role: .destructive) {
                            candidates.removeAll { $0 == item }
                        }
                    }
                }

                HStack {
                    TextField("候補を追加（例: 金子）", text: $newCandidate)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    Button("追加") {
                        addCandidate(newCandidate)
                        newCandidate = ""
                    }
                    .disabled(newCandidate.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }

            Section {
                TextField("金子、カネコ、かねこ", text: $bulkText, axis: .vertical)
                    .lineLimit(2...4)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                Button("一括で取り込む") {
                    importBulk()
                }
                .disabled(bulkText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            } header: {
                Text("一括追加")
            } footer: {
                Text("長い語（金子町）が短い語（金子）より優先して置換されます。")
            }
        }
        .navigationTitle(existing == nil ? "単語を追加" : "単語を編集")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("キャンセル") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("保存") { save() }
                    .disabled(correct.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .onAppear(perform: load)
    }

    private func load() {
        guard let existing else { return }
        correct = existing.correct
        reading = existing.reading
        candidates = existing.misrecognitions
    }

    private func addCandidate(_ raw: String) {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        if !candidates.contains(trimmed) {
            candidates.append(trimmed)
        }
    }

    private func importBulk() {
        let parsed = DictionaryEntry.normalizedList(
            bulkText.split(whereSeparator: { $0 == "," || $0 == "、" || $0 == "\n" }).map(String.init)
        )
        for item in parsed {
            addCandidate(item)
        }
        bulkText = ""
    }

    private func save() {
        var entry = existing ?? DictionaryEntry(correct: "", reading: "")
        entry.correct = correct.trimmingCharacters(in: .whitespacesAndNewlines)
        entry.reading = reading.trimmingCharacters(in: .whitespacesAndNewlines)
        entry.misrecognitions = DictionaryEntry.normalizedList(candidates)
        entry.updatedAt = Date()
        onSave(entry)
        dismiss()
    }
}
