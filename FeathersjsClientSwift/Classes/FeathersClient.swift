//
//  Connection.swift
//  doroga
//
//  Created by Bucha Kanstantsin on 7/11/16.
//  Copyright © 2016 Bucha Kanstantsin. All rights reserved.
//

import Foundation
import SocketIO


public typealias SocketRequestData = [SocketData]
public typealias FeathersRequestObject = [String: SocketData]
public typealias FeathersRequestArray = [FeathersRequestObject]

public typealias SocketResponseData = [Any]
public typealias FeathersResponseObject = [String: Any]
public typealias FeathersResponseArray = [FeathersResponseObject]

public enum FeathersError: Error {
    case authError(reason: String)
    case emitterError(reason: String)
    case receiverError(reason: String)
    case connectionError(reason: String)
    case serverError(reason: String, type: String, code: Int)
    case databaseError(reason: String, SQL: String, SQLError: FeathersResponseObject)
    public func reason() -> String {
        switch self {
            case let .authError(reason):
                return reason
            case let .emitterError(reason):
                return reason
            case let .receiverError(reason):
                return reason
            case let .connectionError(reason):
                return reason
            case let .serverError(reason, _, _):
                return reason
            case let .databaseError(reason, _, _):
                return reason
        }
    }
}

public enum FeathersResponse {
    case error(FeathersError)
    case array(FeathersResponseArray)
    case object(FeathersResponseObject)
    case raw(SocketResponseData)
    
    public func extractError() -> FeathersError? {
        if case let FeathersResponse.error(result) = self {
            return result
        } else {
            return nil
        }
    }
    
    public func extractObject() -> FeathersResponseObject? {
        if case let FeathersResponse.object(result) = self {
            return result
        } else {
            return nil
        }
    }
}

public typealias EventHandler = (_ response: FeathersResponse, _ ack: SocketAckEmitter?) -> ()
public typealias ResponseHandler = (_ response: FeathersResponse) -> ()

open class FeathersClient {
    
    public let token: String
    let socket: SocketIOClient
    
    var scheduledAuthSucceedReceiver: Receiver?
    var scheduledAuthFailedReceiver: Receiver?
    
    public var connected: Bool {
        let result = socket.status == SocketIOClientStatus.connected
        return result
    }
    
    public var authorized = false
    
    public var debugModeEnabled = false
    
    public let feathersURL: URL
    public let namespace: String?
    public var timeout: UInt64
    
    public init(URL: URL,
                namespace: String?,
                token: String,
                timeout: UInt64,
                debugMode: Bool = false) {
        self.feathersURL = URL
        self.namespace = namespace
        self.token = token
        self.timeout = timeout
        self.debugModeEnabled = debugMode
        
        let configuration: SocketIOClientConfiguration = [ .forcePolling(false)]
        self.socket = SocketIOClient(socketURL: feathersURL,
                                     config: configuration)
    }
    
    public var onConnect: EventHandler?
    public var onDisconnect: EventHandler?
    public var onError: EventHandler?
    public var onUnathorize: EventHandler?
    
    fileprivate var connectReceiver: Receiver?
    fileprivate var disconnectReceiver: Receiver?
    fileprivate var errorReceiver: Receiver?
    fileprivate var unauthorizeReceiver: Receiver?
    
    public func connect() {
        initiateCoreEventsReceiving()
        socket.connect()
    }
    
    func initiateCoreEventsReceiving() {
        
        connectReceiver = Receiver(feathers: self,
                                   event: "connect")
        do { try
            connectReceiver?.startListening() { [unowned self] (response, ack) in
                guard self.onConnect != nil else { return }
                self.onConnect!(response, ack)
            }
        } catch {
            print("===== connectReceiver: \(error)")
        }
        
        
        disconnectReceiver = Receiver(feathers: self,
                                      event: "disconnect")
        do { try
            disconnectReceiver?.startListening() { [unowned self] (response, ack) in
                guard self.onDisconnect != nil else { return }
                self.onDisconnect!(response, ack)
            }
        } catch {
            print("===== disconnectReceiver: \(error)")
        }
        
        errorReceiver = Receiver(feathers: self,
                                 event: "error")
        do { try
            errorReceiver?.startListening(){ [unowned self] (response, ack) in
                guard self.onError != nil else { return }
                self.onError!(response, ack)
            }
        } catch {
            print("===== errorReceiver: \(error)")
        }
        
        unauthorizeReceiver = Receiver(feathers: self,
                                       event: "unauthorized")
        
        do { try
            unauthorizeReceiver?.startListening() { [unowned self] (response, ack) in
                self.authorized = false
                guard self.onUnathorize != nil else { return }
                self.onUnathorize!(response, ack)
            }
        } catch {
            print("===== unauthorizeReceiver: \(error)")
        }
    }
    
    public func authorize(_ auth: UserAuthProtocol,
                          completion: @escaping ResponseHandler) throws {
        guard connected else {
            let reason = "Should Be Connected To Authorize User "
            throw FeathersError.connectionError(reason: reason)
        }
        
        scheduledAuthSucceedReceiver = Receiver(feathers: self,
                                                event: "authenticated")
        do { try
            scheduledAuthSucceedReceiver?.startListening() { [unowned self] (response, ack) in
                self.scheduledAuthSucceedReceiver = nil
                self.scheduledAuthFailedReceiver = nil
                
                self.authorized = true
                completion(response)
            }
        } catch {
            print("===== scheduledAuthSucceedReceiver: \(error)")
        }
    
        scheduledAuthFailedReceiver =  Receiver(feathers: self,
                                                event: "unauthorized")
        do { try
            scheduledAuthFailedReceiver?.startListening() { [unowned self] (response, ack) in
                self.scheduledAuthSucceedReceiver = nil
                self.scheduledAuthFailedReceiver = nil
                
                completion(response)
            }
        } catch {
            print("===== scheduledAuthFailedReceiver: \(error)")
        }
        
        
        let emitter = Emitter(feathers: self,
                              event: "authenticate",
                              authRequired: false)
        
        do { try
            emitter.emit(auth.requestObject())
        } catch {
            self.scheduledAuthSucceedReceiver = nil
            self.scheduledAuthFailedReceiver = nil
            
            print("====== Authorize Emitter: \(error)")
            throw error
        }
    }
}
