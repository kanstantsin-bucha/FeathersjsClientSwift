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
    
    - Throws: `FeathersError`
    */

    
    public func emit(_ object: FeathersRequestObject? = nil) throws {
        let data = object != nil ? [object!]
                                 : []
        do { try emit(data: data)
        } catch {
            throw error
        }
    }
    
    public func emit(_ objects: [FeathersRequestObject]) throws {
        do { try emit(data: objects)
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
    Send an event to server and receive data from server using acknowledgement
    
    emitter will retain itself until callback will be received or timeout occured
    
    - Throws: `FeathersError`
    */
    
    public func emitWithAck(_ object: FeathersRequestObject? = nil,
                     completion: @escaping ResponseHandler) throws {
        let data = object != nil ? [object!]
                                 : []
        do { try emitWithAck(data: data, completion: completion)
        } catch {
            throw error
        }
    }
    
    public func emitWithAck(_ objects: [FeathersRequestObject],
                     completion: @escaping ResponseHandler) throws {
        do { try emitWithAck(data: objects, completion: completion)
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
            print("Should Have Valid Connection Callback To Emit ")
            throw FeathersError.emitterError(reason: "No valid callback")
        }
        
        callback?(feathers.timeout, { (data) in
            print("=== data \(data)")
            let response = self.responseParser.parse(responseData: data)
            print("=== response \(response)")
            completion(response)
        })
    }
}
