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
    
    ///После обработки события обязательно вызовите completeEvent() – если обработка прошла успешно, или cancelEvent() – если что-то пошло не так и выполнение события нужно отменить
    func perform(event: Any, onState state: Any, route: AmberRoutePerformer, completeEvent: @escaping () -> (), cancelEvent: @escaping () -> ())
    
    func process(state: Any, afterEvent event: Any, route: AmberRoutePerformer)
}

public extension AmberMiddleware{
    public func process(state: Any, beforeEvent event: Any) { }
    
    public func perform(event: Any, onState state: Any, route: AmberRoutePerformer, completeEvent: @escaping () -> (), cancelEvent: @escaping () -> ()) { completeEvent() }
    
    public func process(state: Any, afterEvent event: Any, route: AmberRoutePerformer){ }
}
