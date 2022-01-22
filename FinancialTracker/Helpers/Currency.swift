//
//  Currency.swift
//  FinancialTracker
//
//  Created by Boyan Pavlov on 22.01.22.
//

import Foundation

class Currencies {
    var allCurrencies: [Currency] = []
    
    init() {
        let sem = DispatchSemaphore.init(value: 0)

        if let jsonLink = URL(string: "https://raw.githubusercontent.com/mansourcodes/country-databases/main/currency-details.json") {
            URLSession.shared.dataTask(with: jsonLink) { data, _, error in
                defer { sem.signal() }
                guard error == nil else {
                    assertionFailure("Couldn't load json.")
                    return
                }
                
                guard let data = data else {
                    return
                }

                do {
                    let result = try JSONDecoder().decode([String: Currency].self, from: data)
                    var beforeSorted: [Currency] = []
                    beforeSorted.append(contentsOf: result.values)
                    self.allCurrencies = beforeSorted.sorted { $0.code < $1.code }
                } catch {
                    assertionFailure(error.localizedDescription)
                }
            }.resume()
            
            sem.wait()
        }
    }

}

struct Currency: Codable {
    let name: String
    let symbolNative: String
    let code: String
    
    enum CodingKeys: String, CodingKey {
        case name
        case symbolNative = "symbol_native"
        case code
    }
}
