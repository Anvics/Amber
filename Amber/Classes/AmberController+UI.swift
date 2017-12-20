//
//  AmberControllerHelper.swift
//  TrainBrain
//
//  Created by Nikita Arkhipov on 09.10.2017.
//  Copyright © 2017 Nikita Arkhipov. All rights reserved.
//

import UIKit

extension AmberPresentable{
    public static func instantiate() -> Self{
        let sb = UIStoryboard(name: storyboardFile, bundle: nil)
        guard let vc = sb.instantiateViewController(withIdentifier: storyboardID) as? Self else { fatalError() }
        return vc
    }
}

extension UIViewController: AmberPresenter{
    public func push(_ viewController: UIViewController, animated: Bool){
        navigationController?.pushViewController(viewController, animated: animated)
    }

    public func embedIn(view: UIView, container: UIViewController){
        self.view.frame = view.bounds
        container.addChildViewController(self)
        view.addSubview(self.view)
        view.embeddedControllers.append(self)
        didMove(toParentViewController: container)
    }
    
    public func show(_ viewController: UIViewController, animated: Bool){
        if navigationController != nil { push(viewController, animated: true) }
        else { present(viewController, animated: true, completion: nil) }
    }
    
    public func close(animated: Bool){
        if let nav = navigationController{ nav.popViewController(animated: animated) }
        else if parent != nil { unembed() }
        else{ dismiss(animated: animated, completion: nil) }
    }
    
    public func dismiss(animated: Bool) {
        dismiss(animated: animated, completion: nil)
    }
    
    public func pop(animated: Bool){
        navigationController?.popViewController(animated: animated)
    }
    
    public func popToRoot(animated: Bool){
        navigationController?.popToRootViewController(animated: animated)
    }
    
    func unembed(shouldModifyEmbedArray: Bool = true){
        removeFromParentViewController()
        if let index = view.superview?.embeddedControllers.index(of: self), shouldModifyEmbedArray{
            view.superview?.embeddedControllers.remove(at: index)
        }
        view.removeFromSuperview()
        didMove(toParentViewController: nil)
    }
}

private var UIView_Associated_EmbedControllers: UInt8 = 0
extension UIView{
    var embeddedControllers: [UIViewController]{
        get {
            return objc_getAssociatedObject(self, &UIView_Associated_EmbedControllers) as? [UIViewController] ?? []
        }
        set {
            objc_setAssociatedObject(self, &UIView_Associated_EmbedControllers, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}
