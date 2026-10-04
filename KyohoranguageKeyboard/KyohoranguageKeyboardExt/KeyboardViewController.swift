import UIKit

/// Custom keyboard: composition / voice → optional dictionary correction → insert into host field.
final class KeyboardViewController: UIInputViewController {
    private enum KeyPage: Int {
        case hiragana = 0
        case katakana = 1
        case candidates = 2
    }

    private let store = DictionaryStore()
    private var engine = CorrectionEngine(entries: [])
    private var composition = ""
    private var correctionEnabled = true
    private var keyPage: KeyPage = .hiragana
    private var awaitingVoiceSessionId: UUID?
    private var voicePollTimer: Timer?
    private var voiceLaunchDeadline: Date?
    private var voiceBecameActiveAt: Date?
    private var aggressivePollUntil: Date?
    private var statusOverride: String?
    /// Prevents double auto-insert of the same completed voice session.
    private var lastAutoInsertedSessionId: UUID?

    private let hostVoiceHint = "協豊ランゲージアプリの「音声」から入力してください"

    private let rootStack = UIStackView()
    private let compositionLabel = UILabel()
    private let previewLabel = UILabel()
    private let correctionButton = UIButton(type: .system)
    private let micButton = UIButton(type: .system)
    private let pasteResultButton = UIButton(type: .system)
    private let pageControl = UISegmentedControl(items: ["あ", "ア", "候補"])
    private let keysScrollView = UIScrollView()
    private let keysContainer = UIStackView()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.secondarySystemBackground
        buildLayout()
        reloadDictionary()
        refreshChrome()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reloadDictionary()
        voiceBecameActiveAt = Date()
        aggressivePollUntil = Date().addingTimeInterval(8)
        refreshChrome()
        tryConsumeVoiceResult()
        startVoicePolling(interval: 0.15)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopVoicePolling()
    }

    deinit {
        voicePollTimer?.invalidate()
    }

    // MARK: - Dictionary

    private func reloadDictionary() {
        let entries = store.seedInitialEntriesIfEmpty()
        engine = store.makeEngine(from: entries)
        correctionEnabled = store.isCorrectionEnabled()
    }

    private var previewText: String {
        engine.correct(composition, enabled: correctionEnabled)
    }

    // MARK: - Layout

    private func buildLayout() {
        rootStack.axis = .vertical
        rootStack.spacing = 8
        rootStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(rootStack)

        compositionLabel.font = .systemFont(ofSize: 22, weight: .regular)
        compositionLabel.numberOfLines = 2
        compositionLabel.textAlignment = .left

        previewLabel.font = .systemFont(ofSize: 16, weight: .medium)
        previewLabel.textColor = .secondaryLabel
        previewLabel.numberOfLines = 2

        correctionButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        correctionButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 48).isActive = true
        correctionButton.layer.cornerRadius = 10
        correctionButton.clipsToBounds = true
        correctionButton.addAction(UIAction { [weak self] _ in
            self?.toggleCorrection()
        }, for: .touchUpInside)

        micButton.setTitle("🎤 音声入力", for: .normal)
        micButton.titleLabel?.font = .systemFont(ofSize: 24, weight: .bold)
        micButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 64).isActive = true
        micButton.layer.cornerRadius = 14
        micButton.clipsToBounds = true
        micButton.backgroundColor = UIColor.systemRed.withAlphaComponent(0.18)
        micButton.setTitleColor(.systemRed, for: .normal)
        micButton.addAction(UIAction { [weak self] _ in
            self?.startVoiceInput()
        }, for: .touchUpInside)

        pasteResultButton.setTitle("📋 結果を貼る", for: .normal)
        pasteResultButton.titleLabel?.font = .systemFont(ofSize: 22, weight: .bold)
        pasteResultButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 56).isActive = true
        pasteResultButton.layer.cornerRadius = 12
        pasteResultButton.clipsToBounds = true
        pasteResultButton.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.18)
        pasteResultButton.setTitleColor(.systemBlue, for: .normal)
        pasteResultButton.addAction(UIAction { [weak self] _ in
            self?.pasteLastVoiceResult()
        }, for: .touchUpInside)
        pasteResultButton.isHidden = true

        pageControl.selectedSegmentIndex = 0
        pageControl.addAction(UIAction { [weak self] _ in
            guard let self else { return }
            self.keyPage = KeyPage(rawValue: self.pageControl.selectedSegmentIndex) ?? .hiragana
            self.rebuildKeys()
        }, for: .valueChanged)

        keysContainer.axis = .vertical
        keysContainer.spacing = 6
        keysContainer.translatesAutoresizingMaskIntoConstraints = false

        keysScrollView.alwaysBounceVertical = true
        keysScrollView.showsVerticalScrollIndicator = true
        keysScrollView.addSubview(keysContainer)
        keysScrollView.heightAnchor.constraint(equalToConstant: 200).isActive = true

        NSLayoutConstraint.activate([
            keysContainer.leadingAnchor.constraint(equalTo: keysScrollView.contentLayoutGuide.leadingAnchor),
            keysContainer.trailingAnchor.constraint(equalTo: keysScrollView.contentLayoutGuide.trailingAnchor),
            keysContainer.topAnchor.constraint(equalTo: keysScrollView.contentLayoutGuide.topAnchor),
            keysContainer.bottomAnchor.constraint(equalTo: keysScrollView.contentLayoutGuide.bottomAnchor),
            keysContainer.widthAnchor.constraint(equalTo: keysScrollView.frameLayoutGuide.widthAnchor),
        ])

        rootStack.addArrangedSubview(padded(compositionLabel, height: 56))
        rootStack.addArrangedSubview(previewLabel)
        rootStack.addArrangedSubview(correctionButton)
        rootStack.addArrangedSubview(micButton)
        rootStack.addArrangedSubview(pasteResultButton)
        rootStack.addArrangedSubview(pageControl)
        rootStack.addArrangedSubview(keysScrollView)
        rootStack.addArrangedSubview(makeActionRow())

        NSLayoutConstraint.activate([
            rootStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8),
            rootStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -8),
            rootStack.topAnchor.constraint(equalTo: view.topAnchor, constant: 8),
            rootStack.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -8),
            view.heightAnchor.constraint(greaterThanOrEqualToConstant: 420),
        ])

        rebuildKeys()
    }

    private func padded(_ label: UILabel, height: CGFloat) -> UIView {
        let wrap = UIView()
        label.translatesAutoresizingMaskIntoConstraints = false
        wrap.addSubview(label)
        NSLayoutConstraint.activate([
            wrap.heightAnchor.constraint(greaterThanOrEqualToConstant: height),
            label.leadingAnchor.constraint(equalTo: wrap.leadingAnchor, constant: 10),
            label.trailingAnchor.constraint(equalTo: wrap.trailingAnchor, constant: -10),
            label.topAnchor.constraint(equalTo: wrap.topAnchor, constant: 8),
            label.bottomAnchor.constraint(equalTo: wrap.bottomAnchor, constant: -8),
        ])
        wrap.backgroundColor = UIColor.systemBackground
        wrap.layer.cornerRadius = 10
        return wrap
    }

    private func makeActionRow() -> UIStackView {
        let row = UIStackView()
        row.axis = .horizontal
        row.spacing = 8
        row.distribution = .fillEqually
        row.addArrangedSubview(makeKey("🌐", style: .secondary) { [weak self] in
            self?.advanceToNextInputMode()
        })
        row.addArrangedSubview(makeKey("スペース", style: .secondary) { [weak self] in
            self?.appendToComposition(" ")
        })
        row.addArrangedSubview(makeKey("削除", style: .destructive) { [weak self] in
            self?.deleteBackwardComposition()
        })
        row.addArrangedSubview(makeKey("確定", style: .primary) { [weak self] in
            self?.commitComposition(insertNewline: false)
        })
        row.addArrangedSubview(makeKey("改行", style: .secondary) { [weak self] in
            self?.commitComposition(insertNewline: true)
        })
        return row
    }

    private func rebuildKeys() {
        keysContainer.arrangedSubviews.forEach {
            keysContainer.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }

        let rows: [[String]]
        switch keyPage {
        case .hiragana:
            rows = [
                ["あ", "い", "う", "え", "お"],
                ["か", "き", "く", "け", "こ"],
                ["さ", "し", "す", "せ", "そ"],
                ["た", "ち", "つ", "て", "と"],
                ["な", "に", "ぬ", "ね", "の"],
                ["は", "ひ", "ふ", "へ", "ほ"],
                ["ま", "み", "む", "め", "も"],
                ["や", "ゆ", "よ", "わ", "を", "ん"],
                ["゛", "゜", "ー", "、", "。"],
            ]
        case .katakana:
            rows = [
                ["ア", "イ", "ウ", "エ", "オ"],
                ["カ", "キ", "ク", "ケ", "コ"],
                ["サ", "シ", "ス", "セ", "ソ"],
                ["タ", "チ", "ツ", "テ", "ト"],
                ["ナ", "ニ", "ヌ", "ネ", "ノ"],
                ["ハ", "ヒ", "フ", "ヘ", "ホ"],
                ["マ", "ミ", "ム", "メ", "モ"],
                ["ヤ", "ユ", "ヨ", "ワ", "ヲ", "ン"],
                ["゛", "゜", "ー", "、", "。"],
            ]
        case .candidates:
            rows = candidateRows()
        }

        for rowTitles in rows {
            let row = UIStackView()
            row.axis = .horizontal
            row.spacing = 6
            row.distribution = .fillEqually
            for title in rowTitles {
                row.addArrangedSubview(makeKey(title, style: .key) { [weak self] in
                    self?.handleCharacterKey(title)
                })
            }
            keysContainer.addArrangedSubview(row)
        }
    }

    private func candidateRows() -> [[String]] {
        let entries = store.loadEntries()
        var chips: [String] = []
        for entry in entries {
            chips.append(contentsOf: entry.misrecognitions)
            chips.append(entry.correct)
        }
        var seen = Set<String>()
        let unique = chips.filter { seen.insert($0).inserted }
        return stride(from: 0, to: unique.count, by: 3).map { start in
            Array(unique[start..<min(start + 3, unique.count)])
        }
    }

    private enum KeyStyle {
        case key, primary, secondary, destructive
    }

    private func makeKey(_ title: String, style: KeyStyle, action: @escaping () -> Void) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: style == .key ? 22 : 18, weight: .semibold)
        button.titleLabel?.adjustsFontSizeToFitWidth = true
        button.titleLabel?.minimumScaleFactor = 0.7
        button.layer.cornerRadius = 10
        button.clipsToBounds = true
        button.heightAnchor.constraint(greaterThanOrEqualToConstant: 52).isActive = true

        switch style {
        case .key:
            button.backgroundColor = UIColor.systemBackground
            button.setTitleColor(.label, for: .normal)
        case .primary:
            button.backgroundColor = UIColor.systemBlue
            button.setTitleColor(.white, for: .normal)
        case .secondary:
            button.backgroundColor = UIColor.tertiarySystemFill
            button.setTitleColor(.label, for: .normal)
        case .destructive:
            button.backgroundColor = UIColor.systemOrange.withAlphaComponent(0.25)
            button.setTitleColor(.label, for: .normal)
        }

        button.addAction(UIAction { _ in action() }, for: .touchUpInside)
        return button
    }

    // MARK: - Voice

    private func startVoiceInput() {
        reloadDictionary()
        statusOverride = nil

        // Host-first: if Full Access is off, don't pretend to wait.
        guard hasFullAccess else {
            failVoiceLaunch(message: hostVoiceHint + "（フルアクセスもオンにしてください）")
            return
        }

        let payload = VoiceBridge.beginRequest()
        awaitingVoiceSessionId = payload.sessionId
        // Fail fast if host never starts listening.
        voiceLaunchDeadline = Date().addingTimeInterval(1.5)
        statusOverride = "アプリを開いています… 開かないときは「協豊ランゲージ」アプリの「音声」へ"
        refreshChrome()
        startVoicePolling(interval: 0.15)
        aggressivePollUntil = Date().addingTimeInterval(8)
        openHostVoiceURL()
    }

    private func openHostVoiceURL() {
        let url = AppGroupConstants.voiceURL

        if openURLWithUIApplication(url) {
            return
        }

        guard let context = extensionContext else {
            failVoiceLaunch(message: hostVoiceHint)
            return
        }

        context.open(url) { [weak self] success in
            DispatchQueue.main.async {
                guard let self else { return }
                if !success {
                    self.failVoiceLaunch(message: self.hostVoiceHint)
                }
            }
        }
    }

    @discardableResult
    private func openURLWithUIApplication(_ url: URL) -> Bool {
        var responder: UIResponder? = self
        while let current = responder {
            if let application = current as? UIApplication {
                application.open(url, options: [:]) { [weak self] success in
                    DispatchQueue.main.async {
                        guard let self else { return }
                        if success {
                            self.statusOverride = "アプリで話して「完了」→ ここに戻ると文字が入ります"
                            self.refreshChrome()
                        } else {
                            self.failVoiceLaunch(message: self.hostVoiceHint)
                        }
                    }
                }
                return true
            }
            responder = current.next
        }
        return false
    }

    private func failVoiceLaunch(message: String) {
        // Do NOT wipe App Group — host may still finish and write a ready result.
        awaitingVoiceSessionId = nil
        voiceLaunchDeadline = nil
        statusOverride = message
        // Keep light polling so host-completed results still insert.
        startVoicePolling(interval: 0.2)
        refreshChrome()
    }

    private func clearVoiceWait(message: String?) {
        // UI-only clear. Never destroy a ready/last result the host already wrote.
        awaitingVoiceSessionId = nil
        voiceLaunchDeadline = nil
        statusOverride = message
        refreshChrome()
    }

    private func startVoicePolling(interval: TimeInterval) {
        stopVoicePolling()
        voicePollTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.tryConsumeVoiceResult()
        }
        if let voicePollTimer {
            RunLoop.main.add(voicePollTimer, forMode: .common)
        }
    }

    private func stopVoicePolling() {
        voicePollTimer?.invalidate()
        voicePollTimer = nil
    }

    private func tryConsumeVoiceResult() {
        // After aggressive window, slow down polling a bit.
        if let until = aggressivePollUntil, Date() > until {
            aggressivePollUntil = nil
            startVoicePolling(interval: 0.25)
        }

        let payload = VoiceBridge.load()

        // Ready session: always insert once.
        if payload.status == .ready,
           lastAutoInsertedSessionId != payload.sessionId {
            insertReadyPayload(payload)
            return
        }

        // Fresh last result: auto-insert only right after returning to the keyboard
        // (aggressive window). Later, user can tap 「結果を貼る」.
        if let last = VoiceBridge.loadLastResult(),
           lastAutoInsertedSessionId != last.sessionId,
           Date().timeIntervalSince(last.updatedAt) < 120,
           let until = aggressivePollUntil,
           Date() < until {
            lastAutoInsertedSessionId = last.sessionId
            insertTextFromVoice(raw: last.rawText, corrected: last.correctedText)
            return
        }

        if VoiceBridge.isTimedOut(payload) {
            // Timed-out working session only — keep last result if any.
            if payload.status == .requesting || payload.status == .listening {
                VoiceBridge.clearSession()
            }
            clearVoiceWait(message: hostVoiceHint)
            return
        }

        // Host never opened / never reached listening.
        if let deadline = voiceLaunchDeadline,
           Date() > deadline,
           awaitingVoiceSessionId != nil,
           payload.status == .requesting {
            failVoiceLaunch(message: hostVoiceHint)
            return
        }

        // User returned while host still listening — keep App Group intact; just guide them.
        if let awaiting = awaitingVoiceSessionId,
           payload.sessionId == awaiting,
           (payload.status == .requesting || payload.status == .listening) {
            voiceLaunchDeadline = nil
            statusOverride = "ホストで「完了」を押し、このアプリに戻ってください"
            // After a while, drop sticky mic "待機中" but keep polling for ready.
            if let appeared = voiceBecameActiveAt, Date().timeIntervalSince(appeared) > 8 {
                awaitingVoiceSessionId = nil
                statusOverride = hostVoiceHint + "（完了済みなら「結果を貼る」）"
            }
            refreshChrome()
            return
        }

        if payload.status == .listening || payload.status == .requesting {
            // Host-started session: poll quietly until ready; show paste affordance.
            refreshChrome()
            return
        }

        if payload.status == .error {
            let msg = payload.errorMessage?.isEmpty == false
                ? payload.errorMessage!
                : hostVoiceHint
            clearVoiceWait(message: msg)
            return
        }

        if payload.status == .cancelled {
            clearVoiceWait(message: nil)
        }
    }

    private func insertReadyPayload(_ payload: VoicePayload) {
        lastAutoInsertedSessionId = payload.sessionId
        insertTextFromVoice(raw: payload.rawText, corrected: payload.correctedText)
    }

    private func insertTextFromVoice(raw: String, corrected: String) {
        let trimmedRaw = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedCorrected = corrected.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedRaw.isEmpty || !trimmedCorrected.isEmpty else {
            clearVoiceWait(message: "言葉を認識できませんでした。アプリの「音声」でもう一度話してください。")
            return
        }

        reloadDictionary()
        let text: String
        if correctionEnabled {
            text = trimmedCorrected.isEmpty
                ? engine.correct(trimmedRaw, enabled: true)
                : trimmedCorrected
        } else {
            text = trimmedRaw.isEmpty ? trimmedCorrected : trimmedRaw
        }
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            clearVoiceWait(message: "言葉を認識できませんでした。アプリの「音声」でもう一度話してください。")
            return
        }

        textDocumentProxy.insertText(trimmed)
        awaitingVoiceSessionId = nil
        voiceLaunchDeadline = nil
        VoiceBridge.markInserted()
        // Keep last result so 「結果を貼る」 still works if the field did not accept insert.
        composition = ""
        statusOverride = "入りました: \(trimmed)（入っていなければ「結果を貼る」）"
        refreshChrome()
    }

    /// Manual fallback when auto-insert did not run (App Group / clipboard).
    private func pasteLastVoiceResult() {
        reloadDictionary()

        if let last = VoiceBridge.loadLastResult() {
            let text = last.textForInsert(correctionEnabled: correctionEnabled, engine: engine)
                .trimmingCharacters(in: .whitespacesAndNewlines)
            guard !text.isEmpty else { return }
            textDocumentProxy.insertText(text)
            VoiceBridge.markInserted()
            composition = ""
            statusOverride = "貼り付けました: \(text)"
            refreshChrome()
            return
        }

        let payload = VoiceBridge.load()
        if payload.status == .ready {
            insertReadyPayload(payload)
            return
        }

        if let saved = VoiceBridge.loadClipboardText() {
            textDocumentProxy.insertText(saved)
            composition = ""
            statusOverride = "貼り付けました: \(saved)"
            refreshChrome()
            return
        }

        if let clip = UIPasteboard.general.string?
            .trimmingCharacters(in: .whitespacesAndNewlines),
           !clip.isEmpty {
            textDocumentProxy.insertText(clip)
            composition = ""
            statusOverride = "貼り付けました: \(clip)"
            refreshChrome()
            return
        }

        statusOverride = "貼る結果がありません。アプリの「音声」でもう一度話して「完了」を押してください。"
        refreshChrome()
    }

    private var hasPasteableVoiceResult: Bool {
        if VoiceBridge.loadLastResult() != nil { return true }
        if VoiceBridge.load().status == .ready { return true }
        if VoiceBridge.loadClipboardText() != nil { return true }
        return false
    }

    // MARK: - Actions

    private func toggleCorrection() {
        correctionEnabled.toggle()
        store.setCorrectionEnabled(correctionEnabled)
        refreshChrome()
    }

    private func handleCharacterKey(_ title: String) {
        switch title {
        case "゛":
            applyDakuten()
        case "゜":
            applyHandakuten()
        default:
            appendToComposition(title)
        }
    }

    private func appendToComposition(_ text: String) {
        statusOverride = nil
        composition.append(text)
        refreshChrome()
    }

    private func deleteBackwardComposition() {
        statusOverride = nil
        guard !composition.isEmpty else {
            textDocumentProxy.deleteBackward()
            return
        }
        composition.removeLast()
        refreshChrome()
    }

    private func commitComposition(insertNewline: Bool) {
        let text = previewText
        if !text.isEmpty {
            textDocumentProxy.insertText(text)
        }
        if insertNewline {
            textDocumentProxy.insertText("\n")
        }
        composition = ""
        refreshChrome()
    }

    private func refreshChrome() {
        compositionLabel.text = composition.isEmpty ? "ここに入力…" : composition
        compositionLabel.textColor = composition.isEmpty ? .tertiaryLabel : .label

        if let statusOverride, !statusOverride.isEmpty {
            previewLabel.text = statusOverride
            previewLabel.textColor = statusOverride.contains("開けません") || statusOverride.contains("フルアクセス") || statusOverride.contains("エラー") || statusOverride.contains("タイムアウト")
                ? .systemOrange
                : .secondaryLabel
            previewLabel.numberOfLines = 3
        } else if composition.isEmpty {
            previewLabel.text = correctionEnabled
                ? "補正ON：確定／音声で辞書を適用します"
                : "補正OFF：入力どおり確定します"
            previewLabel.textColor = .secondaryLabel
        } else if correctionEnabled {
            let corrected = previewText
            previewLabel.text = corrected == composition
                ? "補正後: （変化なし）"
                : "補正後: \(corrected)"
            previewLabel.textColor = .secondaryLabel
        } else {
            previewLabel.text = "そのまま: \(composition)"
            previewLabel.textColor = .secondaryLabel
        }

        let on = correctionEnabled
        correctionButton.setTitle(on ? "辞書補正 ON" : "辞書補正 OFF", for: .normal)
        correctionButton.backgroundColor = on
            ? UIColor.systemGreen.withAlphaComponent(0.25)
            : UIColor.tertiarySystemFill
        correctionButton.setTitleColor(on ? .systemGreen : .label, for: .normal)

        if awaitingVoiceSessionId != nil {
            micButton.setTitle("🎤 待機中…", for: .normal)
        } else {
            micButton.setTitle("🎤 アプリで音声", for: .normal)
        }

        let canPaste = hasPasteableVoiceResult
        pasteResultButton.isHidden = !canPaste
        if canPaste {
            pasteResultButton.setTitle("📋 結果を貼る", for: .normal)
        }
    }

    // MARK: - Dakuten helpers

    private static let dakutenMap: [Character: Character] = [
        "か": "が", "き": "ぎ", "く": "ぐ", "け": "げ", "こ": "ご",
        "さ": "ざ", "し": "じ", "す": "ず", "せ": "ぜ", "そ": "ぞ",
        "た": "だ", "ち": "ぢ", "つ": "づ", "て": "で", "と": "ど",
        "は": "ば", "ひ": "び", "ふ": "ぶ", "へ": "べ", "ほ": "ぼ",
        "カ": "ガ", "キ": "ギ", "ク": "グ", "ケ": "ゲ", "コ": "ゴ",
        "サ": "ザ", "シ": "ジ", "ス": "ズ", "セ": "ゼ", "ソ": "ゾ",
        "タ": "ダ", "チ": "ヂ", "ツ": "ヅ", "テ": "デ", "ト": "ド",
        "ハ": "バ", "ヒ": "ビ", "フ": "ブ", "ヘ": "ベ", "ホ": "ボ",
        "う": "ゔ", "ウ": "ヴ",
    ]

    private static let handakutenMap: [Character: Character] = [
        "は": "ぱ", "ひ": "ぴ", "ふ": "ぷ", "へ": "ぺ", "ほ": "ぽ",
        "ハ": "パ", "ヒ": "ピ", "フ": "プ", "ヘ": "ペ", "ホ": "ポ",
    ]

    private func applyDakuten() {
        guard let last = composition.last else { return }
        if let mapped = Self.dakutenMap[last] {
            composition.removeLast()
            composition.append(mapped)
            refreshChrome()
        }
    }

    private func applyHandakuten() {
        guard let last = composition.last else { return }
        if let mapped = Self.handakutenMap[last] {
            composition.removeLast()
            composition.append(mapped)
            refreshChrome()
        }
    }
}
