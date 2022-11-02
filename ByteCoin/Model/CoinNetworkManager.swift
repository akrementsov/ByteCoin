//
//  CoinNetworkManager.swift
//  ByteCoin
//
//  Created by Andrey on 9/17/22.
//  Images Copyright © 2019 The App Brewery. All rights reserved.
//

import Foundation

protocol CoinNetworkManagerDelegate: AnyObject {
    func coinManager(_ manager: CoinNetworkManager, didUpdateCoin coin: CoinModel)
    func coinManager(_ manager: CoinNetworkManager, didFailWithError error: Error)
}

enum ServerError: Error {
    case message(_ message: String)
}

final class CoinNetworkManager {
    
    let fiatCurrencyArray = ["AUD", "BRL","CAD","CNY","EUR","GBP","HKD","IDR","ILS","INR","JPY","MXN","NOK","NZD","PLN","RON","RUB","SEK","SGD","USD","ZAR"]
    let digitalCurrencyArray = ["BTC", "ETH", "USDT", "USDC", "BNB", "BUSD", "XRP", "ADA", "SOL", "DOGE", "DOT", "MATIC"]
    weak var delegate: CoinNetworkManagerDelegate?
    
    private var path = ""
    private let baseURL = "https://rest.coinapi.io/v1/exchangerate"
    private let apiKey = "ENTER YOUR API KEY HERE"
    
    func getExchangeRate(baseCurrency: String, quoteCurrency: String) {
        guard let url = URL(string: "\(baseURL)/\(baseCurrency)/\(quoteCurrency)") else { return }

        var urlRequest = URLRequest(url: url)
        urlRequest.addValue(apiKey, forHTTPHeaderField: "X-CoinAPI-Key")
        urlRequest.timeoutInterval = 20
        
        path = urlRequest.url!.absoluteString
        performRequest(with: urlRequest)
    }
    
    private func performRequest(with urlRequest: URLRequest) {
        let session = URLSession(configuration: .default)
        session.delegateQueue.qualityOfService = .default
        let task = session.dataTask(with: urlRequest) { data, response, error in
            switch error {
            case .some(let error):
                self.delegate?.coinManager(self, didFailWithError: error)
            case .none:
                guard let response = response as? HTTPURLResponse,
                      self.path == response.url?.absoluteString,
                      let safeData = data else { return }
                
                switch response.statusCode {
                case 200:
                    guard let coin = self.parseJSON(safeData) else { return }
                    self.delegate?.coinManager(self, didUpdateCoin: coin)
                default:
                    guard let error = self.parseJSONError(safeData) else { return }
                    self.delegate?.coinManager(self, didFailWithError: ServerError.message(error))
                }
            }
        }
        task.resume()
    }
    
    private func parseJSON(_ coinData: Data) -> CoinModel? {
        let decoder = JSONDecoder()
        do {
            let decodedData = try decoder.decode(CoinData.self, from: coinData)
            let rate = decodedData.rate
            let fiatCurrency = decodedData.asset_id_quote
            let digitalCurrency = decodedData.asset_id_base
            
            return CoinModel(rate: rate, fiatCurrency: fiatCurrency, digitalCurrency: digitalCurrency)
        } catch {
            self.delegate?.coinManager(self, didFailWithError: error)
            return nil
        }
    }
    
    private func parseJSONError(_ errorData: Data) -> String? {
        let decoder = JSONDecoder()
        do {
            let decodedData = try decoder.decode(ErrorData.self, from: errorData)
            let message = decodedData.error
            
            return message
        } catch {
            self.delegate?.coinManager(self, didFailWithError: error)
            return nil
        }
    }
}
