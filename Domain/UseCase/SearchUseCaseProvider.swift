//
//  SearchUseCaseProvider.swift
//  Domain
//
//  Created by Fandy Gotama on 29/07/19.
//  Copyright © 2019 Adrena Teknologi Indonesia. All rights reserved.
//

import RxSwift
import Platform

public struct SearchUseCaseProvider<CloudService: ServiceType, CacheService: ServiceType, ServiceRequest, ServiceResponse: ResponseListType>: UseCase
    where
    CloudService.R == ServiceRequest, CloudService.T == ServiceResponse, CloudService.E == Error,
    CacheService.R == ServiceRequest, CacheService.T == ServiceResponse, CacheService.E == Error {
    
    public typealias R = ServiceRequest
    public typealias T = ServiceResponse
    public typealias E = Error
    
    private let _service: CloudService
    private let _cacheService: CacheService?
    private let _activityIndicator: ActivityIndicator?
    
    public init(service: CloudService, cacheService: CacheService?, activityIndicator: ActivityIndicator?) {
        _service = service
        _cacheService = cacheService
        _activityIndicator = activityIndicator
    }
    
    public func executeCache(request: ServiceRequest?) -> Observable<Result<ServiceResponse, CacheService.E>> {
        return _cacheService?.get(request: request) ?? .empty()
    }
    
    public func execute(request: ServiceRequest?) -> Observable<Result<ServiceResponse, CloudService.E>> {
        if let activityIndicator = _activityIndicator {
            return _service.get(request: request).trackActivity(activityIndicator)
        } else {
            return _service.get(request: request)
        }
    }
}


