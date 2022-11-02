//
//  CoinViewController.swift
//  ByteCoin
//
//  Created by Andrey on 9/17/22.
//  Images Copyright © 2019 The App Brewery. All rights reserved.
//

import UIKit

final class CoinViewController: UIViewController {
    
    @IBOutlet weak var digitalTextField: UITextField!
    @IBOutlet weak var digitalCurrencyPicker: UIPickerView!
    @IBOutlet weak var fiatCurrencyPicker: UIPickerView!
    @IBOutlet weak var fiatTextField: UITextField!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    var coinManager = CoinNetworkManager()
    var coinCalculator = CoinCalculatorManager()
    
    lazy private var badConnectionAlert: UIAlertController = {
        let alertController = UIAlertController(title: "Bad internet connection", message: "Check your internet connection and try one more time", preferredStyle: .alert)
        let action = UIAlertAction(title: "Ok", style: .default)
        alertController.addAction(action)
        return alertController
    }()
    
    lazy private var bar: UIToolbar = {
        let bar = UIToolbar(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 35))
        let done = UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(hideKeyboard))
        let font = UIFont.systemFont(ofSize: 20)
        let textAttributes: [NSAttributedString.Key: Any] = [.font: font]
        done.setTitleTextAttributes(textAttributes, for: .normal)
        done.setTitleTextAttributes(textAttributes, for: .highlighted)
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil)
        let fixSpace = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: self, action: nil)
        fixSpace.width = 23
        
        bar.items = [flexSpace, done, fixSpace]
        return bar
    }()
    
    private var waitingTimer: Timer?
    private var delayTimer: Timer?
    private var digitalTextFieldValue: String?
    private var fiatTextFieldValue: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupVC()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillAppear), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillDisappear), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification,  object: nil)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
    }
}

// MARK: - Functions
extension CoinViewController {
    private func waitingForConnection() {
        self.waitingTimer?.invalidate()
        waitingTimer = Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(startWaiting), userInfo: nil, repeats: false)
    }
    
    private func finishWaiting() {
        self.waitingTimer?.invalidate()
        self.activityIndicator.stopAnimating()
    }
    
    @objc private func startWaiting() {
        self.activityIndicator.startAnimating()
        self.activityIndicator.isHidden = false
    }
    
    @objc private func keyboardWillAppear(_ notification: NSNotification) {
        if self.view.frame.origin.y == 0 {
            self.view.frame.origin.y = -view.frame.height / 4
        }
    }
    
    @objc private func keyboardWillDisappear(_ notification: NSNotification) {
        self.view.frame.origin.y = 0
    }
    
    private func setupVC() {
        digitalCurrencyPicker.dataSource = self
        digitalCurrencyPicker.delegate = self
        fiatCurrencyPicker.dataSource = self
        fiatCurrencyPicker.delegate = self
        coinManager.delegate = self
        digitalTextField.delegate = self
        fiatTextField.delegate = self
        
        digitalTextField.inputAccessoryView = bar
        fiatTextField.inputAccessoryView = bar
        
        digitalCurrencyPicker.tintColor = UIColor(named: "Title Color")
        fiatCurrencyPicker.tintColor = UIColor(named: "Title Color")
    }

    @objc private func hideKeyboard() {
        view.endEditing(true)
    }
    
    private func delayRequest() {
        let digitalSelected = digitalCurrencyPicker.selectedRow(inComponent: 0)
        let fiatSelected = fiatCurrencyPicker.selectedRow(inComponent: 0)
        
        let digitalCurrency = coinManager.digitalCurrencyArray[digitalSelected]
        let fiatCurrency = coinManager.fiatCurrencyArray[fiatSelected]
        
        delayTimer?.invalidate()
        delayTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: false) { _ in
            self.coinManager.getExchangeRate(baseCurrency: digitalCurrency, quoteCurrency: fiatCurrency)
            self.waitingForConnection()
        }
    }
    
    private func request() {
        let digitalSelected = digitalCurrencyPicker.selectedRow(inComponent: 0)
        let fiatSelected = fiatCurrencyPicker.selectedRow(inComponent: 0)
        
        let digitalCurrency = coinManager.digitalCurrencyArray[digitalSelected]
        let fiatCurrency = coinManager.fiatCurrencyArray[fiatSelected]
        
        coinManager.getExchangeRate(baseCurrency: digitalCurrency, quoteCurrency: fiatCurrency)
        waitingForConnection()
    }
}

