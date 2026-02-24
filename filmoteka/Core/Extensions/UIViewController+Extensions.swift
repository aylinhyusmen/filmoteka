import UIKit

extension UIViewController {
    
    @MainActor
    func showAlert(
        title: String,
        message: String,
        actionTitle: String = "OK",
        action: (() -> Void)? = nil
    ) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: actionTitle, style: .default) { _ in
            action?()
        })
        present(alert, animated: true)
    }
    
    @MainActor
    func showError(_ error: Error, title: String = "Oops!") {
        showAlert(title: title, message: error.localizedDescription)
    }
    
    @MainActor
    func showError(message: String = "Something went wrong.", title: String = "Oops!") {
        showAlert(title: title, message: message)
    }
    
}

