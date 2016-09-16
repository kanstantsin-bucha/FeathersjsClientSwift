//
//  Parser.swift
//  doroga
//
//  Created by truebucha on 9/2/16.
//  Copyright © 2016 Bucha Kanstantsin. All rights reserved.
//

import Foundation

public protocol ResponseParser : class {
    func parse(responseData: SocketResponseData) -> FeathersResponse
}

open class DefaultParser: ResponseParser {
    open func parse(responseData: SocketResponseData) -> FeathersResponse {
        if let error = errorUsing(responseData: responseData) {
            return FeathersResponse.error(error)
        }
        
        if let array = objectsArrayUsing(responseData: responseData) {
            if array.count == 1 {
                return FeathersResponse.object(array.first!)
            }
            
            return FeathersResponse.array(array)
        }
        
        return FeathersResponse.raw(responseData)
    }
    
    fileprivate func errorUsing(responseData: SocketResponseData) -> FeathersError? {
        guard responseData.count == 1 else { return nil }
        
        let objectX = responseData.first
        
        if let reason = objectX as? String {
            let result = FeathersError.connectionError(reason: reason)
            return result
        }
        
        if let object = objectX as? FeathersResponseObject {
            let result = errorUsing(responseObject: object)
            return result
        }
        
        return nil
    }
    
    fileprivate func objectsArrayUsing(responseData: SocketResponseData) -> FeathersResponseArray? {

        let result = responseData.filter { (obj) -> Bool in
            let result = (obj as? FeathersResponseObject) != nil
            return result
        }
        
        guard result.count != 0 else {
            return nil
        }

        return result as? FeathersResponseArray
    }
    
    /*
    {
    className = "bad-request";
    code = 400;
    errors =     (
    {
    message = "email must be unique";
    path = email;
    type = "unique violation";
    value = "xxx@gmail.com";
    }
    );
    message = "Validation error";
    name = BadRequest;
    stack = "BadRequest: Validation error\n    at Object.construct (/Users...timers.js:534:15)\n    at processImmediate [as _immediateCallback] (timers.js:514:5)";
    type = FeathersError;
    }
    */
    
    fileprivate func errorUsing(responseObject: FeathersResponseObject) -> FeathersError? {
        let message = responseObject["message"] as? String
        let name = responseObject["name"] as? String
        
        guard message != nil else { return nil }
        
        let type = responseObject["type"] as? String
        let mainReason = message ?? ""
        let errorType = type ?? name ?? "Error"
        
        let SQL = responseObject["sql"] as? String
        
        guard SQL == nil else {
            let original = responseObject["original"] as? FeathersResponseObject
            let parent = responseObject["parent"] as? FeathersResponseObject
            let error = original ?? parent ?? ["sorry" : "sql error description not found"]
            let result = FeathersError.databaseError(reason: mainReason,
                                                     SQL: SQL!,
                                                     SQLError: error)
            return result
        }
        
        let errors = responseObject["errors"]
        let firstError = (errors as? [AnyObject])?.first as? FeathersResponseObject
        let firstMessage = firstError?["message"] as? String
        let firstReason = firstMessage ?? ""
        
        let code = responseObject["code"] as? Int
        
        let reason = mainReason + ": " + firstReason
        
        let result =  FeathersError.serverError(reason: reason,
                                                type: errorType,
                                                code: code ?? 0)
        return result
    }
    
}


