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

    private let rootStack = UIStackView()
    private let compositionLabel = UILabel()
    private let previewLabel = UILabel()
    private let correctionButton = UIButton(type: .system)
    private let micButton = UIButton(type: .system)
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
        refreshChrome()
        tryConsumeVoiceResult()
        if awaitingVoiceSessionId != nil {
            startVoicePolling()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Keep polling briefly is unnecessary off-screen; restart on appear.
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
        let payload = VoiceBridge.beginRequest()
        awaitingVoiceSessionId = payload.sessionId
        previewLabel.text = "音声アプリを開いています… 完了後、ここに戻ると文字が入ります"
        startVoicePolling()
        openHostVoiceURL()
    }

    private func openHostVoiceURL() {
        let url = AppGroupConstants.voiceURL
        // Public API for extensions.
        extensionContext?.open(url) { [weak self] success in
            DispatchQueue.main.async {
                if !success {
                    self?.openURLViaResponderChain(url)
                }
            }
        }
        // Also try responder-chain openURL (still uses UIApplication.open publicly via the system).
        openURLViaResponderChain(url)
    }

    private func openURLViaResponderChain(_ url: URL) {
        var responder: UIResponder? = self
        let selector = sel_registerName("openURL:")
        while let current = responder {
            if current.responds(to: selector) {
                current.perform(selector, with: url)
                return
            }
            responder = current.next
        }
    }

    private func startVoicePolling() {
        stopVoicePolling()
        voicePollTimer = Timer.scheduledTimer(withTimeInterval: 0.35, repeats: true) { [weak self] _ in
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
        let payload = VoiceBridge.load()

        if let awaiting = awaitingVoiceSessionId,
           payload.sessionId == awaiting,
           payload.status == .listening || payload.status == .requesting {
            previewLabel.text = "音声入力中… ホストで「完了」を押し、このアプリに戻ってください"
            return
        }

        guard payload.status == .ready else {
            if payload.status == .error {
                previewLabel.text = "音声エラー: \(payload.errorMessage ?? "不明")"
                if awaitingVoiceSessionId != nil {
                    awaitingVoiceSessionId = nil
                    stopVoicePolling()
                    VoiceBridge.clear()
                }
            } else if payload.status == .cancelled {
                awaitingVoiceSessionId = nil
                stopVoicePolling()
                VoiceBridge.clear()
                refreshChrome()
            }
            return
        }

        let raw = payload.rawText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !raw.isEmpty else {
            VoiceBridge.clear()
            awaitingVoiceSessionId = nil
            stopVoicePolling()
            refreshChrome()
            return
        }

        reloadDictionary()
        let text = engine.correct(raw, enabled: correctionEnabled)
        textDocumentProxy.insertText(text)
        VoiceBridge.clear()
        awaitingVoiceSessionId = nil
        stopVoicePolling()
        composition = ""
        previewLabel.text = correctionEnabled && text != raw
            ? "音声を挿入しました: \(text)（元: \(raw)）"
            : "音声を挿入しました: \(text)"
        refreshChromeKeepingVoiceNote()
    }

    private func refreshChromeKeepingVoiceNote() {
        let note = previewLabel.text
        refreshChrome()
        if let note, note.contains("音声を挿入") {
            previewLabel.text = note
        }
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
        composition.append(text)
        refreshChrome()
    }

    private func deleteBackwardComposition() {
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

        if awaitingVoiceSessionId == nil {
            if composition.isEmpty {
                previewLabel.text = correctionEnabled
                    ? "補正ON：確定／音声で辞書を適用します"
                    : "補正OFF：入力どおり確定します"
            } else if correctionEnabled {
                let corrected = previewText
                previewLabel.text = corrected == composition
                    ? "補正後: （変化なし）"
                    : "補正後: \(corrected)"
            } else {
                previewLabel.text = "そのまま: \(composition)"
            }
        }

        let on = correctionEnabled
        correctionButton.setTitle(on ? "辞書補正 ON" : "辞書補正 OFF", for: .normal)
        correctionButton.backgroundColor = on
            ? UIColor.systemGreen.withAlphaComponent(0.25)
            : UIColor.tertiarySystemFill
        correctionButton.setTitleColor(on ? .systemGreen : .label, for: .normal)

        if awaitingVoiceSessionId != nil {
            micButton.setTitle("🎤 音声待機中…", for: .normal)
        } else {
            micButton.setTitle("🎤 音声入力", for: .normal)
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
