import UIKit

final class CreateAccountViewController: UIViewController {
    
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var confirmPasswordTextField: UITextField!
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var errorLabel: UILabel!
    @IBOutlet weak var createAccountButton: UIButton!
    
    private let viewModel = CreateAccountViewModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        bindViewModel()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        viewModel.cancelSignUp()
    }
    
    private func bindViewModel() {
        viewModel.onSuccess = {
            Navigator.shared.navigateToHome()
        }
        
        viewModel.onError = { [weak self] errorMessage in
            self?.errorLabel.isHidden = false
            self?.showError(message: errorMessage)
        }
        
        viewModel.onLoading = { [weak self] isLoading in
            self?.createAccountButton.isEnabled = !isLoading
            self?.createAccountButton.setTitle(isLoading ? "Creating..." : "Create Account", for: .normal)
        }
    }
    
    @IBAction func createAccountButtonTapped(_ sender: UIButton) {
        errorLabel.isHidden = true
        
        viewModel.createAccount(
            email: emailTextField.text,
            password: passwordTextField.text,
            confirmPassword: confirmPasswordTextField.text,
            username: usernameTextField.text
        )
    }
}
