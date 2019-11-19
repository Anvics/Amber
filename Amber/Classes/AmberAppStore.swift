//
//  AmberAppState.swift
//  TestFrameworksProject
//
//  Created by Nikita Arkhipov on 04.05.2018.
//  Copyright © 2018 Nikita Arkhipov. All rights reserved.
//

import Foundation
import ReactiveKit
import Bond

public protocol AmberAppStoreBase {
    var routePerformer: AmberRoutePerformer! { get set }
}

public protocol AmberAppStore: AmberAppStoreBase {
    associatedtype Reducer: AmberAppReducer
    typealias ActionBlock = (Reducer.Action) -> Void

    var reducer: Reducer { get }
    func currentState() -> Reducer.State
    func updateState(newState: Reducer.State)
}

public extension AmberAppStore{
    func perform(action: Reducer.Action){
        initiateChangeState(action: action) { (state, isCancelled, actionPerf) in
            self.reducer.reduce(action: action, state: state, isCancelled: isCancelled, performAction: actionPerf)
        }
    }
    
    fileprivate func initiateChangeState(action: AmberAction, newState: @escaping (Reducer.State, Bool, @escaping ActionBlock) -> Reducer.State){
        processAction(action) { isCancelled in self.changeState(action: action, isCancelled: isCancelled, newState: newState) }
    }
    
    fileprivate func processAction(_ action: AmberCancellable, actionBlock: @escaping (Bool) -> Void){
        Amber.process(state: currentState(), beforeEvent: action)
        Amber.perform(event: action, onState: currentState(), route: routePerformer) { isCancelled in
            if isCancelled && !action.shouldProcessIfCancelled { return }
            actionBlock(isCancelled)
            Amber.process(state: self.currentState(), afterEvent: action, route: self.routePerformer)
        }
    }
    
    fileprivate func changeState(action: AmberAction, isCancelled: Bool, newState: (Reducer.State, Bool, @escaping ActionBlock) -> Reducer.State){
        let stateToUse = currentState()
        var isPerformed = false
        var delayedActions: [Reducer.Action] = []
        
        let ns = newState(stateToUse, isCancelled, { a in
            if isPerformed{ self.perform(action: a) }
            else { delayedActions.append(a) }
        })
        
        updateState(newState: ns)
        
        isPerformed = true
        delayedActions.forEach(perform)
    }
}
