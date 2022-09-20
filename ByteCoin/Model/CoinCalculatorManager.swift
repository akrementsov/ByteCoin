//
//  CoinCalculatorManager.swift
//  ByteCoin
//
//  Created by Andrey on 9/17/22.
//  Images Copyright © 2019 The App Brewery. All rights reserved.
//

import Foundation

final class CoinCalculatorManager {
    var rate: Double?
    var storedDigitalValue: String?
    var storedFiatValue: String?
    
    func storeCoinModel(_ coinModel: CoinModel) {
        self.rate = coinModel.rate
    }
    
    func storeDigital(_ digitalCurrency: String?) {
        self.storedDigitalValue = digitalCurrency
        self.storedFiatValue = nil
    }
    
    func storeFiat(_ fiatCurrency: String?) {
        self.storedFiatValue = fiatCurrency
        self.storedDigitalValue = nil
    }
    
    func calculate() -> CalculatedModel? {
        guard let rate = rate else { return nil }
       
        var digital: Decimal = 0.0
        var fiat: Decimal = 0.0
        
        if let storedDigitalValue = storedDigitalValue {
            digital = Decimal(Double(storedDigitalValue)!)
            fiat = digital * Decimal(rate)
            let trimmedString = storedDigitalValue.round(12)
            return CalculatedModel(digitalCurrency: trimmedString, fiatCurrency: "\(fiat)".round(12))
        } else if let storedFiatValue = storedFiatValue {
            fiat = Decimal(Double(storedFiatValue)!)
            digital = fiat / Decimal(rate)
            return CalculatedModel(digitalCurrency: "\(digital)".round(12), fiatCurrency: storedFiatValue.round(12))
        } else {
            return nil
        }
    }
}
