//
//  GRDataManager.swift
//  granular
//
//  Created by Dmitry Babenko on 2019-05-25.
//  Copyright © 2019 Decowareb. All rights reserved.
//

import Foundation

protocol DataManager {
    func getItems(startingIndex: Int?, size: Int?, completion: @escaping([GRItemPresentable]?, Error?) -> Void)
}

class GRDataManager {
    static let shared = GRDataManager()
    
    private var networkManager: NetworkManager
    private var coreDataManager: CoreDataManager
    
    required init(networkManager: NetworkManager = GRNetworkManager.shared,
                  coreDataManager: CoreDataManager = GRCoreDataManager.shared) {
        self.networkManager = networkManager
        self.coreDataManager = coreDataManager
    }
}

extension GRDataManager: DataManager{
    func getItems(startingIndex: Int?, size: Int?, completion: @escaping([GRItemPresentable]?, Error?) -> Void) {
        self.networkManager.getItems { (result) in
            switch result {
            case .success(let itemModels):
                self.coreDataManager.replaceItems(itemModels, completion: { error in
                    if let error = error {
                        completion(nil, error)
                        return
                    }
                    self.coreDataManager.getItems(startingIndex: startingIndex, size: size) { result in
                        switch result {
                        case .success(let items):
                            completion(items, nil)
                        case .failure(let error):
                            completion(nil, error)
                        }
                    }
                })
            case .failure(let networkError):
                self.coreDataManager.getItems(startingIndex: startingIndex, size: size) { result in
                    switch result {
                    case .success(let items):
                        if items?.count == 0 {
                            let items = (0...99).compactMap {GRItemNetworkModel(name: "Item #\($0)", url: "")}
                            completion(items, networkError)
                            return
                        }
                        completion(items, networkError)
                    case .failure(let error):
                        completion(nil, error)
                    }
                }
            }
        }
    }
}
