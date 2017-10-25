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

public protocol AmberTransition { }

public protocol AmberAction { }

public enum AmberEither<A, B>{
    case first(A)
    case second(B)
}

public class Amber{
    public static let main = Amber()
    
    private(set) var middleware: [AmberMiddleware] = []
    
    public func registerSharedMiddleware(_ sharedMiddleware: AmberMiddleware...){
        for m in sharedMiddleware{
            middleware.append(m)
        }
    }
    
    func process(state: Any, beforeEvent event: Any){
        middleware.forEach { $0.process(state: state, beforeEvent: event) }
    }
    
    func perform(event: Any, onState state: Any, route: AmberRoutePerformer, index: Int = 0, completion: @escaping () -> ()){
        if index == middleware.count { completion(); return }
        middleware[index].perform(event: event, onState: state, route: route) {
            self.perform(event: event, onState: state, route: route, index: index + 1, completion: completion)
        }
    }
    
    func process(state: Any, afterEvent event: Any, route: AmberRoutePerformer){
        middleware.forEach { $0.process(state: state, afterEvent: event, route: route) }
    }
    
    public static func setInitial<Module: AmberController>(module: Module.Type, data: Module.State.RequiredData, window: UIWindow!){
        let (vc, _) = AmberControllerHelper.create(module: module, data: data, outputListener: nil)
        window.rootViewController = vc
        window.makeKeyAndVisible()
    }
    
    public static func setInitial<Module: AmberController>(module: Module.Type, window: UIWindow!) where Module.State.RequiredData == Void{
        setInitial(module: module, data: (), window: window)
    }
}

