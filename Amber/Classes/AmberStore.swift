//
//  AmberStore.swift
//  TrainBrain
//
//  Created by Nikita Arkhipov on 09.10.2017.
//  Copyright © 2017 Nikita Arkhipov. All rights reserved.
//

import Foundation
import ReactiveKit

public final class AmberStore<Reducer: AmberReducer>{
    var state: Signal<Reducer.State, NoError> { return _state.toSignal().ignoreNil() }
    
    public let action = Subject<Reducer.Action, NoError>()
    public let outputAction = Subject<Reducer.OutputAction, NoError>()
    public let transition = Subject<Reducer.Transition, NoError>()
    
    var outputListener: ((Reducer.OutputAction) -> Void)?
    fileprivate var routePerformer: AmberRoutePerformer!
    
    fileprivate let _state = Property<Reducer.State?>(nil)
    
    fileprivate let reducer: Reducer
    private let router: AmberRouterBlock<Reducer>
    private var isInitialized = false
    
    typealias ActionBlock = (Reducer.Action) -> Void
    typealias OutputActionBlock = (Reducer.OutputAction) -> Void
    typealias TransitionBlock = (Reducer.Transition) -> Void
    
    public init<R: AmberRouter>(reducer: Reducer, router: R) where R.Reducer == Reducer{
        self.reducer = reducer
        self.router = router.perform
        subscribe()
    }
    
    public func initialize(with data: Reducer.State.RequiredData, routePerformer: AmberRoutePerformer){
        if isInitialized { return }
        isInitialized = true
        self.routePerformer = routePerformer
        Amber.appStore?.routePerformer = routePerformer
        sharedInitialize(data: data)
    }
    
    public func currentState() -> Reducer.State{
        guard let state = _state.value else {
            fatalError("Не удалось получить текущее состояние. Если ошибка произошла при запуске приложения, убедитесь в том что в начальном контроллере в самом начале viewDidLoad есть строчка store.initialize(on: self)")
        }
        return state
    }
    
    public func perform(action: Reducer.Action){
        initiateChangeState(action: action) { (state, router, isCancelled, actionPerf, outActionPerf, transitionPerf) in
            self.reducer.reduce(action: action, state: state, isCancelled: isCancelled, performTransition: transitionPerf, performAction: actionPerf, performOutputAction: outActionPerf)
        }
    }
    
    public func performInput(action: Reducer.InputAction){
        initiateChangeState(action: action) { (state, router, isCancelled, actionPerf, outActionPerf, _) in
            self.reducer.reduceInput(action: action, state: state, isCancelled: isCancelled, performAction: actionPerf, performOutputAction: outActionPerf)
        }
    }
    
    public func performOutput(action: Reducer.OutputAction){
        processAction(action) { isCancelled in
            self.outputListener?(action)
        }
    }
    
    public func perform(transition: Reducer.Transition){
        processAction(transition) { isCancelled in
            self.router(transition, self.currentState(), isCancelled, self.routePerformer, self.reducer, self.perform)
        }
    }
}

extension AmberStore{
    fileprivate func subscribe(){
        let _ = action.observeNext { [weak self] in self?.perform(action: $0) }
        let _ = outputAction.observeNext { [weak self] in self?.performOutput(action: $0) }
        let _ = transition.observeNext { [weak self] in self?.perform(transition: $0) }
    }

    fileprivate func processAction(_ action: AmberCancellable, actionBlock: @escaping (Bool) -> Void){
        Amber.process(state: currentState(), beforeEvent: action)
        Amber.perform(event: action, onState: currentState(), route: routePerformer) { isCancelled in
            if isCancelled && !action.shouldProcessIfCancelled { return }
            actionBlock(isCancelled)
            Amber.process(state: self.currentState(), afterEvent: action, route: self.routePerformer)
        }
    }

    fileprivate func initiateChangeState(action: AmberAction, newState: @escaping (Reducer.State, AmberRoutePerformer, Bool, @escaping ActionBlock, @escaping OutputActionBlock, @escaping TransitionBlock) -> Reducer.State){
        processAction(action) { isCancelled in self.changeState(action: action, isCancelled: isCancelled, newState: newState) }
    }
    
    fileprivate func changeState(action: AmberAction, isCancelled: Bool, newState: (Reducer.State, AmberRoutePerformer, Bool, @escaping ActionBlock, @escaping OutputActionBlock, @escaping TransitionBlock) -> Reducer.State){
        let stateToUse = currentState()
        var isPerformed = false
        var delayedActions: [Reducer.Action] = []
        var delayedOutputActions: [Reducer.OutputAction] = []
        var delayedTransitions: [Reducer.Transition] = []
        
        let ns = newState(stateToUse, routePerformer, isCancelled, { a in
            if isPerformed{ self.perform(action: a) }
            else { delayedActions.append(a) }
        }, { a in
            if isPerformed{ self.performOutput(action: a) }
            else { delayedOutputActions.append(a) }
        }, { t in
            if isPerformed { self.perform(transition: t) }
            else{ delayedTransitions.append(t) }
        })
        
        _state.value = ns
        
        isPerformed = true
        delayedActions.forEach(perform)
        delayedOutputActions.forEach(performOutput)
        delayedTransitions.forEach(perform)
    }
    
    fileprivate func sharedInitialize(data: Reducer.State.RequiredData){
        _state.value = Reducer.State(data: data)
        reducer.initialize(state: currentState(), performAction: perform, performOutputAction: performOutput)
    }
}



