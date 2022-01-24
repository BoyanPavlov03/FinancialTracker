//
//  Currency.swift
//  FinancialTracker
//
//  Created by Boyan Pavlov on 22.01.22.
//

import Foundation

struct Links {
    static let symbolCurrencyApi = "https://raw.githubusercontent.com/mansourcodes/country-databases/main/currency-details.json"
    static let ratesCurrencyApi = "https://open.er-api.com/v6/latest"
}

struct Currency: Codable {
    let name: String
    let symbolNative: String
    let code: String
    
    var rate: Double
    
    enum CodingKeys: String, CodingKey {
        case name
        case symbolNative = "symbol_native"
        case code
        case rate
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
        rate = try values.decodeIfPresent(Double.self, forKey: .rate) ?? 0
    }
}

func getCurrencies(completionHandler: @escaping (String?, [Currency]?) -> Void) {
    var allCurrencies: [Currency] = []
    
    if let jsonLink = URL(string: Links.symbolCurrencyApi) {
        URLSession.shared.dataTask(with: jsonLink) { data, _, error in
            guard error == nil else {
                completionHandler("Couldn't load json.", nil)
                return
            }
            
            if let data = data {
                do {
                    let result = try JSONDecoder().decode([String: Currency].self, from: data)
                    var beforeSorted: [Currency] = []
                    beforeSorted.append(contentsOf: result.values)
                    allCurrencies = beforeSorted.sorted { $0.code < $1.code }
                } catch {
                    completionHandler(error.localizedDescription, nil)
                }
            }
        }.resume()
    }
    
    if let jsonLink = URL(string: Links.ratesCurrencyApi) {
        URLSession.shared.dataTask(with: jsonLink) { data, _, error in
            guard error == nil else {
                completionHandler("Couldn't load json.", nil)
                return
            }
            
            if let data = data {
                do {
                    let result = try JSONDecoder().decode(Currency.ExchangeRates.self, from: data)
                    for iterrator in 0..<allCurrencies.count {
                        let code = allCurrencies[iterrator].code
                        if let rate = result.rates[code] {
                            allCurrencies[iterrator].rate = rate
                        }
                    }
                    completionHandler(nil, allCurrencies)
                } catch {
                    completionHandler(error.localizedDescription, nil)
                }
            }
        }.resume()        
    }
}
