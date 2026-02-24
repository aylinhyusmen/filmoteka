import UIKit

final class ResetPasswordViewController: UIViewController {
    
    @IBOutlet weak var newPasswordTextField: UITextField!
    @IBOutlet weak var newPasswordConfirmTextField: UITextField!
    @IBOutlet weak var resetPasswordButton: UIButton!
    @IBOutlet weak var errorLabel: UILabel!
    
    private let viewModel = ResetPasswordViewModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        bindViewModel()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        viewModel.cancelTask()
    }
    
    private func bindViewModel() {
        viewModel.onSuccess = { [weak self] in
            self?.showSuccessAlert()
        }
        
        viewModel.onError = { [weak self] errorMessage in
            self?.errorLabel.isHidden = false
            self?.showError(message: errorMessage)
        }
        
        viewModel.onLoading = { [weak self] isLoading in
            self?.resetPasswordButton.isEnabled = !isLoading
            self?.resetPasswordButton.setTitle(isLoading ? "Updating..." : "Reset Password", for: .normal)
        }
    }
    
    @IBAction func resetPasswordButtonTapped(_ sender: UIButton) {
        errorLabel.isHidden = true
        
        viewModel.resetPassword(
            password: newPasswordTextField.text,
            confirmPassword: newPasswordConfirmTextField.text
        )
    }
    
    private func showSuccessAlert() {
        let alert = UIAlertController(
            title: "Password Updated!",
            message: "Please log in with your new credentials.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            Navigator.shared.navigateToLogin(from: self.navigationController)
        })
        
        present(alert, animated: true)
    }
}
