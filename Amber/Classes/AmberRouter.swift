//
//  AmberRouter.swift
//  TrainBrain
//
//  Created by Nikita Arkhipov on 09.10.2017.
//  Copyright © 2017 Nikita Arkhipov. All rights reserved.
//

import UIKit

enum AmberPresentationType{
    case present, show
}

public protocol AmberEmbedder {
    func embed<Module: AmberController>(_ module: Module.Type, data: Module.Reducer.State.RequiredData, inView view: UIView, outputListener: Module.OutputActionListener?) -> Module.InputActionListener
    func cleanEmbed<Module: AmberController>(_ module: Module.Type, data: Module.Reducer.State.RequiredData, inView view: UIView, outputListener: Module.OutputActionListener?) -> Module.InputActionListener
    func embedFullScreen<Module: AmberController>(_ module: Module.Type, data: Module.Reducer.State.RequiredData, outputListener: Module.OutputActionListener?) -> Module.InputActionListener
}

public extension AmberEmbedder{
    func embed<Module: AmberController>(_ module: Module.Type, data: Module.Reducer.State.RequiredData, inView view: UIView) -> Module.InputActionListener{
        return embed(module, data: data, inView: view, outputListener: nil)
    }

    func embed<Module: AmberController>(_ module: Module.Type, inView view: UIView, outputListener: Module.OutputActionListener? = nil) -> Module.InputActionListener where Module.Reducer.State.RequiredData == Void {
        return embed(module, data: (), inView: view, outputListener: outputListener)
    }
    
    func cleanEmbed<Module: AmberController>(_ module: Module.Type, data: Module.Reducer.State.RequiredData, inView view: UIView) -> Module.InputActionListener{
        return cleanEmbed(module, data: data, inView: view, outputListener: nil)
    }
    
    func cleanEmbed<Module: AmberController>(_ module: Module.Type, inView view: UIView, outputListener: Module.OutputActionListener?) -> Module.InputActionListener where Module.Reducer.State.RequiredData == Void {
        return cleanEmbed(module, data: (), inView: view, outputListener: outputListener)
    }
    
    func embedFullScreen<Module: AmberController>(_ module: Module.Type, data: Module.Reducer.State.RequiredData, inView view: UIView) -> Module.InputActionListener{
        return embedFullScreen(module, data: data, outputListener: nil)
    }
    
    func embedFullScreen<Module: AmberController>(_ module: Module.Type, outputListener: Module.OutputActionListener?) -> Module.InputActionListener where Module.Reducer.State.RequiredData == Void {
        return embedFullScreen(module, data: (), outputListener: outputListener)
    }
}

public protocol AmberRoutePerformer: AmberEmbedder {
    var controller: UIViewController? { get }
    
    func replace<Module: AmberController>(with module: Module.Type, data: Module.Reducer.State.RequiredData, animation: UIView.AnimationOptions)
    func show<Module: AmberController>(_ module: Module.Type, data: Module.Reducer.State.RequiredData, outputListener: Module.OutputActionListener?) -> Module.InputActionListener
    func present<Module: AmberController>(_ module: Module.Type, data: Module.Reducer.State.RequiredData, outputListener: Module.OutputActionListener?) -> Module.InputActionListener

    func baseReplace(storyboardFile: String, storyboardID: String, animation: UIView.AnimationOptions)
    func baseShow(storyboardFile: String, storyboardID: String)
    func basePresent(storyboardFile: String, storyboardID: String)

    func baseReplace(controller: UIViewController, animation: UIView.AnimationOptions)
    func baseShow(controller: UIViewController)
    func basePresent(controller: UIViewController)

    func close()

    func dismiss()
    func pop()
    func popToRoot()
}

public extension AmberRoutePerformer{
    func replace<Module: AmberController>(with module: Module.Type, animation: UIView.AnimationOptions = .transitionCrossDissolve) where Module.Reducer.State.RequiredData == Void{
        replace(with: module, data: (), animation: animation)
    }

    func replace<Module: AmberController>(with module: Module.Type, data: Module.Reducer.State.RequiredData){
        replace(with: module, data: data, animation: .transitionCrossDissolve)
    }

