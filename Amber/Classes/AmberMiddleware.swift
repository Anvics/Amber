//
//  AmberMiddleware.swift
//  TrainBrain
//
//  Created by Nikita Arkhipov on 10.10.2017.
//  Copyright © 2017 Nikita Arkhipov. All rights reserved.
//

import Foundation

public protocol AmberMiddleware{
    func process(state: Any, beforeEvent event: Any)
    
    func perform(event: Any, onState state: Any, route: AmberRoutePerformer, performBlock: @escaping () -> ())
    
    func process(state: Any, afterEvent event: Any, route: AmberRoutePerformer)
}

public extension AmberMiddleware{
    public func process(state: Any, beforeEvent event: Any) { }
    
    public func perform(event: Any, onState state: Any, route: AmberRoutePerformer, performBlock: @escaping () -> ()){ performBlock() }
    
    public func process(state: Any, afterEvent event: Any, route: AmberRoutePerformer){ }
}

public class AmberLoggingMiddleware: AmberMiddleware{
    public init(){}
    
    public func process(state: Any, afterEvent event: Any, route: AmberRoutePerformer){
        print("----------------------------------------")
        print("\(type(of: event)).\(event) -> \(state)")
    }
}
