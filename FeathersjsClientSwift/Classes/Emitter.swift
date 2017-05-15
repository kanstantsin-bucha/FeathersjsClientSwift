//
//  Emitter.swift
//  doroga
//
//  Created by truebucha on 8/24/16.
//  Copyright © 2016 Bucha Kanstantsin. All rights reserved.
//

import Foundation
import SocketIO


public enum EmitterError: Error {
    case connectionNotConnected
    case connectionNotAuthorized
    case socketFailedToEmitEvent
    case receivedTimeoutOrNoAckCallback
    //error when there is a connection failure
    case connectionFailure(reason: String)
}

/** emitter mostly used like single shot object
 */

open class Emitter {

    public unowned let feathers: FeathersClient
    public let event: String
    public let responseParser: ResponseParser
    public let authRequired: Bool

    public init(feathers: FeathersClient,
                event: String,
                authRequired: Bool = true,
                responseParser: ResponseParser = DefaultParser()) {
        self.feathers = feathers
        self.event = event
        self.authRequired = authRequired
        self.responseParser = responseParser
    }
    
    /**
    Send an event to server
    - parameter id: id of requested object (FeathersObjectID)
    - parameter object: request object containing additional info (FeathersRequestObject)
    - throws: `FeathersError`
    */

    public func emit(id: FeathersObjectID? = nil,
                     _ object: FeathersRequestObject? = nil) throws {
        let data = dataUsing(id: id,
                             object: object,
                             objects: nil)
        do { try emit(data: data)
        } catch {
            throw error
        }
    }
    
    public func emit(id: FeathersObjectID? = nil,
                     _ objects: [FeathersRequestObject]) throws {
        let data = dataUsing(id: id,
                             object: nil,
                             objects: objects)
        do { try emit(data: data)
        } catch {
            throw error
        }
    }
    
    func emit(data: SocketRequestData) throws {

        guard feathers.connected else {
            print("Should Be Connected To Emit")
            throw FeathersError.connectionError(reason: "Not connected")
        }
    
        guard authRequired == false || feathers.authorized else {
            print("Should Have Authorized Connection To Emit")
            throw FeathersError.connectionError(reason: "Not authorized")
        }
        
        feathers.socket.emit(event, with: data)
    }
    
    /** 
     - parameter id: id of requested object (FeathersObjectID)
     - parameter object: request object containing additional info (FeathersRequestObject)
     - throws: `FeathersError`
    */
    
    public func emitWithAck(id: FeathersObjectID? = nil,
                            _ object: FeathersRequestObject? = nil,
                            completion: @escaping ResponseHandler) throws {
        let data = dataUsing(id: id,
                             object: object,
                             objects: nil)
        do { try emitWithAck(data: data,
                             completion: completion)
        } catch {
            throw error
        }
    }
    
    public func emitWithAck(id: FeathersObjectID? = nil,
                            _ objects: [FeathersRequestObject],
                            completion: @escaping ResponseHandler) throws {
        let data = dataUsing(id: id,
                             object: nil,
                             objects: objects)
        do { try emitWithAck(data: data,
                             completion: completion)
        } catch {
            throw error
        }
    }
    
    func emitWithAck(data: SocketRequestData,
                     completion: @escaping ResponseHandler) throws {
        guard feathers.connected else {
            print("Should Be Connected To Emit")
            throw FeathersError.connectionError(reason: "Not connected")
        }

        guard authRequired == false || feathers.authorized else {
            print("Should Have Authorized Connection To Emit")
            throw FeathersError.connectionError(reason: "Not authorized")
        }
        
        let callback: OnAckCallback? = feathers.socket.emitWithAck(event, with: data)
        
        guard callback != nil else {
            print("Should Have Valid Connection Callback Object To Emit ")
            throw FeathersError.emitterError(reason: "No valid callback")
        }
        
        callback?.timingOut(after: feathers.timeout, callback: { (data) in
            let response = self.responseParser.parse(responseData: data)
            print("=== received response \(response)")
            completion(response)
        })
    }
    
    fileprivate func dataUsing(id: FeathersObjectID?,
                               object: FeathersRequestObject?,
                               objects: FeathersRequestArray?) -> SocketRequestData {
        var result: SocketRequestData = []
        
        if let id = id {
            result.append(id)
        }
        
        if let object = object {
            result.append(object)
        }
        
        if let objects = objects {
            result.append(objects)
        }
        
        return result
    }
}
