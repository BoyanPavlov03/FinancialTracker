//
//  DatabaseManager.swift
//  FinancialTracker
//
//  Created by Boyan Pavlov on 5.02.22.
//

import Foundation
import Firebase
import FirebaseFirestore

enum DatabaseError: Error {
    case database(Error?)
    case nonExistingUser
    case access(String?)
    case unknown(String?)
    
    var title: String {
        switch self {
        case .nonExistingUser:
            return "Not Existing User"
        case .access(let error):
            if error != nil {
                return "Access Error"
            }
            return "Unknown Access Error"
        case .database(let error):
            if error != nil {
                return "Database Error"
            }
            return "Unknown Database Error"
        case .unknown:
            return "Unknown Error"
        }
    }
    
    var message: String {
        switch self {
        case .nonExistingUser:
            return "This user doesn't exists or hasn't finished his account creation."
        case .access(let error):
            return error ?? ""
        case .database(let error):
            return error?.localizedDescription ?? ""
        case .unknown(let error):
            return error ?? ""
        }
    }
}

protocol DatabaseManagerDelegate: AnyObject {
    func databaseManagerDidUserChange(sender: DatabaseManager)
}

/// Class for managing all firestore related actions.
class DatabaseManager {
    private let firestore = Firestore.firestore()
    private let delegatesCollection = DelegatesCollection<DatabaseManagerDelegate>()
 
    private(set) var currentUser: User?
    
    init() {}
    
    /// Creating and saving user to firestore database.
    /// - Parameters:
    ///   - firstName: A `String` containing the user's first name.
    ///   - lastName: A `String` containing the user's last name.
    ///   - email: A `String` containing the user's email.
    ///   - uid: A `String` containing the user's UID.
    ///   - completionHandler: Block that is to be executed if an error appears or the function is successfully executed.
    ///     1. `databaseError` - An error object that indicates why the function failed, or nil if the was successful.
    ///     2. `user` - The user that was just created.
    func createUser(firstName: String, lastName: String, email: String, uid: String, completionHandler: @escaping (DatabaseError?, User?) -> Void) {
        let firstNameKey = User.CodingKeys.firstName.rawValue
        let lastNameKey = User.CodingKeys.lastName.rawValue
        let uidKey = User.CodingKeys.uid.rawValue
        let emailKey = User.CodingKeys.email.rawValue
        let scoreKey = User.CodingKeys.score.rawValue
        let premiumKey = User.CodingKeys.premium.rawValue
        let fcmToken = User.CodingKeys.FCMToken.rawValue
        guard let token = UserDefaults.standard.string(forKey: User.CodingKeys.FCMToken.rawValue) else {
            assertionFailure("fcmToken key doesn't exist.")
            return
        }
        // swiftlint:disable:next line_length
        let data = [firstNameKey: firstName, lastNameKey: lastName, emailKey: email, uidKey: uid, scoreKey: 0.0, premiumKey: false, fcmToken: token] as [String: Any]
        
        firestore.collection(DBCollectionKey.users.rawValue).document(uid).setData(data) { error in
            if error != nil {
                completionHandler(DatabaseError.database(error), nil)
                return
            }
            
            self.currentUser = User(firstName: firstName, lastName: lastName, email: email, uid: uid, score: 0)
            completionHandler(nil, self.currentUser)
        }
    }
    
    /// Saving user's starting balance to firestore.
    /// - Parameters:
    ///   - balance: A `Double` containing the balance the user entered.
    ///   - currency: A `Currency` type containing the currency's symbol, rate, code and name.
    ///   - completionHandler: Block that is to be executed if an error appears or the function is successfully executed.
    ///     1. `databaseError` - An error object that indicates why the function failed, or nil if the was successful.
    ///     2. `success` - Boolean that indicates whether the function was successful.
    func addBalanceToCurrentUser(_ balance: Double, currency: Currency, completionHandler: @escaping (DatabaseError?, Bool) -> Void) {
        guard let currentUser = currentUser else {
            completionHandler(DatabaseError.access("Current user is nil in \(#function)."), false)
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
        
            firestore.collection(usersKey).document(currentUser.uid).updateData([balanceKey: balance, currencyKey: currencyValue]) { error in
                if let error = error {
                    completionHandler(DatabaseError.database(error), false)
                    return
                }
                completionHandler(nil, true)
            }
        } catch {
            completionHandler(DatabaseError.database(error), false)
        }
    }
    
