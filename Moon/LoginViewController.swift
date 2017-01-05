//
//  LogInViewController.swift
//  Moon
//
//  Created by Evan Noble on 3/30/16.
//  Copyright © 2016 Evan Noble. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift
import GoogleSignIn

class LoginViewController: UIViewController, UITextFieldDelegate, ErrorPopoverRenderer, SegueHandlerType, OverlayRenderer   {
    
    enum SegueIdentifier: String {
        case LoggedIn
        case EnterProfileInformation
    }
    
    // MARK: - Properties
    private var viewModel: LoginViewModel!
    private let disposeBag = DisposeBag()
    
    // MARK: - Outlets
    @IBOutlet weak var fbLoginButton: UIButton!
    @IBOutlet weak var scroll: UIScrollView!
    @IBOutlet weak var logo: UIImageView!
    @IBOutlet weak var emailText: UITextField!
    @IBOutlet weak var password: UITextField!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var createAccountButton: UIButton!
    @IBOutlet weak var forgotPasswordButton: UIButton!
    @IBOutlet weak var googleLoginButton: UIButton!
    
    // MARK: - View controller lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        GIDSignIn.sharedInstance().uiDelegate = self
        
        viewSetup()
        createAndBindViewModel()
    }

    func viewSetup(){
        
        
        // Scroll view set up
        scroll.contentSize = CGSizeMake(self.view.frame.size.width, 677)
        scroll.scrollEnabled = true
        scroll.backgroundColor = UIColor.clearColor()

        // Setting the textfield delegate
        emailText.delegate = self
        password.delegate = self
   
        // Email text field set up
        emailText.backgroundColor = UIColor.clearColor()
        emailText.attributedPlaceholder = NSAttributedString(string:"Email", attributes:[NSForegroundColorAttributeName: UIColor.whiteColor()])
        
        // Password textfield set up
        password.backgroundColor = UIColor.clearColor()
        password.attributedPlaceholder = NSAttributedString(string:"Password", attributes:[NSForegroundColorAttributeName: UIColor.whiteColor()])
     
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        // Changes the status bar to white
        return UIStatusBarStyle.LightContent
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?){
        view.endEditing(true)
        super.touchesBegan(touches, withEvent: event)
        
        // Resigns the keyboards when it senses a touch
        emailText.resignFirstResponder()
        password.resignFirstResponder()
        
    }
    
    func createAndBindViewModel() {
        
        viewModel = LoginViewModel(userService: FirebaseUserService(), facebookService: FacebookService(), pushNotificationService: BatchService(), googleService: GoogleService())
        
        // VC to VM
        emailText.rx_text.bindTo(viewModel.email).addDisposableTo(disposeBag)
        password.rx_text.bindTo(viewModel.password).addDisposableTo(disposeBag)
        fbLoginButton.rx_tap.bindTo(viewModel.facebookLoginButtonTapped).addDisposableTo(disposeBag)
        forgotPasswordButton.rx_tap.bindTo(viewModel.forgotPasswordButtonTapped).addDisposableTo(disposeBag)
        googleLoginButton.rx_tap.bindTo(viewModel.googleSignInButtonTapped).addDisposableTo(disposeBag)
        loginButton.rx_tap.bindTo(viewModel.loginButtonTapped).addDisposableTo(disposeBag)
        
        // VM to VC
        viewModel.shouldShowOverlay.asObservable()
            .subscribeNext { (action) in
                switch action {
                case .Remove:
                    self.removeOverlay()
                case .Show(let options):
                    self.presentOverlayWith(Options: options)
                }
            }
            .addDisposableTo(disposeBag)
        
        viewModel.postLoginAction
            .subscribeNext { (action) in
                switch action {
                case .LoginComplete:
                    self.performSegueWithIdentifier(SegueIdentifier.LoggedIn, sender: self)
                case .MoreInformationNeeded:
                    self.performSegueWithIdentifier(SegueIdentifier.EnterProfileInformation, sender: self)
                case .Failed(let error):
                    self.presentError(ErrorOptions(errorMessage: error.debugDescription))
                }
            }
            .addDisposableTo(disposeBag)
        
    }
    
}

extension LoginViewController: GIDSignInUIDelegate {
    
    func signIn(signIn: GIDSignIn!, dismissViewController viewController: UIViewController!) {
        self.dismissViewControllerAnimated(true) { () -> Void in
        }
    }
    
    func signIn(signIn: GIDSignIn!, presentViewController viewController: UIViewController!) {
        self.presentViewController(viewController, animated: true) { () -> Void in
        }
    }
}
