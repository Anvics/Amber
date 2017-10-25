//
//  AmberRouter.swift
//  TrainBrain
//
//  Created by Nikita Arkhipov on 09.10.2017.
//  Copyright © 2017 Nikita Arkhipov. All rights reserved.
//

import UIKit

enum AmberPresentationType{
    case push, present, show, embed
}

public protocol AmberEmbedder {
    func embed<Module: AmberController>(_ module: Module.Type, data: Module.State.RequiredData, inView view: UIView, outputListener: Module.OutputActionListener?) -> Module.InputActionListener
}

public extension AmberEmbedder{
    func embed<Module: AmberController>(_ module: Module.Type, data: Module.State.RequiredData, inView view: UIView) -> Module.InputActionListener{
        return embed(module, data: data, inView: view, outputListener: nil)
    }
    
    func embed<Module: AmberController>(_ module: Module.Type, inView view: UIView, outputListener: Module.OutputActionListener? = nil) -> Module.InputActionListener where Module.State.RequiredData == Void{
        return embed(module, data: (), inView: view, outputListener: outputListener)
    }
}

public protocol AmberRoutePerformer: AmberEmbedder {
    func replace<Module: AmberController>(with module: Module.Type, data: Module.State.RequiredData, animation: UIViewAnimationOptions)
    
    func show<Module: AmberController>(_ module: Module.Type, data: Module.State.RequiredData, outputListener: Module.OutputActionListener?) -> Module.InputActionListener
    
    func push<Module: AmberController>(_ module: Module.Type, data: Module.State.RequiredData, outputListener: Module.OutputActionListener?) -> Module.InputActionListener
    func present<Module: AmberController>(_ module: Module.Type, data: Module.State.RequiredData, outputListener: Module.OutputActionListener?) -> Module.InputActionListener
    
    func close()
    
    func dismiss()
    func pop()
    func popToRoot()
}

public extension AmberRoutePerformer{
    func replace<Module: AmberController>(with module: Module.Type, animation: UIViewAnimationOptions = .transitionCrossDissolve) where Module.State.RequiredData == Void{
        replace(with: module, data: (), animation: animation)
    }
    
    func replace<Module: AmberController>(with module: Module.Type, data: Module.State.RequiredData){
        replace(with: module, data: data, animation: .transitionCrossDissolve)
    }
    
    func show<Module: AmberController>(_ module: Module.Type, outputListener: Module.OutputActionListener? = nil) -> Module.InputActionListener where Module.State.RequiredData == Void{
        return show(module, data: (), outputListener: outputListener)
    }
    
    func show<Module: AmberController>(_ module: Module.Type, data: Module.State.RequiredData) -> Module.InputActionListener{
        return show(module, data: data, outputListener: nil)
    }
    
    func push<Module: AmberController>(_ module: Module.Type, outputListener: Module.OutputActionListener? = nil) -> Module.InputActionListener where Module.State.RequiredData == Void{
        return push(module, data: (), outputListener: outputListener)
    }
    
    func present<Module: AmberController>(_ module: Module.Type, outputListener: Module.OutputActionListener? = nil) -> Module.InputActionListener where Module.State.RequiredData == Void{
        return present(module, data: (), outputListener: outputListener)
    }
}

public class FakeAmberRoutePerformer: AmberRoutePerformer{
    public func embed<Module: AmberController>(_ module: Module.Type, data: Module.State.RequiredData, inView view: UIView, outputListener: Module.OutputActionListener?) -> Module.InputActionListener{ return { _ in } }
    public func replace<Module: AmberController>(with module: Module.Type, data: Module.State.RequiredData, animation: UIViewAnimationOptions){ }
    
    public func show<Module: AmberController>(_ module: Module.Type, data: Module.State.RequiredData, outputListener: Module.OutputActionListener?) -> Module.InputActionListener{ return { _ in } }
    public func push<Module: AmberController>(_ module: Module.Type, data: Module.State.RequiredData, outputListener: Module.OutputActionListener?) -> Module.InputActionListener{ return { _ in } }
    public func present<Module: AmberController>(_ module: Module.Type, data: Module.State.RequiredData, outputListener: Module.OutputActionListener?) -> Module.InputActionListener{ return { _ in } }
    
    public func close(){ }
    
    public func dismiss(){ }
    public func pop(){ }
    public func popToRoot(){ }
}

final class AmberRoutePerformerImplementation<T: AmberController>: AmberRoutePerformer {
    weak var controller: T?
    
    init(controller: T) {
        self.controller = controller
    }
    
    func replace<Module: AmberController>(with module: Module.Type, data: Module.State.RequiredData, animation: UIViewAnimationOptions){
        guard let currentVC = UIApplication.shared.keyWindow?.rootViewController else { fatalError() }
        let (vc, _) = AmberControllerHelper.create(module: module, data: data, outputListener: nil)
        UIView.transition(from: currentVC.view, to: vc.view, duration: 0.4, options: animation) { _ in
            UIApplication.shared.keyWindow?.rootViewController = vc
        }
    }
    
    func show<Module: AmberController>(_ module: Module.Type, data: Module.State.RequiredData, outputListener: Module.OutputActionListener?) -> Module.InputActionListener{
        return route(module: module, data: data, presentation: .show, outputListener: outputListener)
    }
    
    func push<Module: AmberController>(_ module: Module.Type, data: Module.State.RequiredData, outputListener: Module.OutputActionListener?) -> Module.InputActionListener{
        return route(module: module, data: data, presentation: .push, outputListener: outputListener)
    }
    
    func present<Module: AmberController>(_ module: Module.Type, data: Module.State.RequiredData, outputListener: Module.OutputActionListener?) -> Module.InputActionListener{
        return route(module: module, data: data, presentation: .present, outputListener: outputListener)
    }
    
    func close() { controller?.close(animated: true) }
    
    func dismiss(){ controller?.dismiss(animated: true) }
    
    func pop() { controller?.pop(animated: true) }
    
    func popToRoot() { controller?.popToRoot(animated: true) }
    
    func embed<Module: AmberController>(_ module: Module.Type, data: Module.State.RequiredData, inView view: UIView, outputListener: Module.OutputActionListener?) -> Module.InputActionListener{
        let (vc, output) = AmberControllerHelper.create(module: module, data: data, routerPerformer: self, outputListener: outputListener)
        guard let uicontroller = controller as? UIViewController else { fatalError() }
        vc.embedIn(view: view, container: uicontroller)
        return output
    }
    
    fileprivate func route<Module: AmberController>(module: Module.Type, data: Module.State.RequiredData, presentation: AmberPresentationType, outputListener: Module.OutputActionListener?) -> Module.InputActionListener{
        let (vc, output) = AmberControllerHelper.create(module: module, data: data, outputListener: outputListener)
        
        switch presentation {
        case .present: controller?.present(vc, animated: true, completion: nil)
        case .push: controller?.push(vc, animated: true)
        case .show: controller?.show(vc, animated: true)
        case .embed: fatalError("Call embed instead of route")
        }
        return output
    }
    
}

public protocol AmberRouter{
    associatedtype Reducer: AmberReducer
    
    func perform(transition: Reducer.Transition, route: AmberRoutePerformer, reducer: Reducer, performAction: @escaping (Reducer.Action) -> Void)
}

typealias AmberRouterBlock<Reducer: AmberReducer> = (Reducer.Transition, AmberRoutePerformer, Reducer, @escaping (Reducer.Action) -> Void) -> Void