    /// Creating and saving a new transaction to the current user.
    /// - Parameters:
    ///   - amount: A `Double` containing the user's transaction amount.
    ///   - category: A `Category` containing the specified `ExpenseCategory` or `IncomeCategory`.
    ///   - completionHandler: Block that is to be executed if an error appears or the function is successfully executed.
    ///     1. `databaseError` - An error object that indicates why the function failed, or nil if the was successful.
    ///     2. `success` - Boolean that indicates whether the function was successful.
    func addTransactionToUserByUID(_ uid: String, amount: Double, category: Category, date: Date, completionHandler: @escaping (DatabaseError?, Bool) -> Void) {
        guard let currentUser = currentUser else {
            completionHandler(DatabaseError.access("Current user is nil in \(#function)."), false)
            return
        }
        
        let usersKey = DBCollectionKey.users.rawValue
        let balanceKey = User.CodingKeys.balance.rawValue
        let formatedDate = date.formatDate("hh:mm:ss, MM/dd/yyyy")
        
        guard let currency = currentUser.currency else {
            fatalError("User doesn't have currency.")
        }
        
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
                            
                guard let userBalance = currentUser.balance else {
                    assertionFailure("User hasn't entered balance yet.")
                    return
                }
                
                let newBalanceValue = (userBalance - amount).round(to: currency.symbolsAfterComma)
                let expenseValue = FieldValue.arrayUnion([dictionary])
                
                let data = [expenseKey: expenseValue, balanceKey: newBalanceValue] as [String: Any]
                firestore.collection(usersKey).document(uid).setData(data, merge: true) { error in
                    if let error = error {
                        completionHandler(DatabaseError.database(error), false)
                        return
                    }
                    completionHandler(nil, true)
                }
            } else if let category = category as? IncomeCategory {
                let incomeKey = User.CodingKeys.incomes.rawValue
                let income = Transaction(amount: amount, date: formatedDate, category: category)
                
                let incomeData = try JSONEncoder().encode(income)
                let json = try JSONSerialization.jsonObject(with: incomeData, options: [])
                
                guard let dictionary = json as? [String: Any] else {
                    assertionFailure("Couldn't cast json to dictionary.")
                    return
                }
                            
                guard let userBalance = currentUser.balance else {
                    assertionFailure("User hasn't entered balance yet.")
                    return
                }

                let newBalanceValue = (userBalance + amount).round(to: currency.symbolsAfterComma)
                let incomeValue = FieldValue.arrayUnion([dictionary])
                
                let data = [incomeKey: incomeValue, balanceKey: newBalanceValue] as [String: Any]
                firestore.collection(usersKey).document(uid).setData(data, merge: true) { error in
                    if let error = error {
                        completionHandler(DatabaseError.database(error), false)
                        return
                    }
                    completionHandler(nil, true)
                }
            }
        } catch {
            completionHandler(DatabaseError.database(error), true)
        }
    }
    
    /// Adding score to the current user based on the amount of time spent in app.
    /// - Parameters:
    ///   - time: A `Double` containing the amount of time the user has spend in foreground. It is measured in seconds.
    ///   - completionHandler: Block that is to be executed if an error appears or the function is successfully executed.
    ///     1. `databaseError` - An error object that indicates why the function failed, or nil if the was successful.
    ///     2. `success` - Boolean that indicates whether the function was successful.
    func addScoreToCurrentUser(basedOn time: Double, completionHandler: @escaping (DatabaseError?, Bool) -> Void) {
        guard let currentUser = currentUser else {
            completionHandler(DatabaseError.access("Current user is nil in \(#function)."), false)
            return
        }
        
        // A point is gained every 20 minutes
        let score = ((time / 60) / 20).round(to: 3)
        
        let newScore = currentUser.score + score
        firestore.collection(DBCollectionKey.users.rawValue).document(currentUser.uid).setData(["score": newScore], merge: true) { error in
            if let error = error {
                completionHandler(DatabaseError.database(error), false)
                return
            }
            completionHandler(nil, true)
        }
    }
    
    /// Changing current user's currency to a new one of his choice.
    /// - Parameters:
    ///   - amount: A `Double` containing the user's transaction amount.
    ///   - currency: A `Currency` type containing the currency's symbol, rate, code and name.
    ///   - completionHandler: Block that is to be executed if an error appears or the function is successfully executed.
    ///     1. `databaseError` - An error object that indicates why the function failed, or nil if the was successful.
    ///     2. `success` - Boolean that indicates whether the function was successful.
    func changeCurrentUserCurrency(_ currency: Currency, completionHandler: @escaping (DatabaseError?, Bool) -> Void) {
        guard let currentUser = currentUser, let balance = currentUser.balance, let currentCurrency = currentUser.currency else {
            completionHandler(DatabaseError.access("Current user is nil in \(#function)."), false)
            return
        }
        
        let newBalance = ((balance / currentCurrency.rate) * currency.rate).round(to: currentCurrency.symbolsAfterComma)
        
        var newExpenses: [Transaction] = []
        for expense in currentUser.expenses {
            let newExpenseAmount = ((expense.amount / currentCurrency.rate) * currency.rate).round(to: currentCurrency.symbolsAfterComma)
            newExpenses.append(Transaction(amount: newExpenseAmount, date: expense.date, category: expense.category))
        }
        
        var newIncomes: [Transaction] = []
        for income in currentUser.incomes {
            let newIncomeAmount = ((income.amount / currentCurrency.rate) * currency.rate).round(to: currentCurrency.symbolsAfterComma)
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
            
            firestore.collection(DBCollectionKey.users.rawValue).document(currentUser.uid).updateData(data) { error in
                if let error = error {
                    completionHandler(DatabaseError.database(error), false)
                    return
                }
                
                self.changeTransfersCurrency(currency: currency, uid: currentUser.uid) { databaseError, success in
                    completionHandler(databaseError, success)
                }
            }
        } catch {
            completionHandler(DatabaseError.database(error), false)
        }
    }
    
    /// Changing current user's currency to a new one of his choice.
    /// - Parameters:
    ///   - currency: A `Currency` type containing the currency's symbol, rate, code and name.
    ///   - uid: A `String` type containing the currentUser uid.
    ///   - completionHandler: Block that is to be executed if an error appears or the function is successfully executed.
    ///     1. `databaseError` - An error object that indicates why the function failed, or nil if the was successful.
    ///     2. `success` - Boolean that indicates whether the function was successful.
    private func changeTransfersCurrency(currency: Currency, uid: String, completionHandler: @escaping(DatabaseError?, Bool) -> Void) {
        let usersKey = DBCollectionKey.users.rawValue
        let transfersKey = DBCollectionKey.transfers.rawValue
        
        firestore.collection(usersKey).document(uid).collection(transfersKey).getDocuments { querySnapshot, error in
            guard error == nil else {
                completionHandler(DatabaseError.database(error), false)
                return
            }

            guard let documents = querySnapshot?.documents else {
                // The user may not have any transfers yet so this collection would be empty
                return
            }
            
            let amountKey = Transfer.TransferKeys.amount.rawValue
            let receiverCurrencyKey = Transfer.TransferKeys.receiverCurrencyRate.rawValue

            for document in documents {
                do {
                    let data = try JSONSerialization.data(withJSONObject: document.data(), options: .prettyPrinted)
                    let transfer = try JSONDecoder().decode(Transfer.self, from: data)

                    let newAmount = ((transfer.amount / transfer.receiverCurrencyRate) * currency.rate).round(to: currency.symbolsAfterComma)
                    
                    var updatedData: [String: Any]
                    
                    // We don't want to change amount if we are on the receiving side
                    switch transfer.transferType {
                    case .send, .requestFromMe:
                        updatedData = [amountKey: newAmount, receiverCurrencyKey: currency.rate]
                    default:
                        updatedData = [receiverCurrencyKey: currency.rate]
                    }
                    
                    self.updateTransfers(data: updatedData, transfer: transfer) { databaseError, success in
                        completionHandler(databaseError, success)
                    }
                } catch {
                    completionHandler(DatabaseError.database(error), false)
                }
            }
            completionHandler(nil, true)
        }
    }
    
    /// Changing current user's currency to a new one of his choice.
    /// - Parameters:
    ///   - data: Data which needs to be replaced.
    ///   - transfer: A `Transfer` type containing the transfer for which needs data to be replaced.
    ///   - completionHandler: Block that is to be executed if an error appears or the function is successfully executed.
    ///     1. `databaseError` - An error object that indicates why the function failed, or nil if the was successful.
    ///     2. `success` - Boolean that indicates whether the function was successful.
    private func updateTransfers(data: [String: Any], transfer: Transfer, completionHandler: @escaping(DatabaseError?, Bool) -> Void) {
        let usersKey = DBCollectionKey.users.rawValue
        let transfersKey = DBCollectionKey.transfers.rawValue
        
        self.firestore.collection(usersKey).document(transfer.fromUser).collection(transfersKey).document(transfer.uid).updateData(data) { error in
            guard error == nil else {
                completionHandler(DatabaseError.database(error), false)
                return
            }
            
            self.firestore.collection(usersKey).document(transfer.toUser).collection(transfersKey).document(transfer.uid).updateData(data) { error in
                guard error == nil else {
                    completionHandler(DatabaseError.database(error), false)
                    return
                }
                
                completionHandler(nil, true)
            }
        }
    }
    
    /// Upgrading user's rank so that he can access premium features.
    /// - Parameters:
    ///   - completionHandler: Block that is to be executed if an error appears or the function is successfully executed.
    ///     1. `databaseError` - An error object that indicates why the function failed, or nil if the was successful.
    ///     2. `success` - Boolean that indicates whether the function was successful.
    func buyPremium(completionHandler: @escaping (DatabaseError?, Bool) -> Void) {
        guard let currentUser = currentUser else {
            completionHandler(DatabaseError.access("Current user is nil in \(#function)."), false)
            return
        }
        
        let premiumKey = User.CodingKeys.premium.rawValue
        firestore.collection(DBCollectionKey.users.rawValue).document(currentUser.uid).setData([premiumKey: true], merge: true) { error in
            if let error = error {
                completionHandler(DatabaseError.database(error), false)
                return
            }
            completionHandler(nil, true)
        }
    }
    
    /// FCM device token is saved when user turns on app
    /// - Parameters:
    ///   - token: A `String` containing the user's device token.
    ///   - completionHandler: Block that is to be executed if an error appears or the function is successfully executed.
    ///     1. `databaseError` - An error object that indicates why the function failed, or nil if the was successful.
    ///     2. `success` - Boolean that indicates whether the function was successful.
    func saveFCMTokenToCurrentUser(_ token: String, completionHandler: @escaping (DatabaseError?, Bool) -> Void) {
        guard let currentUser = currentUser else {
            completionHandler(DatabaseError.access("User data is nil \(#function)."), false)
            return
        }
        let FCMTokenKey = User.CodingKeys.FCMToken.rawValue
        
        firestore.collection(DBCollectionKey.users.rawValue).document(currentUser.uid).setData([FCMTokenKey: token], merge: true) { error in
            if let error = error {
                completionHandler(DatabaseError.database(error), false)
                return
            }
            completionHandler(nil, true)
        }
    }
    
    /// Removing FCM token from user when he signs out
    /// - Parameters:
    ///   - completionHandler: Block that is to be executed if an error appears or the function is successfully executed.
    ///     1. `databaseError` - An error object that indicates why the function failed, or nil if the was successful.
    ///     2. `success` - Boolean that indicates whether the function was successful.
    func removeFCMTokenFromCurrentUser(completionHandler: @escaping (DatabaseError?, Bool) -> Void) {
        guard let currentUser = currentUser else {
            completionHandler(DatabaseError.access("User data is nil \(#function)."), false)
            return
        }
        
        let fcmTokenKey = User.CodingKeys.FCMToken.rawValue
        
        setUserToNil()
        firestore.collection(DBCollectionKey.users.rawValue).document(currentUser.uid).updateData([fcmTokenKey: ""]) { error in
            if let error = error {
                completionHandler(DatabaseError.database(error), false)
                return
            }
            completionHandler(nil, true)
        }
    }
    
    /// Adding new transfer to the database of the current user.
    /// - Parameters:
    ///   - transferType: A `TransferType` whether the user wanted money or send to someone else.
    ///   - description: A `String` containing the transfer's description.
    ///   - completionHandler: Block that is to be executed if an error appears or the function is successfully executed.
    ///     1. `databaseError` - An error object that indicates why the function failed, or nil if the was successful.
    ///     2. `success` - Boolean that indicates whether the function was successful.
    func setTransferToUserByUUID(_ uid: String, transfer: Transfer, completionHandler: @escaping (DatabaseError?, Bool) -> Void) {
        do {
            let transferData = try JSONEncoder().encode(transfer)
            let json = try JSONSerialization.jsonObject(with: transferData, options: [])
            
            guard let dictionary = json as? [String: Any] else {
                assertionFailure("Couldn't cast json to dictionary.")
                return
            }
            
            // swiftlint:disable:next line_length
            firestore.collection(DBCollectionKey.users.rawValue).document(uid).collection(DBCollectionKey.transfers.rawValue).document(transfer.uid).setData(dictionary) { error in
                if let error = error {
                    completionHandler(DatabaseError.database(error), false)
                    return
                }
                
                completionHandler(nil, true)
            }
        } catch {
            completionHandler(DatabaseError.database(error), false)
        }
    }
    
    /// Transfering money from one user to another.
    /// - Parameters:
    ///   - email: A `String` containing the user's email.
    ///   - amount: A `Double` containing the amount to be send or requested.
    ///   - transferType: A `TransferType` whether the user wanted money or send to someone else.
    ///   - completionHandler: Block that is to be executed if an error appears or the function is successfully executed.
    ///     1. `databaseError` - An error object that indicates why the function failed, or nil if the was successful.
    ///     2. `user` - The user that were sent money to.
    func transferMoney(email: String, amount: Double, transferType: TransferType, completionHandler: @escaping (DatabaseError?, User?) -> Void) {
        guard let currentUser = currentUser else {
            completionHandler(DatabaseError.access("User data is nil \(#function)."), nil)
            return
        }
        
        firestore.collection(DBCollectionKey.users.rawValue).whereField("email", isEqualTo: email).getDocuments { querySnapshot, error in
            if let error = error {
                completionHandler(DatabaseError.database(error), nil)
                return
            }
            
            // Get all documents that match this email(should return 1)
            guard let documents = querySnapshot?.documents else {
                // We have a query here because its about the users and to access it you have to be logged so an error is needed
                completionHandler(DatabaseError.unknown("There are no users."), nil)
                return
            }
            
            // Checking if it is only one
            guard documents.count == 1 else {
                completionHandler(DatabaseError.unknown("There mustn't be more than one user with this email."), nil)
                return
            }
            
            do {
                let data = try JSONSerialization.data(withJSONObject: documents[0].data(), options: .prettyPrinted)
                let user = try JSONDecoder().decode(User.self, from: data)
                guard user.balance != nil else {
                    completionHandler(DatabaseError.nonExistingUser, nil)
                    return
                }
                
                guard let receiverCurrency = user.currency,
                      let senderCurrency = currentUser.currency else {
                    completionHandler(DatabaseError.unknown("Users don't have currency."), nil)
                    return
                }
                
                let transferUID = UUID().uuidString
                var receiverTransferType: TransferType
                var senderTransferType: TransferType
                let formatedDate = Date.today.formatDate("hh:mm:ss, MM/dd/yyyy")
                
                switch transferType {
                case .send:
                    senderTransferType = .send
                    receiverTransferType = .receive
                case .requestFromMe:
                    senderTransferType = .requestFromMe
                    receiverTransferType = .requestToMe
                default:
                    fatalError("Receive or RequestToMe cases shouldn't be an option.")
                }
                
                // swiftlint:disable:next line_length
                var transfer = Transfer(uid: transferUID, transferType: senderTransferType, transferState: .pending, fromUser: currentUser.uid, toUser: user.uid, amount: amount, senderName: "\(currentUser.firstName) \(currentUser.lastName)", senderCurrencyRate: senderCurrency.rate, receiverCurrencyRate: receiverCurrency.rate, date: formatedDate)
                self.setTransferToUserByUUID(currentUser.uid, transfer: transfer) { databaseError, _ in
                    if let databaseError = databaseError {
                        completionHandler(databaseError, nil)
                        return
                    }
                    
                    transfer.transferType = receiverTransferType
                    self.setTransferToUserByUUID(user.uid, transfer: transfer) { databaseError, _ in
                        if let databaseError = databaseError {
                            completionHandler(databaseError, nil)
                            return
                        }

                        completionHandler(nil, user)
                    }
                }
            } catch {
                completionHandler(DatabaseError.database(error), nil)
            }
        }
    }
    
    /// Transfering money from one user to another.
    /// - Parameters:
    ///   - transfer: A `Transfer` type which represents the transfer which needs to completed
    ///   - completionHandler: Block that is to be executed if an error appears or the function is successfully executed.
    ///     1. `databaseError` - An error object that indicates why the function failed, or nil if the was successful.
    ///     2. `success` - Boolean that indicates whether the function was successful.
    func completeTransfer(transfer: Transfer, completionHandler: @escaping(DatabaseError?, Bool) -> Void) {
        guard let currentUser = currentUser else {
            completionHandler(DatabaseError.access("User data is nil \(#function)."), false)
            return
        }
        
        let myTransferAmount = (transfer.amount / transfer.senderCurrencyRate) * transfer.receiverCurrencyRate
        var otherUserTransactionType: Category
        var myTransactionType: Category
    
        switch transfer.transferType {
        case .receive:
            otherUserTransactionType = ExpenseCategory.transfer
            myTransactionType = IncomeCategory.transfer
        case .requestToMe:
            otherUserTransactionType = IncomeCategory.transfer
            myTransactionType = ExpenseCategory.transfer
        default:
            assertionFailure("Should not appear.")
            return
        }
        
        let otherUID = transfer.fromUser
        let myUID = currentUser.uid
        self.addTransactionToUserByUID(otherUID, amount: transfer.amount, category: otherUserTransactionType, date: Date.today) { databaseError, _ in
            if let databaseError = databaseError {
                completionHandler(databaseError, false)
                return
            }
            
            // swiftlint:disable:next line_length
            self.firestore.collection(DBCollectionKey.users.rawValue).document(transfer.fromUser).collection(DBCollectionKey.transfers.rawValue).document(transfer.uid).updateData([Transfer.TransferKeys.transferState.rawValue: "Completed"])
            
            self.addTransactionToUserByUID(myUID, amount: myTransferAmount, category: myTransactionType, date: Date.today) { databaseError, _ in
                if let databaseError = databaseError {
                    completionHandler(databaseError, false)
                    return
                }
                
                // swiftlint:disable:next line_length
                self.firestore.collection(DBCollectionKey.users.rawValue).document(currentUser.uid).collection(DBCollectionKey.transfers.rawValue).document(transfer.uid).updateData([Transfer.TransferKeys.transferState.rawValue: "Completed"])
                
                completionHandler(nil, true)
            }
        }
    }
    
    /// Listener for firestore changes
    /// - Parameters:
    ///   - completionHandler: Block that is to be executed if an error appears or the function is successfully executed.
    ///     1. `databaseError` - An error object that indicates why the function failed, or nil if the was successful.
    ///     2. `user` - The user that was returned by firestore.
    func firestoreDidChangeUserTransfersData(completionHandler: @escaping (DatabaseError?, [Transfer]?) -> Void) {
        guard let currentUser = currentUser else {
            completionHandler(DatabaseError.access("User data is nil \(#function)."), nil)
            return
        }
        
        // swiftlint:disable:next line_length
        firestore.collection(DBCollectionKey.users.rawValue).document(currentUser.uid).collection(DBCollectionKey.transfers.rawValue).addSnapshotListener { query, error in
            
            guard error == nil else {
                completionHandler(DatabaseError.database(error), nil)
                return
            }
            
            guard let query = query else {
                // The user may not have any transfers yet so this collection would be empty
                return
            }
            
            do {
                var transfers: [Transfer] = []
                
                for document in query.documents {
                    let data = try JSONSerialization.data(withJSONObject: document.data(), options: .prettyPrinted)
                    let transfer = try JSONDecoder().decode(Transfer.self, from: data)
                    transfers.append(transfer)
                }
                
                completionHandler(nil, transfers)
            } catch {
                completionHandler(DatabaseError.database(error), nil)
            }
        }
    }
    
    /// Listener for firestore changes
    /// - Parameters:
    ///   - completionHandler: Block that is to be executed if an error appears or the function is successfully executed.
    ///     1. `databaseError` - An error object that indicates why the function failed, or nil if the was successful.
    ///     2. `user` - The user that was returned by firestore.
    func firestoreDidChangeUserData(completionHandler: @escaping (DatabaseError?, User?) -> Void) {
        guard let currentUser = currentUser else {
            completionHandler(DatabaseError.access("User data is nil \(#function)."), nil)
            return
        }
        
        firestore.collection(DBCollectionKey.users.rawValue).document(currentUser.uid).addSnapshotListener { document, error in
            guard error == nil else {
                completionHandler(DatabaseError.database(error), nil)
                return
            }
            
            guard let json = document?.data() else {
                completionHandler(DatabaseError.unknown("Current user data is nil."), nil)
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
                completionHandler(DatabaseError.database(error), nil)
            }
        }
    }
    
    /// Fetching data at the beginning of startup
    /// Listener for firestore changes
    /// - Parameters:
    ///   - uid: A `String` containing the user's UID.
    ///   - completionHandler: Block that is to be executed if an error appears or the function is successfully executed.
    ///     1. `databaseError` - An error object that indicates why the function failed, or nil if the was successful.
    ///     2. `user` - The user that was returned by firestore.
    func getCurrentUserData(uid: String, completionHandler: @escaping (DatabaseError?, User?) -> Void) {
        firestore.collection(DBCollectionKey.users.rawValue).document(uid).getDocument { document, error in
            guard error == nil else {
                completionHandler(DatabaseError.database(error), nil)
                return
            }
            
            guard let json = document?.data() else {
                completionHandler(DatabaseError.unknown("Current user data is nil."), nil)
                return
            }
            
            do {
                let data = try JSONSerialization.data(withJSONObject: json, options: .prettyPrinted)
                let user = try JSONDecoder().decode(User.self, from: data)
                self.currentUser = user
                let FCMTokenKey = User.CodingKeys.FCMToken.rawValue
                
                self.saveFCMTokenToCurrentUser(UserDefaults.standard.string(forKey: FCMTokenKey) ?? "") { error, _ in
                    if let error = error {
                        assertionFailure(error.localizedDescription)
                        return
                    }
                }
                
                if user.balance != nil {
                    self.delegatesCollection.forEach { delegate in
                        delegate.databaseManagerDidUserChange(sender: self)
                    }
                }
                
                completionHandler(nil, user)
            } catch {
                completionHandler(DatabaseError.database(error), nil)
            }
        }
    }
    
    /// Get all stored users in the database.
    /// Listener for firestore changes
    /// - Parameters:
    ///   - completionHandler: Block that is to be executed if an error appears or the function is successfully executed.
    ///     1. `databaseError` - An error object that indicates why the function failed, or nil if the was successful.
    ///     2. `emails` - All users's emails.
    func getAllUsers(completionHandler: @escaping (DatabaseError?, [String]?) -> Void) {
        guard let currentUser = currentUser else {
            completionHandler(DatabaseError.access("Current user is nil in \(#function)."), nil)
            return
        }
        
        firestore.collection(DBCollectionKey.users.rawValue).getDocuments { querySnapshot, error in
            if let error = error {
                completionHandler(DatabaseError.database(error), nil)
                return
            }
            
            guard let documents = querySnapshot?.documents else {
                // We have a query here because its about the users and to access it you have to be logged so an error is needed
                completionHandler(DatabaseError.unknown("There are no users."), nil)
                return
            }
            
            var emails: [String] = []
            for document in documents {
                guard let email = document.data()["email"] as? String else {
                    continue
                }
                
                guard email != currentUser.email else {
                    continue
                }
                
                emails.append(email)
            }
            
            completionHandler(nil, emails)
        }
    }
    
    func setUserToNil() {
        currentUser = nil
    }
    
    // MARK: - DelegatesCollection Methods
    
    func addDelegate(_ delegate: DatabaseManagerDelegate) {
        delegatesCollection.add(delegate: delegate)
    }
    
    func removeDelegate(_ delegate: DatabaseManagerDelegate) {
        delegatesCollection.remove(delegate: delegate)
    }
}
