//
//  SinchService.swift
//  Moon
//
//  Created by Evan Noble on 12/5/16.
//  Copyright © 2016 Evan Noble. All rights reserved.
//

import Foundation
import SinchVerification
import RxSwift

enum SMSValidationResponse {
    case Success
    case Error(error: String)
}

protocol SMSValidationService {
    mutating func sendVerificationCodeTo(PhoneNumber phoneNumber: String, CountryCode countryCode: String) -> Observable<SMSValidationResponse>
    func verifyNumberWith(Code code: String) -> Observable<SMSValidationResponse>
}

class SinchService: SMSValidationService {
    
    private let sinchAPIKey = "1c4d1e22-0863-479a-8d15-4ecc6d2f6807"
    private var verification: SINVerificationProtocol?
    
    func sendVerificationCodeTo(PhoneNumber phoneNumber: String, CountryCode countryCode: String) -> Observable<SMSValidationResponse> {
        
        return Observable.create({ (observer) -> Disposable in
            // Get user's current region by carrier info
            let defaultRegion = SINDeviceRegion.currentCountryCode()
            do {
                let phoneNumber = try SINPhoneNumberUtil().parse(phoneNumber, defaultRegion: defaultRegion)
                let phoneNumberInE164 = SINPhoneNumberUtil().formatNumber(phoneNumber, format: .E164)
                let verification = SINVerification.SMSVerificationWithApplicationKey(self.sinchAPIKey, phoneNumber: phoneNumberInE164)
                // retain the verification instance
                self.verification = verification
                verification.initiateWithCompletionHandler({(success: Bool, error: NSError?) -> Void in
                    if success {
                        observer.onNext(.Success)
                        observer.onCompleted()
                    } else {
                        observer.onNext(.Error(error: "Failure to send validation"))
                        observer.onCompleted()
                    }
                })
            } catch {
                observer.onNext(.Error(error: "Failure to format phone number"))
                observer.onCompleted()
            }
            return AnonymousDisposable {
                
            }
        })
    }
    
    func verifyNumberWith(Code code: String) -> Observable<SMSValidationResponse> {
        return Observable.create({ (observer) -> Disposable in
            self.verification!.verifyCode(code, completionHandler: {(success: Bool, error: NSError?) -> Void in
                if success {
                    observer.onNext(.Success)
                    observer.onCompleted()
                } else {
                    observer.onNext(.Error(error: "Failure to verify code"))
                    observer.onCompleted()
                }
            })
            return AnonymousDisposable {
                
            }
        })
    }
}