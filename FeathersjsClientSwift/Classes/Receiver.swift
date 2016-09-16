//
//  Receiver.swift
//  doroga
//
//  Created by truebucha on 8/24/16.
//  Copyright © 2016 Bucha Kanstantsin. All rights reserved.
//

import Foundation

open class Receiver {
    
    public unowned var feathers: FeathersClient
    public let event: String
    public let responseParser: ResponseParser
    public var handler: EventHandler?
    public let authRequired: Bool
    public let connectionRequired: Bool 
    var handle: UUID?
    public var listening: Bool {
        let result = handle != nil
        return result
    }
    
    public init(feathers: FeathersClient,
                event: String,
                authRequired: Bool = false,
                connectionRequired: Bool = false,
                responseParser: ResponseParser = DefaultParser()) {
        self.feathers = feathers
        self.event = event
        self.connectionRequired = connectionRequired
        self.authRequired = authRequired
        self.responseParser = responseParser
    }
    
    deinit {
        stopListening()
    }
    
    public func startListening(_ handler: @escaping EventHandler) throws {
        guard connectionRequired == false || feathers.connected else {
            print("To Listen Should Have Feathers Connected")
            throw FeathersError.connectionError(reason: "Not Connected")
        }
        
        guard authRequired == false || feathers.authorized else {
            print("Should Have Authorized Connection To listen")
            throw FeathersError.connectionError(reason: "Not Authorized")
        }
        
        self.handler = handler
        
        handle = feathers.socket.on(event) { [unowned self] (data, ack) in
            let response = self.responseParser.parse(responseData: data)
            self.handler?(response, ack)
        }
        
        guard handle != nil else {
            self.handler = nil
            print("To Listen Should Have Feathers Handle")
            throw FeathersError.receiverError(reason: "No Valid Handle")
        }
    }
    
    public func stopListening() {
        guard handle != nil else {
            print("Receiver not listening. Skip stop listening action")
            return;
        }
        
        feathers.socket.off(id: handle!)
        handle = nil
        handler = nil
    }
    
}