    func baseReplace(storyboardFile: String, storyboardID: String){
        baseReplace(storyboardFile: storyboardFile, storyboardID: storyboardID, animation: .transitionCrossDissolve)
    }

    func show<Module: AmberController>(_ module: Module.Type, outputListener: Module.OutputActionListener? = nil) -> Module.InputActionListener where Module.Reducer.State.RequiredData == Void{
        return show(module, data: (), outputListener: outputListener)
    }

    func show<Module: AmberController>(_ module: Module.Type, data: Module.Reducer.State.RequiredData) -> Module.InputActionListener{
        return show(module, data: data, outputListener: nil)
    }

    func present<Module: AmberController>(_ module: Module.Type, outputListener: Module.OutputActionListener? = nil) -> Module.InputActionListener where Module.Reducer.State.RequiredData == Void{
        return present(module, data: (), outputListener: outputListener)
    }
    
    func present<Module: AmberController>(_ module: Module.Type, data: Module.Reducer.State.RequiredData) -> Module.InputActionListener{
        return present(module, data: data, outputListener: nil)
    }
}

public class FakeAmberRoutePerformer: AmberRoutePerformer{
    public var controller: UIViewController? { return nil }
        
    public func embed<Module: AmberController>(_ module: Module.Type, data: Module.Reducer.State.RequiredData, inView view: UIView, outputListener: Module.OutputActionListener?) -> Module.InputActionListener{ return { _ in } }
    public func cleanEmbed<Module: AmberController>(_ module: Module.Type, data: Module.Reducer.State.RequiredData, inView view: UIView, outputListener: Module.OutputActionListener?) -> Module.InputActionListener{ return { _ in } }
    public func embedFullScreen<Module: AmberController>(_ module: Module.Type, data: Module.Reducer.State.RequiredData, outputListener: Module.OutputActionListener?) -> Module.InputActionListener{ return { _ in } }
    
    public func replace<Module: AmberController>(with module: Module.Type, data: Module.Reducer.State.RequiredData, animation: UIView.AnimationOptions){ }

    public func show<Module: AmberController>(_ module: Module.Type, data: Module.Reducer.State.RequiredData, outputListener: Module.OutputActionListener?) -> Module.InputActionListener{ return { _ in } }
    public func present<Module: AmberController>(_ module: Module.Type, data: Module.Reducer.State.RequiredData, outputListener: Module.OutputActionListener?) -> Module.InputActionListener{ return { _ in } }

    public func baseReplace(storyboardFile: String, storyboardID: String, animation: UIView.AnimationOptions){ }
    public func baseShow(storyboardFile: String, storyboardID: String){ }
    public func basePresent(storyboardFile: String, storyboardID: String){ }
    
    public func baseReplace(controller: UIViewController, animation: UIView.AnimationOptions){ }
    public func baseShow(controller: UIViewController){ }
    public func basePresent(controller: UIViewController){ }

    public func close(){ }

    public func dismiss(){ }
    public func pop(){ }
    public func popToRoot(){ }
}

final class AmberRoutePerformerImplementation<T: AmberController, U: AmberController>: AmberRoutePerformer {
    var controller: UIViewController? { return amberController as? UIViewController }
    
    weak var amberController: T?
    weak var embedder: U?

    init(controller: T, embedder: U) {
        self.amberController = controller
        self.embedder = embedder
    }

    func replace<Module: AmberController>(with module: Module.Type, data: Module.Reducer.State.RequiredData, animation: UIView.AnimationOptions){
        let (vc, _) = AmberControllerHelper.create(module: module, data: data, outputListener: nil)
        replaceWith(vc, animation: animation)
    }

    func show<Module: AmberController>(_ module: Module.Type, data: Module.Reducer.State.RequiredData, outputListener: Module.OutputActionListener?) -> Module.InputActionListener{
        return route(module: module, data: data, presentation: .show, outputListener: outputListener)
    }

    func present<Module: AmberController>(_ module: Module.Type, data: Module.Reducer.State.RequiredData, outputListener: Module.OutputActionListener?) -> Module.InputActionListener{
        return route(module: module, data: data, presentation: .present, outputListener: outputListener)
    }

