//
//  UseCase.swift
//  Domain
//
//  Created by Fandy Gotama on 07/05/19.
//  Copyright © 2019 Adrena Teknologi Indonesia. All rights reserved.
//

import RxSwift
import Platform

public protocol UseCase {
    associatedtype R
    associatedtype T
    associatedtype E
    
    func executeCache(request: R?) -> Observable<Result<T, E>>
    func execute(request: R?) -> Observable<Result<T, E>>
}
