//
//  ProfileAuth.swift
//  doroga
//
//  Created by truebucha on 9/9/16.
//  Copyright © 2016 Bucha Kanstantsin. All rights reserved.
//

import Foundation

public protocol UserAuthProtocol {
    var email: String {get}
    var password: String {get}
    
    func requestObject() -> FeathersRequestObject
}

open class UserAuth: UserAuthProtocol {

    public let email: String
    public let password: String
    
    static let passwordMinCharactersCount = 5
    
    public init?(email: String,
                 password: String) {
        let validEmail = type(of: self).validateEmailFormat(email)
        let validPassword = type(of: self).validatePasswordFormat(password)
        guard validEmail, validPassword else { return nil }
        self.email = email
        self.password = password
    }
    
    public func requestObject() -> FeathersRequestObject {
        let result = ["email": email,
                      "password": password]
        return result
    }
    
    open class func validateEmailFormat(_ email: String) -> Bool {
        let REGEX: String
        REGEX = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,32}"
        let predicate = NSPredicate(format: "SELF MATCHES %@", REGEX)
        return predicate.evaluate(with: email)
    }
    
    
    /// Validate password is at least 5 characters
    open class func validatePasswordFormat(_ password: String) -> Bool {
        let trimmedString = password.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        let result = trimmedString.characters.count >= passwordMinCharactersCount
        return result
    }

}
