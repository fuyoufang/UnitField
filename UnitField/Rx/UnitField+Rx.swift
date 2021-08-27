import RxSwift
import RxCocoa

#if os(iOS) || os(tvOS)

import RxSwift
import UIKit

extension Reactive where Base: UnitField {
    /// Reactive wrapper for `text` property.
    public var text: ControlProperty<String?> {
        return value
    }
    
    /// Reactive wrapper for `text` property.
    public var value: ControlProperty<String?> {
        return base.rx.controlPropertyWithDefaultEvents(
            getter: { textField in
                textField.text
            },
            setter: { textField, value in
                // This check is important because setting text value always clears control state
                // including marked text selection which is imporant for proper input
                // when IME input method is used.
                if textField.text != value {
                    textField.text = value
                }
            }
        )
    }

    /// Bindable sink for `isSecureTextEntry` property.
    public var isSecureTextEntry: Binder<Bool> {
        return Binder(self.base) { textField, isSecureTextEntry in
            textField.isSecureTextEntry = isSecureTextEntry
        }
    }
    
}

extension Reactive where Base: UIControl {
    /// This is a separate method to better communicate to public consumers that
    /// an `editingEvent` needs to fire for control property to be updated.
    internal func controlPropertyWithDefaultEvents<T>(
        editingEvents: UIControl.Event = [.allEditingEvents, .valueChanged],
        getter: @escaping (Base) -> T,
        setter: @escaping (Base, T) -> Void
        ) -> ControlProperty<T> {
        return controlProperty(
            editingEvents: editingEvents,
            getter: getter,
            setter: setter
        )
    }
}

#endif