// MARK: - UIPickerViewSetting
extension CoinViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        switch pickerView.tag {
        case 0: return coinManager.digitalCurrencyArray.count
        default: return coinManager.fiatCurrencyArray.count
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        switch pickerView.tag {
        case 0: return coinManager.digitalCurrencyArray[row]
        default: return coinManager.fiatCurrencyArray[row]
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        guard let digitalText = digitalTextField.text,
        let fiatText = fiatTextField.text,
        (fiatText + digitalText) != "" else { return }
        
        delayRequest()
    }
}

// MARK: - CoinManagerDelegate
extension CoinViewController: CoinNetworkManagerDelegate {
    func coinManager(_ manager: CoinNetworkManager, didUpdateCoin coin: CoinModel) {
        DispatchQueue.main.async {
            self.finishWaiting()
            self.coinCalculator.storeCoinModel(coin)
            
            if self.coinCalculator.calculate() == nil {
                self.digitalTextField.text = ""
                self.fiatTextField.text = ""
            } else {
                self.digitalTextField.text = String(self.coinCalculator.calculate()!.digitalCurrency)
                self.fiatTextField.text = String(self.coinCalculator.calculate()!.fiatCurrency)
            }
        }
    }
    
// MARK: Error handling
    func coinManager(_ manager: CoinNetworkManager, didFailWithError error: Error) {
        if let urlError = error as? URLError {
            switch urlError.code{
            case .timedOut:
                DispatchQueue.main.async {
                    self.finishWaiting()
                    self.present(self.badConnectionAlert, animated: true)
                }
            default:
                DispatchQueue.main.async {
                    self.finishWaiting()
                }
            }
        }
        
        if let serverError = error as? ServerError {
            switch serverError {
            case .message(let message):
                DispatchQueue.main.async {
                    let alert = UIAlertController(title: "Something happened", message: message, preferredStyle: .alert)
                    let action = UIAlertAction(title: "Ok", style: .default)
                    alert.addAction(action)
                    self.present(alert, animated: true)
                    self.finishWaiting()
                }
            }
        }
    }
}

// MARK: - UITextFieldDelegate
extension CoinViewController: UITextFieldDelegate {
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        delayTimer?.invalidate()
        
        if textField.tag == 0 {
            digitalTextFieldValue = textField.text
        }
        
        if textField.tag == 1 {
            fiatTextFieldValue = textField.text
        }
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        guard let digitalText = digitalTextField.text,
        let fiatText = fiatTextField.text,
        (fiatText + digitalText) != "" else { return }
        
        if textField.tag == 0, textField.text != digitalTextFieldValue, textField.text != "" {
            coinCalculator.storeDigital(textField.text?.trimmingCharacters(in: ["."]))
            delayRequest()
            return
        } else if textField.tag == 0, textField.text == "" {
            coinCalculator.storeFiat(fiatTextField.text?.trimmingCharacters(in: ["."]))
            delayRequest()
            return
        } else if textField.tag == 1, textField.text != fiatTextFieldValue, textField.text != "" {
            coinCalculator.storeFiat(textField.text?.trimmingCharacters(in: ["."]))
            delayRequest()
            return
        } else if textField.tag == 1, textField.text == "" {
            coinCalculator.storeDigital(digitalTextField.text?.trimmingCharacters(in: ["."]))
            delayRequest()
            return
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        view.endEditing(true)
    }
}

