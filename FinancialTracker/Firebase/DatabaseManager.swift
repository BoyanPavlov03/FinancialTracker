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
    case unknown
    
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
        case .unknown:
            return "This error should not appear."
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
        let remindersKey = User.CodingKeys.reminders.rawValue
        guard let token = UserDefaults.standard.string(forKey: "fcmToken") else {
            assertionFailure("fcmToken key doesn't exist.")
            return
        }
        // swiftlint:disable:next line_length
        let data = [firstNameKey: firstName, lastNameKey: lastName, emailKey: email, uidKey: uid, scoreKey: 0.0, premiumKey: false, fcmToken: token, remindersKey: []] as [String: Any]
        
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
    func addTransactionToCurrentUser(amount: Double, category: Category, completionHandler: @escaping (DatabaseError?, Bool) -> Void) {
        guard let currentUser = currentUser else {
            completionHandler(DatabaseError.access("Current user is nil in \(#function)."), false)
            return
        }
        
        let usersKey = DBCollectionKey.users.rawValue
        let balanceKey = User.CodingKeys.balance.rawValue
        let formatedDate = Date.today.formatDate("hh:mm:ss, MM/dd/yyyy")
        
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

                let newBalanceValue = (userBalance - amount).round(to: 2)
                let expenseValue = FieldValue.arrayUnion([dictionary])
                
                let data = [expenseKey: expenseValue, balanceKey: newBalanceValue] as [String: Any]
                firestore.collection(usersKey).document(currentUser.uid).setData(data, merge: true) { error in
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

                let newBalanceValue = (userBalance + amount).round(to: 2)
                let incomeValue = FieldValue.arrayUnion([dictionary])
                
                let data = [incomeKey: incomeValue, balanceKey: newBalanceValue] as [String: Any]
                firestore.collection(usersKey).document(currentUser.uid).setData(data, merge: true) { error in
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
            
            firestore.collection(DBCollectionKey.users.rawValue).document(currentUser.uid).updateData(data) { error in
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
        
        firestore.collection(DBCollectionKey.users.rawValue).document(currentUser.uid).updateData([fcmTokenKey: ""]) { error in
            if let error = error {
                completionHandler(DatabaseError.database(error), false)
                return
            }
            completionHandler(nil, true)
        }
    }
    
    /// Adding new reminder to the database of the current user.
    /// - Parameters:
    ///   - transferType: A `TransferType` whether the user wanted money or send to someone else.
    ///   - description: A `String` containing the reminder's description.
    ///   - completionHandler: Block that is to be executed if an error appears or the function is successfully executed.
    ///     1. `databaseError` - An error object that indicates why the function failed, or nil if the was successful.
    ///     2. `success` - Boolean that indicates whether the function was successful.
    func setReminderToCurrentUser(transferType: TransferType, description: String, completionHandler: @escaping (DatabaseError?, Bool) -> Void) {
        guard let currentUser = currentUser else {
            completionHandler(DatabaseError.access("Current user is nil in \(#function)."), false)
            return
        }
        
        let formatedDate = Date.today.formatDate("hh:mm:ss, MM/dd/yyyy")
        
        let reminder = Reminder(transferType: transferType, description: description, date: formatedDate)
        
        do {
            let reminderData = try JSONEncoder().encode(reminder)
            let json = try JSONSerialization.jsonObject(with: reminderData, options: [])
            
            guard let dictionary = json as? [String: Any] else {
                assertionFailure("Couldn't cast json to dictionary.")
                return
            }
            let remindersKey = User.CodingKeys.reminders.rawValue
            let reminderValue = FieldValue.arrayUnion([dictionary])
            
            let data = [remindersKey: reminderValue] as [String: Any]
            firestore.collection(DBCollectionKey.users.rawValue).document(currentUser.uid).setData(data, merge: true) { error in
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
    
    // Person has read his reminder so he removes it from his list.
    /// - Parameters:
    ///   - reminder: A `Reminder` which should be deleted.
    ///   - completionHandler: Block that is to be executed if an error appears or the function is successfully executed.
    ///     1. `databaseError` - An error object that indicates why the function failed, or nil if the was successful.
    ///     2. `success` - Boolean that indicates whether the function was successful.
    func deleteReminderFromCurrentUser(reminder: Reminder, completionHandler: @escaping (DatabaseError?, Bool) -> Void) {
        guard let currentUser = currentUser else {
            completionHandler(DatabaseError.access("Current user is nil in \(#function)."), false)
            return
        }
        
        var reminders = currentUser.reminders
        if let index = reminders.firstIndex(of: reminder) {
            reminders.remove(at: index)
        }
        
        let remindersKey = User.CodingKeys.reminders.rawValue
        
        do {
            let remindersData = try JSONEncoder().encode(reminders)
            let remindersJson = try JSONSerialization.jsonObject(with: remindersData, options: [])
                          
            guard let remindersValue = remindersJson as? [Any] else {
                assertionFailure("Couldn't cast json to array.")
                return
            }
            
            firestore.collection(DBCollectionKey.users.rawValue).document(currentUser.uid).updateData([remindersKey: remindersValue]) { error in
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
        firestore.collection(DBCollectionKey.users.rawValue).whereField("email", isEqualTo: email).getDocuments { querySnapshot, error in
            if let error = error {
                completionHandler(DatabaseError.database(error), nil)
                return
            }
            
            // Get all documents that match this email(should return 1)
            guard let documents = querySnapshot?.documents else {
                completionHandler(DatabaseError.unknown, nil)
                return
            }
            
            // Checking if it is only one
            guard documents.count == 1 else {
                completionHandler(DatabaseError.unknown, nil)
                return
            }
            
            do {
                let data = try JSONSerialization.data(withJSONObject: documents[0].data(), options: .prettyPrinted)
                let user = try JSONDecoder().decode(User.self, from: data)
                guard user.balance != nil else {
                    completionHandler(DatabaseError.nonExistingUser, nil)
                    return
                }
                
                if transferType == .send {
                    self.addTransactionToCurrentUser(amount: amount, category: ExpenseCategory.transfer) { databaseError, _ in
                        if let databaseError = databaseError {
                            completionHandler(databaseError, nil)
                            return
                        }
                        completionHandler(nil, user)
                    }
                } else if transferType == .request {
                    completionHandler(nil, user)
                }
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
    func firestoreDidChangeData(completionHandler: @escaping (DatabaseError?, User?) -> Void) {
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
                completionHandler(DatabaseError.unknown, nil)
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
                completionHandler(DatabaseError.unknown, nil)
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
                completionHandler(DatabaseError.unknown, nil)
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
