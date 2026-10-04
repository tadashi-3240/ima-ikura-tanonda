import UIKit

/// Custom keyboard: composition buffer → optional dictionary correction → insert into host field.
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

    private let rootStack = UIStackView()
    private let compositionLabel = UILabel()
    private let previewLabel = UILabel()
    private let correctionButton = UIButton(type: .system)
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
        compositionLabel.backgroundColor = UIColor.systemBackground
        compositionLabel.layer.cornerRadius = 10
        compositionLabel.clipsToBounds = true
        compositionLabel.layoutMargins = UIEdgeInsets(top: 8, left: 10, bottom: 8, right: 10)

        previewLabel.font = .systemFont(ofSize: 16, weight: .medium)
        previewLabel.textColor = .secondaryLabel
        previewLabel.numberOfLines = 1

        correctionButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        correctionButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 48).isActive = true
        correctionButton.layer.cornerRadius = 10
        correctionButton.clipsToBounds = true
        correctionButton.addAction(UIAction { [weak self] _ in
            self?.toggleCorrection()
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
        keysScrollView.heightAnchor.constraint(equalToConstant: 220).isActive = true

        NSLayoutConstraint.activate([
            keysContainer.leadingAnchor.constraint(equalTo: keysScrollView.contentLayoutGuide.leadingAnchor),
            keysContainer.trailingAnchor.constraint(equalTo: keysScrollView.contentLayoutGuide.trailingAnchor),
            keysContainer.topAnchor.constraint(equalTo: keysScrollView.contentLayoutGuide.topAnchor),
            keysContainer.bottomAnchor.constraint(equalTo: keysScrollView.contentLayoutGuide.bottomAnchor),
            keysContainer.widthAnchor.constraint(equalTo: keysScrollView.frameLayoutGuide.widthAnchor),
        ])

        let topRow = UIStackView(arrangedSubviews: [correctionButton])
        topRow.axis = .horizontal

        rootStack.addArrangedSubview(padded(compositionLabel, height: 56))
        rootStack.addArrangedSubview(previewLabel)
        rootStack.addArrangedSubview(topRow)
        rootStack.addArrangedSubview(pageControl)
        rootStack.addArrangedSubview(keysScrollView)
        rootStack.addArrangedSubview(makeActionRow())

        NSLayoutConstraint.activate([
            rootStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8),
            rootStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -8),
            rootStack.topAnchor.constraint(equalTo: view.topAnchor, constant: 8),
            rootStack.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -8),
            view.heightAnchor.constraint(greaterThanOrEqualToConstant: 380),
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
        // Stable unique order
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

        if composition.isEmpty {
            previewLabel.text = correctionEnabled ? "補正ON：確定で辞書を適用します" : "補正OFF：入力どおり確定します"
        } else if correctionEnabled {
            let corrected = previewText
            previewLabel.text = corrected == composition
                ? "補正後: （変化なし）"
                : "補正後: \(corrected)"
        } else {
            previewLabel.text = "そのまま: \(composition)"
        }

        let on = correctionEnabled
        correctionButton.setTitle(on ? "辞書補正 ON" : "辞書補正 OFF", for: .normal)
        correctionButton.backgroundColor = on
            ? UIColor.systemGreen.withAlphaComponent(0.25)
            : UIColor.tertiarySystemFill
        correctionButton.setTitleColor(on ? .systemGreen : .label, for: .normal)
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
