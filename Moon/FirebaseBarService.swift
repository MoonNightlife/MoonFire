//
//  FirebaseBarService.swift
//  Moon
//
//  Created by Evan Noble on 2/2/17.
//  Copyright © 2017 Evan Noble. All rights reserved.
//

import Foundation
import RxSwift

protocol BarService {
    func getBarInformationFor(BarID barID: String) -> Observable<BackendResult<Bar2>>
}

struct FirebaseBarService: BarService {
    
    func getBarInformationFor(BarID barID: String) -> Observable<BackendResult<Bar2>> {
        return Observable.create({ (observer) -> Disposable in
            
            return AnonymousDisposable {
                
            }
        })
    }
    
}