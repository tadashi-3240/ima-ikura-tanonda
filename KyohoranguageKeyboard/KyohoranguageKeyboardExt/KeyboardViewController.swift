import UIKit

/// Minimal custom keyboard so「協豊ランゲージ」appears in Settings and the globe switcher.
final class KeyboardViewController: UIInputViewController {
    private let titleLabel = UILabel()
    private let stack = UIStackView()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.secondarySystemBackground
        buildChrome()
    }

    private func buildChrome() {
        titleLabel.text = "協豊ランゲージ"
        titleLabel.font = .preferredFont(forTextStyle: .headline)
        titleLabel.textAlignment = .center

        stack.axis = .vertical
        stack.spacing = 8
        stack.alignment = .fill
        stack.translatesAutoresizingMaskIntoConstraints = false

        let row = UIStackView()
        row.axis = .horizontal
        row.spacing = 8
        row.distribution = .fillEqually

        for label in ["あ", "い", "う", "金古", "⌫"] {
            row.addArrangedSubview(makeKey(title: label) { [weak self] in
                self?.handleKey(label)
            })
        }

        let bottom = UIStackView()
        bottom.axis = .horizontal
        bottom.spacing = 8
        bottom.distribution = .fillEqually
        bottom.addArrangedSubview(makeKey(title: "🌐") { [weak self] in
            self?.advanceToNextInputMode()
        })
        bottom.addArrangedSubview(makeKey(title: "スペース") { [weak self] in
            self?.textDocumentProxy.insertText(" ")
        })
        bottom.addArrangedSubview(makeKey(title: "改行") { [weak self] in
            self?.textDocumentProxy.insertText("\n")
        })

        stack.addArrangedSubview(titleLabel)
        stack.addArrangedSubview(row)
        stack.addArrangedSubview(bottom)
        view.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -8),
            stack.topAnchor.constraint(equalTo: view.topAnchor, constant: 8),
            stack.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -8),
            view.heightAnchor.constraint(greaterThanOrEqualToConstant: 180),
        ])
    }

    private func handleKey(_ title: String) {
        if title == "⌫" {
            textDocumentProxy.deleteBackward()
        } else {
            textDocumentProxy.insertText(title)
        }
    }

    private func makeKey(title: String, action: @escaping () -> Void) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = .preferredFont(forTextStyle: .title3)
        button.backgroundColor = UIColor.systemBackground
        button.layer.cornerRadius = 8
        button.heightAnchor.constraint(greaterThanOrEqualToConstant: 44).isActive = true
        button.addAction(UIAction { _ in action() }, for: .touchUpInside)
        return button
    }
}
