//
//  ViewController.swift
//  FeathersjsClientSwift
//
//  Created by Kanstantsin Bucha on 09/15/2016.
//  Copyright (c) 2016 Kanstantsin Bucha. All rights reserved.
//

import UIKit
import FeathersjsClientSwift


class ViewController: UIViewController {

    var feathers: FeathersClient?
    var authFailedReceiver: Receiver?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        connect()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func connect() {
        // TODO: Please change to your server Socket IO URL
        self.feathers = FeathersClient(URL: URL(string: "http://localhost:3030")!,
                                       namespace: nil,
                                       token: "sdfsdfsdf",
                                       timeout: 60)
        
        let auth = UserAuth(email: "e@mail.com", password: "pass5")
        
        guard auth != nil else {
            print("Email should be valid and password length should be more than 5 symbols")
            return
        }
        
        feathers?.onConnect = { [unowned self] response, ack in
            self.createUser()
            
            do { try self.feathers?.authorize(auth!) { (response) in
                let error = response.extractError()
                guard error == nil else {
                    print("Authentification error: \r\n \(error)")
                    return
                }
                
                let object = response.extractObject()?["data"] as? FeathersResponseObject
                let ID = object?["id"]
                let userID = ID as? Int
                
                guard userID != nil else {
                    let reason = NSLocalizedString("INVALID_USER_ID", comment: "")
                    print("Authentification error: \r\n \(reason)")
                    return
                }
                print("Signed in as user with id \(userID)")
                // Do you stuff here
                }
            } catch {
                print("Connection error: \r\n \(error)")
            }
        }
        
        feathers?.onError = { response, ack in
            if case let FeathersResponse.error(error) = response {
                print("Connection error: \r\n \(error)")    
            }
        }
        
        feathers?.onDisconnect = { response, ack in
            print("Connection disconnect")
        }
        
        feathers?.onUnathorize = { response, ack in
            print("Connection unauthorized")
        }
        
        authFailedReceiver =  Receiver(feathers: self.feathers!,
                               event: "unauthorized")
        do { try
            self.authFailedReceiver?.startListening() { (response, ack) in
            let object = response.extractObject()
                print("Received unauthentification event \(object)")
            }
        } catch {
            print("===== authFailedReceiver has error: \(error)")
        }
                
        feathers?.connect()
        

    }
    
    func createUser() {
        let object: FeathersRequestObject = ["email": "e@mail.com",
                                             "password" : "pass5"]
        let emitter = Emitter(feathers: self.feathers!,
                              event: "users::create",
                              authRequired: false)
        
        do { try emitter.emitWithAck(object) { (response) in
            let error = response.extractError()
            guard error == nil else {
                print("Creation error error: \r\n \(error)")
                return
            }
            let object = response.extractObject()
            print("Received \(object)")
            // you stuff
            }
        } catch {
            print("Connection error: \r\n \(error)") 
        }

    }
}

