//
//  UseCaseProvider.swift
//  Domain
//
//  Created by Fandy Gotama on 13/05/19.
//  Copyright © 2019 Adrena Teknologi Indonesia. All rights reserved.
//

import Platform
import RxSwift

public struct UseCaseProvider<Service, R, T>: UseCase where Service: ServiceType, Service.R == R, Service.T == T, Service.E == Error {
    public typealias R = R
    public typealias T = T
    public typealias E = Error
    
    private let _service: Service
    private let _activityIndicator: ActivityIndicator?
    
    public init(service: Service, activityIndicator: ActivityIndicator?) {
        _service = service
        _activityIndicator = activityIndicator
    }
    
    public func executeCache(request: R?) -> Observable<Result<T, Error>> {
        return .empty()
    }
    
    public func execute(request: R?) -> Observable<Result<T, Error>> {
        if let indicator = _activityIndicator {
            return _service.get(request: request).trackActivity(indicator)
        } else {
            return _service.get(request: request)
        }
    }
}
