//
//  AmberDelayMiddleware.swift
//  TestFrameworksProject
//
//  Created by Nikita Arkhipov on 04.05.2018.
//  Copyright © 2018 Nikita Arkhipov. All rights reserved.
//

import Foundation

public protocol AmberDelayable{
    var delaySeconds: Double? { get }
}

public class AmberDelayMiddleware: AmberMiddleware{
    public init(){}
    
    public func perform(event: Any, onState state: Any, route: AmberRoutePerformer, completeEvent: @escaping () -> (), cancelEvent: @escaping () -> ()){
        guard let delayable = event as? AmberDelayable, let seconds = delayable.delaySeconds else { completeEvent(); return }
        let delayTime = DispatchTime.now() + Double(Int64(seconds * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
        DispatchQueue.main.asyncAfter(deadline: delayTime) {
            completeEvent()
        }
    }
}
