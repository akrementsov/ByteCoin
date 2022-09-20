//
//  CoinModel.swift
//  ByteCoin
//
//  Created by Andrey on 9/17/22.
//  Images Copyright © 2019 The App Brewery. All rights reserved.
//

import Foundation

struct CoinModel: Decodable {
    let rate: Double
    let fiatCurrency: String
    let digitalCurrency: String
}
