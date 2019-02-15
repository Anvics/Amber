//
//  Amber.swift
//  TrainBrain
//
//  Created by Nikita Arkhipov on 09.10.2017.
//  Copyright © 2017 Nikita Arkhipov. All rights reserved.
//

import UIKit

public protocol AmberState: CustomStringConvertible {
    associatedtype RequiredData
    
    init(data: RequiredData)
}

public extension AmberState where RequiredData == Void{
    init(){
        self.init(data: ())
    }
}

public protocol AmberCancellable{
    var shouldProcessIfCancelled: Bool { get }
}

public extension AmberCancellable{
    var shouldProcessIfCancelled: Bool { return false }
}

public protocol AmberTransition: AmberCancellable { }

public protocol AmberAction: AmberCancellable { }

public enum AmberEither<A, B>{
    case first(A)
    case second(B)
}

public class Amber{
    private(set) static var middleware: [AmberMiddleware] = []
    static var appStore: AmberAppStoreBase?
    
    static func process(state: Any, beforeEvent event: Any){
        middleware.forEach { $0.process(state: state, beforeEvent: event) }
    }
    
    static func perform(event: Any, onState state: Any, route: AmberRoutePerformer, index: Int = 0, completion: @escaping (Bool) -> ()){
        if index == middleware.count { completion(false); return }
        middleware[index].perform(event: event, onState: state, route: route, completeEvent: {
            self.perform(event: event, onState: state, route: route, index: index + 1, completion: completion)
        }, cancelEvent: {
            completion(true)
        })
    }
    
    static func process(state: Any, afterEvent event: Any, route: AmberRoutePerformer){
        middleware.forEach { $0.process(state: state, afterEvent: event, route: route) }
    }
    
    public static func addMiddleware(_ middleware: AmberMiddleware...){
        self.middleware.append(contentsOf: middleware)
    }
    
    public static func setAppStore(_ store: AmberAppStoreBase){
        appStore = store
    }
    
    public static func setInitial<Module: AmberController>(module: Module.Type, data: Module.Reducer.State.RequiredData, window: UIWindow!){
        let (vc, _) = AmberControllerHelper.create(module: module, data: data, outputListener: nil)
        window.rootViewController = vc
        window.makeKeyAndVisible()
    }

    public static func setInitial<Module: AmberController>(module: Module.Type, window: UIWindow!) where Module.Reducer.State.RequiredData == Void{
        setInitial(module: module, data: (), window: window)
    }
    
    public static func setBaseInitial(storyboardFile: String, storyboardID: String, window: UIWindow!){
        let vc = UIStoryboard(name: storyboardFile, bundle: nil).instantiateViewController(withIdentifier: storyboardID)
        window.rootViewController = vc
        window.makeKeyAndVisible()
    }
}

