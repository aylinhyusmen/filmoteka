import UIKit

final class AuthViewController: UIViewController {
    
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var createAccountButton: UIButton!
    @IBOutlet weak var errorLabel: UILabel!
    @IBOutlet weak var forgotPasswordButton: UIButton!
    
    private let viewModel = AuthViewModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        bindViewModel()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        viewModel.cancelTasks()
    }
    
    private func bindViewModel() {
        viewModel.onLoginSuccess = {
            Navigator.shared.navigateToHome()
        }
        
        viewModel.onForgotPasswordSuccess = { [weak self] in
            self?.showAlert(
                title: "Check Your Email",
                message: "We've sent you instructions to reset your password."
            )
        }
        
        viewModel.onError = { [weak self] errorMessage in
            self?.errorLabel.isHidden = false
            self?.showError(message: errorMessage)
        }
        
        viewModel.onLoading = { [weak self] isLoading in
            self?.loginButton.isEnabled = !isLoading
            self?.forgotPasswordButton.isEnabled = !isLoading
            self?.createAccountButton.isEnabled = !isLoading
        }
    }
    
    @IBAction func loginButtonTapped(_ sender: UIButton) {
        errorLabel.isHidden = true
        viewModel.login(email: emailTextField.text, password: passwordTextField.text)
    }
    
    @IBAction func forgotPasswordButtonTapped(_ sender: UIButton) {
        errorLabel.isHidden = true
        viewModel.forgotPassword(email: emailTextField.text)
    }
    
    @IBAction func createAccountButtonTapped(_ sender: UIButton) {
        Navigator.shared.navigateToCreateAccount(from: navigationController)
    }
}