    func baseReplace(storyboardFile: String, storyboardID: String, animation: UIView.AnimationOptions){
        let vc = createController(storyboardFile: storyboardFile, storyboardID: storyboardID)
        replaceWith(vc, animation: animation)
    }

    func baseShow(storyboardFile: String, storyboardID: String){
        let vc = createController(storyboardFile: storyboardFile, storyboardID: storyboardID)
        amberController?.show(vc, animated: true)
    }

    func basePresent(storyboardFile: String, storyboardID: String){
        let vc = createController(storyboardFile: storyboardFile, storyboardID: storyboardID)
        amberController?.present(vc, animated: true, completion: nil)
    }
    
    func baseReplace(controller: UIViewController, animation: UIView.AnimationOptions){
        replaceWith(controller, animation: animation)
    }
    func baseShow(controller: UIViewController){
        self.amberController?.show(controller, animated: true)
    }
    func basePresent(controller: UIViewController){
        self.amberController?.present(controller, animated: true, completion: nil)
    }

    func close() { amberController?.close(animated: true) }

    func dismiss(){ amberController?.dismiss(animated: true) }

    func pop() { amberController?.pop(animated: true) }

    func popToRoot() { amberController?.popToRoot(animated: true) }

    func embed<Module: AmberController>(_ module: Module.Type, data: Module.Reducer.State.RequiredData, inView view: UIView, outputListener: Module.OutputActionListener?) -> Module.InputActionListener{
        let (vc, output) = AmberControllerHelper.create(module: module, data: data, route: amberController!, outputListener: outputListener)
        guard let uicontroller = embedder as? UIViewController else { fatalError() }
        vc.embedIn(view: view, container: uicontroller)
        return output
    }
        
    func cleanEmbed<Module: AmberController>(_ module: Module.Type, data: Module.Reducer.State.RequiredData, inView view: UIView, outputListener: Module.OutputActionListener?) -> Module.InputActionListener{
        view.embeddedControllers.forEach { $0.unembed(shouldModifyEmbedArray: false) }
        view.embeddedControllers = []
        return embed(module, data: data, inView: view, outputListener: outputListener)
    }
    
    func embedFullScreen<Module: AmberController>(_ module: Module.Type, data: Module.Reducer.State.RequiredData, outputListener: Module.OutputActionListener?) -> Module.InputActionListener{
        guard let uicontroller = embedder as? UIViewController else { fatalError() }
        return embed(module, data: data, inView: uicontroller.view, outputListener: outputListener)
    }

    private func replaceWith(_ vc: UIViewController, animation: UIView.AnimationOptions){
        guard let currentVC = UIApplication.shared.keyWindow?.rootViewController else { fatalError() }
        UIView.transition(from: currentVC.view, to: vc.view, duration: 0.4, options: animation) { _ in
            UIApplication.shared.keyWindow?.rootViewController = vc
        }
    }

    private func createController(storyboardFile: String, storyboardID: String) -> UIViewController{
        return UIStoryboard(name: storyboardFile, bundle: nil).instantiateViewController(withIdentifier: storyboardID)
    }

    fileprivate func route<Module: AmberController>(module: Module.Type, data: Module.Reducer.State.RequiredData, presentation: AmberPresentationType, outputListener: Module.OutputActionListener?) -> Module.InputActionListener{
        let (vc, output) = AmberControllerHelper.create(module: module, data: data, outputListener: outputListener)

        switch presentation {
        case .present: amberController?.present(vc, animated: true, completion: nil)
        case .show: amberController?.show(vc, animated: true)
        }
        return output
    }

}

public protocol AmberRouter{
    associatedtype Reducer: AmberReducer

    func perform(transition: Reducer.Transition, on state: Reducer.State, isCancelled: Bool, route: AmberRoutePerformer, reducer: Reducer, performAction: @escaping (Reducer.Action) -> Void)
}

typealias AmberRouterBlock<Reducer: AmberReducer> = (Reducer.Transition, Reducer.State, Bool, AmberRoutePerformer, Reducer, @escaping (Reducer.Action) -> Void) -> Void

