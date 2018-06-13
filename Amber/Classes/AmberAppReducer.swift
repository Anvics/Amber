//
//  AmberAppReducer.swift
//  TestFrameworksProject
//
//  Created by Nikita Arkhipov on 04.05.2018.
//  Copyright © 2018 Nikita Arkhipov. All rights reserved.
//

import Foundation

public protocol AmberAppReducer{
    associatedtype State: AmberState
    associatedtype Action: AmberAction
    
    typealias ActionBlock = (Action) -> Void
    
    func initialize(state: State, performAction: @escaping ActionBlock)
    
    func reduce(action: Action, state: State, isCancelled: Bool, performAction: @escaping ActionBlock) -> State
}
