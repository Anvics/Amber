//
//  AmberReducer.swift
//  TrainBrain
//
//  Created by Nikita Arkhipov on 09.10.2017.
//  Copyright © 2017 Nikita Arkhipov. All rights reserved.
//

import Foundation

public protocol AmberReducer{
    associatedtype State: AmberState
    associatedtype Action: AmberAction
    associatedtype OutputAction: AmberAction
    associatedtype InputAction: AmberAction
    associatedtype Transition: AmberTransition

    typealias ActionBlock = (Action) -> Void
    typealias InputActionListener = (InputAction) -> Void
    typealias OutputActionListener = (OutputAction) -> Void
    typealias TransitionBlock = (Transition) -> Void
    
    func initialize(state: State, performAction: @escaping ActionBlock, performOutputAction: @escaping OutputActionListener)
    
    func reduce(action: Action, state: State, performTransition: @escaping TransitionBlock, performAction: @escaping ActionBlock, performOutputAction: @escaping OutputActionListener) -> State
    
    func reduceInput(action: InputAction, state: State, performAction: @escaping ActionBlock, performOutputAction: @escaping OutputActionListener) -> State
}

public extension AmberReducer{
    public func initialize(state: State, performAction: @escaping ActionBlock, performOutputAction: @escaping OutputActionListener){ }
    
    public func reduceInput(action: InputAction, state: State, performAction: @escaping ActionBlock, performOutputAction: @escaping OutputActionListener) -> State{ return state }
}
