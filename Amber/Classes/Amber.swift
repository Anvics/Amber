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
    
    func perform(event: Any, route: AmberRoutePerformer, index: Int = 0, completion: @escaping () -> ()){
        if index == middleware.count { completion(); return }
        middleware[index].perform(event: event, route: route) {
            self.perform(event: event, route: route, index: index + 1, completion: completion)
        }
    }
    
    func process(state: Any, afterEvent event: Any, route: AmberRoutePerformer){
        middleware.forEach { $0.process(state: state, afterEvent: event, route: route) }
    }
    
    public static func setInitial<U: AmberController>(screen: U.Type, data: U.StoreState.RequiredData, window: UIWindow!){
        let (vc, _) = AmberControllerHelper.create(type: screen, data: data, input: nil)
        window.rootViewController = vc
        window.makeKeyAndVisible()
    }
    
    public static func setInitial<U: AmberController>(screen: U.Type, window: UIWindow!) where U.StoreState.RequiredData == Void{
        setInitial(screen: screen, data: (), window: window)
    }
}

