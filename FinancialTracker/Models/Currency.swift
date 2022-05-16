//
//  Currency.swift
//  FinancialTracker
//
//  Created by Boyan Pavlov on 22.01.22.
//

import Foundation

private enum Links: String {
    case symbolCurrencyApi = "https://raw.githubusercontent.com/mansourcodes/country-databases/main/currency-details.json"
    case ratesCurrencyApi = "https://open.er-api.com/v6/latest"
}

enum CurrencyError: Error {
    case currencyName(Error?)
    case currenctRate(Error?)
}

struct Currency: Codable {
    let name: String
    let symbolNative: String
    let code: String
    let symbolsAfterComma: Int
    
    var rate: Double
    
    enum CodingKeys: String, CodingKey {
        case name
        case symbolNative = "symbol_native"
        case code
        case rate
        case symbolsAfterComma = "decimal_digits"
    }
    
    struct ExchangeRates: Codable {
        let rates: [String: Double]
    }
}

extension Currency {
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        name = try values.decode(String.self, forKey: .name)
        symbolNative = try values.decode(String.self, forKey: .symbolNative)
        code = try values.decode(String.self, forKey: .code)
        symbolsAfterComma = try values.decode(Int.self, forKey: .symbolsAfterComma)
        rate = try values.decodeIfPresent(Double.self, forKey: .rate) ?? 0
    }
    
    private static func fetchCurrencies(completionHandler: @escaping (CurrencyError?, [Currency]?) -> Void) {
        var allCurrencies: [Currency] = []
        
        if let jsonLink = URL(string: Links.symbolCurrencyApi.rawValue) {
            URLSession.shared.dataTask(with: jsonLink) { data, _, error in
                guard error == nil else {
                    completionHandler(CurrencyError.currencyName(error), nil)
                    return
                }
                
                if let data = data {
                    do {
                        let result = try JSONDecoder().decode([String: Currency].self, from: data)
                        var beforeSorted: [Currency] = []
                        beforeSorted.append(contentsOf: result.values)
                        allCurrencies = beforeSorted.sorted { $0.code < $1.code }
                        
                        completionHandler(nil, allCurrencies)
                    } catch {
                        completionHandler(CurrencyError.currencyName(error), nil)
                    }
                }
            }.resume()
        }
    }
    
    private static func fetchCurrencyRates(currencies: [Currency], completionHandler: @escaping (CurrencyError?, [Currency]?) -> Void) {
        var allCurrencies: [Currency] = currencies
        
        if let jsonLink = URL(string: Links.ratesCurrencyApi.rawValue) {
            URLSession.shared.dataTask(with: jsonLink) { data, _, error in
                guard error == nil else {
                    completionHandler(CurrencyError.currenctRate(error), nil)
                    return
                }
                
                if let data = data {
                    do {
                        let result = try JSONDecoder().decode(Currency.ExchangeRates.self, from: data)
                        for iterator in 0..<allCurrencies.count {
                            let code = allCurrencies[iterator].code
                            if let rate = result.rates[code] {
                                allCurrencies[iterator].rate = rate
                            }
                        }
                        completionHandler(nil, allCurrencies)
                    } catch {
                        completionHandler(CurrencyError.currenctRate(error), nil)
                    }
                }
            }.resume()
        }
    }
    
    static func getCurrencies(completionHandler: @escaping (CurrencyError?, [Currency]?) -> Void) {
        fetchCurrencies { error, allCurrencies in
            if let error = error {
                completionHandler(error, nil)
                return
            }
            
            guard let allCurrencies = allCurrencies else {
                return
            }
            
            fetchCurrencyRates(currencies: allCurrencies) { error, allCurrencies in
                if let error = error {
                    completionHandler(error, nil)
                    return
                }
                
                completionHandler(nil, allCurrencies)
            }
        }
    }
}
