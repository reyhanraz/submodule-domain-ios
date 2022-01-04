//
//  ListUseCaseProvider.swift
//  Domain
//
//  Created by Fandy Gotama on 18/05/19.
//  Copyright © 2019 Adrena Teknologi Indonesia. All rights reserved.
//

import RxSwift
import Platform

public struct ListUseCaseProvider<R, CloudService: ServiceType, CacheService: ServiceType, Provider: Cache, ServiceResponse: ResponseListType>: UseCase
    where
    CloudService.R == R, CloudService.T == ServiceResponse, CloudService.E == Error,
    CacheService.R == R, CacheService.T == ServiceResponse, CacheService.E == Error,
    Provider.R == R, Provider.T == ServiceResponse.Data.T {
    
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
                        
                        if let list = type.data?.list as? [Pageable] {
                            let paging = Paging(currentPage: type.data?.paging?.currentPage ?? 0,
                                                limitPerPage: type.data?.paging?.limitPerPage ?? 0,
                                                totalPage: type.data?.paging?.totalPage ?? 0)
                            
                            list.forEach {
                                $0.paging = paging
                            }
                        }
                        
                        if page <= 1 {
                            self._cache.removeAll()
                        }
                        
                        if _insertToCache{
                            if let list = type.data?.list {
                                self._cache.putList(models: list)
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
