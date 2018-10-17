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
        #if swift(>=4.2)
            container.addChild(self)
        #else
            container.addChildViewController(self)
        #endif
            view.addSubview(self.view)
        #if swift(>=4.2)
            didMove(toParent: container)
        #else
            didMove(toParentViewController: container)
        #endif
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
    
    private func unembed(){
        #if swift(>=4.2)
            removeFromParent()
            view.removeFromSuperview()
            didMove(toParent: nil)
        #else
            removeFromParentViewController()
            view.removeFromSuperview()
            didMove(toParentViewController: nil)
        #endif
        
    }
}
