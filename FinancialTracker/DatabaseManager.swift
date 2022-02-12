//
//  DatabaseManager.swift
//  FinancialTracker
//
//  Created by Boyan Pavlov on 5.02.22.
//

import Foundation
import Firebase
import FirebaseFirestore

protocol DatabaseManagerDelegate: AnyObject {
    func databaseManagerDidUserChange(sender: DatabaseManager)
}

class DatabaseManager {
    private let firestore = Firestore.firestore()
    private let delegatesCollection = DelegatesCollection<DatabaseManagerDelegate>()
 
    private(set) var currentUser: User?
    
    init() {}
    
    func createUser(firstName: String, lastName: String, email: String, uid: String, completionHandler: @escaping (FirebaseError?, User?) -> Void) {
        let firstNameKey = User.CodingKeys.firstName.rawValue
        let lastNameKey = User.CodingKeys.lastName.rawValue
        let uidKey = User.CodingKeys.uid.rawValue
        let emailKey = User.CodingKeys.email.rawValue
        let scoreKey = User.CodingKeys.score.rawValue
        let premiumKey = User.CodingKeys.premium.rawValue
        let data = [firstNameKey: firstName, lastNameKey: lastName, emailKey: email, uidKey: uid, scoreKey: 0.0, premiumKey: false] as [String: Any]
        
        self.firestore.collection(DBCollectionKey.users.rawValue).document(uid).setData(data) { error in
            if error != nil {
                completionHandler(FirebaseError.database(error), nil)
                return
            }
            
            self.currentUser = User(firstName: firstName, lastName: lastName, email: email, uid: uid, score: 0)
            completionHandler(nil, self.currentUser)
        }
    }
    
    func addBalanceToCurrentUser(_ balance: Double, currency: Currency, completionHandler: @escaping (FirebaseError?, Bool) -> Void) {
        guard let currentUser = currentUser else {
            completionHandler(FirebaseError.access("Current user is nil in \(#function)."), false)
            return
        }
                
        let usersKey = DBCollectionKey.users.rawValue
        let balanceKey = User.CodingKeys.balance.rawValue
        let currencyKey = User.CodingKeys.currency.rawValue
        
        do {
            let currencyData = try JSONEncoder().encode(currency)
            let json = try JSONSerialization.jsonObject(with: currencyData, options: [])
            
            guard let currencyValue = json as? [String: Any] else {
                assertionFailure("Couldn't cast json to dictionary.")
                return
            }
        
            firestore.collection(usersKey).document(currentUser.uid).updateData([balanceKey: balance, currencyKey: currencyValue])
            
            completionHandler(nil, true)
        } catch {
            completionHandler(FirebaseError.database(error), false)
        }
    }
    
    func addTransactionToCurrentUser(_ amount: Double, category: Category, completionHandler: @escaping (FirebaseError?, Bool) -> Void) {
        guard let currentUser = currentUser else {
            completionHandler(FirebaseError.access("Current user is nil in \(#function)."), false)
            return
        }
                
        let usersKey = DBCollectionKey.users.rawValue
        let balanceKey = User.CodingKeys.balance.rawValue
        
        let formatedDate = today.formatDate("hh:mm:ss, MM/dd/yyyy")
        
        do {
            if let category = category as? ExpenseCategory {
                let expenseKey = User.CodingKeys.expenses.rawValue
                let expense = Transaction(amount: amount, date: formatedDate, category: category)
                
                let expenseData = try JSONEncoder().encode(expense)
                let json = try JSONSerialization.jsonObject(with: expenseData, options: [])
                
                guard let dictionary = json as? [String: Any] else {
                    assertionFailure("Couldn't cast json to dictionary.")
                    return
                }
                            
                guard let userBalance = self.currentUser?.balance else {
                    assertionFailure("User hasn't entered balance yet.")
                    return
                }

                let newBalanceValue = (userBalance - amount).round(to: 2)
                let expenseValue = FieldValue.arrayUnion([dictionary])
                
                firestore.collection(usersKey).document(currentUser.uid).setData([expenseKey: expenseValue, balanceKey: newBalanceValue], merge: true)
            } else if let category = category as? IncomeCategory {
                let incomeKey = User.CodingKeys.incomes.rawValue
                let income = Transaction(amount: amount, date: formatedDate, category: category)
                
                let incomeData = try JSONEncoder().encode(income)
                let json = try JSONSerialization.jsonObject(with: incomeData, options: [])
                
                guard let dictionary = json as? [String: Any] else {
                    assertionFailure("Couldn't cast json to dictionary.")
                    return
                }
                            
                guard let userBalance = self.currentUser?.balance else {
                    assertionFailure("User hasn't entered balance yet.")
                    return
                }

                let newBalanceValue = (userBalance + amount).round(to: 2)
                let incomeValue = FieldValue.arrayUnion([dictionary])
                
                firestore.collection(usersKey).document(currentUser.uid).setData([incomeKey: incomeValue, balanceKey: newBalanceValue], merge: true)
            }
            
            completionHandler(nil, true)
        } catch {
            completionHandler(FirebaseError.database(error), true)
        }
    }
    
    func addScoreToUserBasedOnTime(_ time: Double, completionHandler: @escaping (FirebaseError?, Bool) -> Void) {
        guard let currentUser = currentUser else {
            completionHandler(FirebaseError.access("Current user is nil in \(#function)."), false)
            return
        }
        
        // A point is gained every 20 minutes
        let score = ((time / 60) / 20).round(to: 3)
        
        let newScore = currentUser.score + score
        firestore.collection(DBCollectionKey.users.rawValue).document(currentUser.uid).setData(["score": newScore], merge: true)
        completionHandler(nil, true)
    }
    
