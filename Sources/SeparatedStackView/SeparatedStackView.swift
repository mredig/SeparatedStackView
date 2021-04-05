import UIKit

public class SubStack: UIStackView {
	class SeparatorCache {
		private var cache: Set<UIView> = []

		let generator: () -> UIView

		init(generator: @escaping () -> UIView) {
			self.generator = generator
		}

		func dequeueView() -> UIView {
			if let view = cache.first {
				cache.remove(view)
				return view
			} else {
				return generator()
			}
		}

		func queueView(_ view: UIView) {
			view.removeFromSuperview()
			view.removeConstraints(view.constraints)
			cache.insert(view)
		}
	}

	public typealias ConstraintGeneratorParameters = (stack: SubStack, view: UIView, separator: UIView)
	public var verticalConstraintGenerator: (ConstraintGeneratorParameters) -> [NSLayoutConstraint] = { parameters in
		let (stack, view, separator) = parameters

		let constraints = [
			separator.heightAnchor.constraint(equalToConstant: stack.separatorSize),
			separator.centerYAnchor.constraint(equalTo: view.bottomAnchor, constant: stack.spacing / 2),
			separator.widthAnchor.constraint(equalTo: stack.widthAnchor),
		]

		return constraints
	}

	public var horizontalConstraintGenerator: (ConstraintGeneratorParameters) -> [NSLayoutConstraint] = { parameters in
		let (stack, view, separator) = parameters
		let constraints = [
			separator.heightAnchor.constraint(equalTo: stack.heightAnchor),
			separator.widthAnchor.constraint(equalToConstant: stack.separatorSize),
			separator.centerXAnchor.constraint(equalTo: view.trailingAnchor, constant: stack.spacing / 2),
		]

		return constraints
	}

	var separators: Set<UIView> = []
	public var separatorSize: CGFloat = 1

	let separatorCache = SeparatorCache(generator: {
		let separator = UIView()
		separator.backgroundColor = .systemGray2
		return separator
	})

	public override func layoutSubviews() {
		super.layoutSubviews()
		separators.forEach { separatorCache.queueView($0) }
		separators = []

		guard arrangedSubviews.count > 1 else { return }
		let separations = arrangedSubviews.count - 1

		var constraints: [NSLayoutConstraint] = []
		defer { NSLayoutConstraint.activate(constraints) }

		arrangedSubviews[..<separations].forEach {
			guard $0.isHidden == false else { return }
			let separator = separatorCache.dequeueView()
			separator.translatesAutoresizingMaskIntoConstraints = false
			addSubview(separator)

			switch axis {
			case .horizontal:
				constraints += horizontalConstraintGenerator((self, $0, separator))
			case .vertical:
				constraints += verticalConstraintGenerator((self, $0, separator))
			@unknown default:
				print("Unknown axis value: \(axis)")
			}

			separators.insert(separator)
		}
	}
}
