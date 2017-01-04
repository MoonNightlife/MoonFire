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
    case Error(error: NSError)
}

typealias CountryCode = String
protocol SMSValidationService {
    func sendVerificationCodeTo(PhoneNumber phoneNumber: String) -> Observable<SMSValidationResponse>
    func verifyNumberWith(Code code: String) -> Observable<SMSValidationResponse>
    func formatPhoneNumberForGuiFrom(String string: String) -> String?
    func formatPhoneNumberForStorageFrom(String string: String) -> String?
}

class SinchService: SMSValidationService {
    
    private let sinchAPIKey = "1c4d1e22-0863-479a-8d15-4ecc6d2f6807"
    private var verification: SINVerificationProtocol?
    
    func formatPhoneNumberForGuiFrom(String string: String) -> String? {
        do {
            let phoneNumber = try SINPhoneNumberUtil().parse(string, defaultRegion: getDevicesCountryCode())
            return SINPhoneNumberUtil().formatNumber(phoneNumber, format: .National)
        } catch {
            return nil
        }
    }
    
    func formatPhoneNumberForStorageFrom(String string: String) -> String? {
        do {
            let phoneNumber = try SINPhoneNumberUtil().parse(string, defaultRegion: getDevicesCountryCode())
            return SINPhoneNumberUtil().formatNumber(phoneNumber, format: .E164)
        } catch {
            return nil
        }
    }
    
    private func getDevicesCountryCode() -> CountryCode {
        // Get user's current region by carrier info
        return SINDeviceRegion.currentCountryCode()
    }
    
    func sendVerificationCodeTo(PhoneNumber phoneNumber: String) -> Observable<SMSValidationResponse> {
        
        return Observable.create({ (observer) -> Disposable in
            let defaultRegion = self.getDevicesCountryCode()
            do {
                let phoneNumber = try SINPhoneNumberUtil().parse(phoneNumber, defaultRegion: defaultRegion)
                let phoneNumberInE164 = SINPhoneNumberUtil().formatNumber(phoneNumber, format: .E164)
                let verification = SINVerification.SMSVerificationWithApplicationKey(self.sinchAPIKey, phoneNumber: phoneNumberInE164)
                // retain the verification instance
                self.verification = verification
                verification.initiateWithCompletionHandler({(success: Bool, error: NSError?) -> Void in
                    if success {
                        observer.onNext(.Success)
                    } else {
                        observer.onNext(.Error(error: SMSValidationError.VerificationError))
                    }
                    observer.onCompleted()
                })
            } catch {
                observer.onNext(.Error(error: SMSValidationError.FomattingError))
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
                } else {
                    observer.onNext(.Error(error: SMSValidationError.ValidationError))
                }
                observer.onCompleted()
            })
            return AnonymousDisposable {
                
            }
        })
    }
}