    func changeCurrency(_ currency: Currency, completionHandler: @escaping (FirebaseError?, Bool) -> Void) {
        guard let currentUser = currentUser, let balance = currentUser.balance, let currentCurrency = currentUser.currency else {
            completionHandler(FirebaseError.access("Current user is nil in \(#function)."), false)
            return
        }
        
        let newBalance = ((balance / currentCurrency.rate) * currency.rate).round(to: 2)
        
        var newExpenses: [Transaction] = []
        for expense in currentUser.expenses {
            let newExpenseAmount = ((expense.amount / currentCurrency.rate) * currency.rate).round(to: 2)
            newExpenses.append(Transaction(amount: newExpenseAmount, date: expense.date, category: expense.category))
        }
        
        var newIncomes: [Transaction] = []
        for income in currentUser.incomes {
            let newIncomeAmount = ((income.amount / currentCurrency.rate) * currency.rate).round(to: 2)
            newIncomes.append(Transaction(amount: newIncomeAmount, date: income.date, category: income.category))
        }
        
        let balanceKey = User.CodingKeys.balance.rawValue
        let expensesKey = User.CodingKeys.expenses.rawValue
        let currencyKey = User.CodingKeys.currency.rawValue
        let incomesKey = User.CodingKeys.incomes.rawValue
        
        do {
            let incomeData = try JSONEncoder().encode(newIncomes)
            let incomesJson = try JSONSerialization.jsonObject(with: incomeData, options: [])
                          
            guard let incomesValue = incomesJson as? [Any] else {
                assertionFailure("Couldn't cast json to array.")
                return
            }
            
            let expenseData = try JSONEncoder().encode(newExpenses)
            let expensesJson = try JSONSerialization.jsonObject(with: expenseData, options: [])
                          
            guard let expensesValue = expensesJson as? [Any] else {
                assertionFailure("Couldn't cast json to array.")
                return
            }
            
            let currencyData = try JSONEncoder().encode(currency)
            let currencyJson = try JSONSerialization.jsonObject(with: currencyData, options: [])
            
            guard let currencyValue = currencyJson as? [String: Any] else {
                assertionFailure("Couldn't cast json to dictionary.")
                return
            }
                                 
            let data = [balanceKey: newBalance, expensesKey: expensesValue, incomesKey: incomesValue, currencyKey: currencyValue] as [String: Any]
            
            firestore.collection(DBCollectionKey.users.rawValue).document(currentUser.uid).updateData(data)
            
            completionHandler(nil, true)
        } catch {
            completionHandler(FirebaseError.database(error), false)
        }
    }
    
    func buyPremium(completionHandler: @escaping (FirebaseError?, Bool) -> Void) {
        guard let currentUser = currentUser else {
            completionHandler(FirebaseError.access("Current user is nil in \(#function)."), false)
            return
        }
        
        let premiumKey = User.CodingKeys.premium.rawValue
        firestore.collection(DBCollectionKey.users.rawValue).document(currentUser.uid).setData([premiumKey: true], merge: true)
        completionHandler(nil, true)
    }
    
    func firestoreDidChangeData(completionHandler: @escaping (FirebaseError?, User?) -> Void) {
        guard let currentUser = currentUser else {
            completionHandler(FirebaseError.access("User data is nil \(#function)."), nil)
            return
        }
        
        self.firestore.collection(DBCollectionKey.users.rawValue).document(currentUser.uid).addSnapshotListener { document, error in
            guard error == nil else {
                completionHandler(FirebaseError.database(error), nil)
                return
            }
            
            guard let json = document?.data() else {
                completionHandler(FirebaseError.unknown, nil)
                return
            }
            
            do {
                let data = try JSONSerialization.data(withJSONObject: json, options: .prettyPrinted)
                let user = try JSONDecoder().decode(User.self, from: data)
                self.currentUser = user
                                
                self.delegatesCollection.forEach { delegate in
                    delegate.databaseManagerDidUserChange(sender: self)
                }
            
                completionHandler(nil, user)
            } catch {
                completionHandler(FirebaseError.database(error), nil)
            }
        }
    }
    
    func getCurrentUserData(uid: String, completionHandler: @escaping (FirebaseError?, User?) -> Void) {
        self.firestore.collection(DBCollectionKey.users.rawValue).document(uid).getDocument { document, error in
            guard error == nil else {
                completionHandler(FirebaseError.database(error), nil)
                return
            }
            
            guard let json = document?.data() else {
                completionHandler(FirebaseError.unknown, nil)
                return
            }
            
            do {
                let data = try JSONSerialization.data(withJSONObject: json, options: .prettyPrinted)
                let user = try JSONDecoder().decode(User.self, from: data)
                self.currentUser = user
                
                self.delegatesCollection.forEach { delegate in
                    delegate.databaseManagerDidUserChange(sender: self)
                }
                
                completionHandler(nil, user)
            } catch {
                completionHandler(FirebaseError.database(error), nil)
            }
        }
    }
    
    func setUserToNil() {
        self.currentUser = nil
    }
    
    // MARK: - DelegatesCollection Methods
    
    func addDelegate(_ delegate: DatabaseManagerDelegate) {
        delegatesCollection.add(delegate: delegate)
    }
    
    func removeDelegate(_ delegate: DatabaseManagerDelegate) {
        delegatesCollection.remove(delegate: delegate)
    }
}
