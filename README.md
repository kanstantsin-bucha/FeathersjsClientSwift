# FeathersjsClientSwift

[![CI Status](http://img.shields.io/travis/Kanstantsin Bucha/FeathersjsClientSwift.svg?style=flat)](https://travis-ci.org/Kanstantsin Bucha/FeathersjsClientSwift)
[![Version](https://img.shields.io/cocoapods/v/FeathersjsClientSwift.svg?style=flat)](http://cocoapods.org/pods/FeathersjsClientSwift)
[![License](https://img.shields.io/cocoapods/l/FeathersjsClientSwift.svg?style=flat)](http://cocoapods.org/pods/FeathersjsClientSwift)
[![Platform](https://img.shields.io/cocoapods/p/FeathersjsClientSwift.svg?style=flat)](http://cocoapods.org/pods/FeathersjsClientSwift)

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## HOWTO use http transport

add to your app info plist

```
<key>NSAppTransportSecurity</key>
	<dict>
		<key>NSAllowsArbitraryLoads</key>
		<true/>
		<key>NSExceptionDomains</key>
		<dict>
			<key>127.0.0.1</key>
			<dict>
				<key>NSIncludesSubdomains</key>
				<true/>
				<key>NSTemporaryExceptionAllowsInsecureHTTPLoads</key>
				<true/>
				<key>NSTemporaryExceptionMinimumTLSVersion</key>
				<string>TLSv1.1</string>
			</dict>
			<key>featherstest.herokuapp.com</key>
			<dict>
				<key>NSIncludesSubdomains</key>
				<true/>
				<key>NSTemporaryExceptionAllowsInsecureHTTPLoads</key>
				<true/>
				<key>NSTemporaryExceptionMinimumTLSVersion</key>
				<string>TLSv1.1</string>
			</dict>
		</dict>
	</dict>
```

## HOWTO connect

```
 // TODO: Please change to your server Socket IO URL
        self.feathers = FeathersClient(URL: URL(string: "http://feathers")!,
                                       namespace: nil,
                                       token: "sdfsdfsdf",
                                       timeout: 60)
        
        let auth = UserAuth(email: "e@mail.com", password: "pass5")
        
        guard auth != nil else {
            print("Email should be valid and password length should be more than 5 symbols")
            return
        }
        
        feathers?.onConnect = { [unowned self] response, ack in
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

```

## HOWTO send event (create user)

```

 let object: FeathersRequestObject = ["email": "e@mail.com",
                                      "password" : "pass5"]
        let emitter = Emitter(feathers: self.feathers!,
                              event: "users::create",
                              authRequired: false)
        
        do { try emitter.emitWithAck(object) {  [unowned self] (response) in
            let error = response.extractError()
            guard error == nil else {
                print("Creation error error: \r\n \(error)")
                return
            }
            let object = response.extractObject()
            // you stuff
            }
        } catch {
            print("Connection error: \r\n \(error)") 
        }
```

## HOWTO receive event (unauthorization event)

```
 authFailedReceiver =  Receiver(feathers: self.feathers!,
                               event: "unauthorized")
        do { try
            self.authFailedReceiver.startListening() { (response, ack) in
            let object = response.extractObject()
                print("Received unauthentification event \(object)")
            }
        } catch {
            print("===== authFailedReceiver has error: \(error)")
        }

```

## Requirements

## Installation

FeathersjsClientSwift is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "FeathersjsClientSwift"
```

## Author

Kanstantsin Bucha, truebucha@gmail.com

## License

FeathersjsClientSwift is available under the MIT license. See the LICENSE file for more info.
