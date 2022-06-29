//
//  NewListUseCaseProvider.swift
//  Domain
//
//  Created by Reyhan Rifqi Azzami on 30/05/22.
//  Copyright © 2022 Adrena Teknologi Indonesia. All rights reserved.
//

import RxSwift
import Platform

public struct NewListUseCaseProvider<R, CloudService: ServiceType, CacheService: ServiceType, Provider: Cache, ServiceResponse: NewResponseListType>: UseCase
    where
    CloudService.R == R, CloudService.T == ServiceResponse, CloudService.E == Error,
    CacheService.R == R, CacheService.T == ServiceResponse, CacheService.E == Error,
    Provider.R == R, Provider.T == ServiceResponse.T {
    
    public typealias R = R
    public typealias T = ServiceResponse
    public typealias E = Error
    
    private let _service: CloudService
    private let _cacheService: CacheService
    private let _cache: Provider
    private let _activityIndicator: ActivityIndicator?
    private let _forceReloadFromCache: Bool
    private let _insertToCache: Bool
    
    public init(service: CloudService, cacheService: CacheService, cache: Provider, forceReloadFromCache: Bool = false, insertToCache: Bool = true, activityIndicator: ActivityIndicator?) {
        _service = service
        _cacheService = cacheService
        _cache = cache
        _activityIndicator = activityIndicator
        _forceReloadFromCache = forceReloadFromCache
        _insertToCache = insertToCache
    }
    
    public func executeCache(request: R?) -> Observable<Result<ServiceResponse, Error>> {
        return _cacheService.get(request: request)
    }
    
    public func execute(request: R?) -> Observable<Result<ServiceResponse, Error>> {
        let forceReload: Bool
        let page: Int
        
        if let request = request as? ListRequestType {
            forceReload = request.forceReload
            page = request.page
        } else {
            forceReload = true
            page = 0
        }
        
        if _cache.isCacheAvailable(request: request) == true && !forceReload {
            return _cacheService.get(request: request)
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
            
            let result = response
                .observeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                .do(onNext: { result in
                    if case let Result.success(type) = result {
                        
                        if page <= 1 {
                            self._cache.removeAll()
                        }
                        
                        if _insertToCache{
                            if type.data.count > 0 {
                                self._cache.putList(models: type.data)
                            }
                        }
                        
                    }
                })
            
            if _forceReloadFromCache {
                return result.flatMap { _ in
                    self._cacheService.get(request: request)
                }
            } else {
                return result
            }
        }
    }
}
