//
//  GetDetailUseCaseProvider.swift
//  Domain
//
//  Created by Fandy Gotama on 31/08/19.
//  Copyright © 2019 Adrena Teknologi Indonesia. All rights reserved.
//

import RxSwift
import Platform

public struct GetDetailUseCaseProvider<R, CloudService: ServiceType, CacheService: ServiceType, Provider: Cache, ServiceResponse: ResponseType>: UseCase
    where
    CloudService.R == R, CloudService.T == ServiceResponse, CloudService.E == Error,
    CacheService.R == R, CacheService.T == ServiceResponse, CacheService.E == Error,
    Provider.R == R {
    
    public typealias R = R
    public typealias T = ServiceResponse
    public typealias E = Error
    
    private let _service: CloudService
    private let _cacheService: CacheService?
    private let _cache: Provider?
    private let _activityIndicator: ActivityIndicator?
    private let _forceReload: Bool
    
    public init(service: CloudService, cacheService: CacheService?, cache: Provider?, forceReload: Bool = false, activityIndicator: ActivityIndicator?) {
        _service = service
        _cacheService = cacheService
        _cache = cache
        _activityIndicator = activityIndicator
        _forceReload = forceReload
    }
    
    public func executeCache(request: R?) -> Observable<Result<ServiceResponse, Error>> {
        return _cacheService?.get(request: request) ?? .empty()
    }
    
    public func execute(request: R?) -> Observable<Result<ServiceResponse, Error>> {
        if let cache = _cache, let service = _cacheService, cache.isCacheAvailable(request: request) == true && !_forceReload {
            return service.get(request: request)
        } else {
            let response: Observable<Result<ServiceResponse, Error>>
            
            if let indicator = _activityIndicator {
                response = _service
                    .get(request: request)
                    .trackActivity(indicator)
            } else {
                response = _service
                    .get(request: request)
            }
            
            return response
        }
    }
}
