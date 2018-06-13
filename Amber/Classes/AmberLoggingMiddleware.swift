//
//  AmberLoggingMiddleware.swift
//  TestFrameworksProject
//
//  Created by Nikita Arkhipov on 04.05.2018.
//  Copyright © 2018 Nikita Arkhipov. All rights reserved.
//

import Foundation

public class AmberLoggingMiddleware: AmberMiddleware{
    public init(){}
    
    public func process(state: Any, afterEvent event: Any, route: AmberRoutePerformer){
        print("----------------------------------------")
        print("\(type(of: event)).\(event) -> \(state)")
    }
}
