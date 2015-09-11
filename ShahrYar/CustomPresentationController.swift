//
//  Created by Pete Callaway on 26/06/2014.
//  Copyright (c) 2014 Dative Studios. All rights reserved.
//

import UIKit


public class CustomPresentationController: UIPresentationController {

    lazy var dimmingView :UIView = {
        let view = UIView(frame: self.containerView!.bounds)
        view.backgroundColor = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.2)
        view.alpha = 0.0
        return view
    }()

    override public func presentationTransitionWillBegin() {
        // Add the dimming view and the presented view to the heirarchy
        self.dimmingView.frame = self.containerView!.bounds
        self.containerView!.addSubview(self.dimmingView)
        self.containerView!.addSubview(self.presentedView()!)

        // Fade in the dimming view alongside the transition
        if let transitionCoordinator = self.presentingViewController.transitionCoordinator() {
            transitionCoordinator.animateAlongsideTransition({(context: UIViewControllerTransitionCoordinatorContext!) -> Void in
                self.dimmingView.alpha  = 1.0
            }, completion:nil)
        }
    }

    override public func presentationTransitionDidEnd(completed: Bool)  {
        // If the presentation didn't complete, remove the dimming view
        if !completed {
            self.dimmingView.removeFromSuperview()
        }
    }

    override public func dismissalTransitionWillBegin()  {
        // Fade out the dimming view alongside the transition
        if let transitionCoordinator = self.presentingViewController.transitionCoordinator() {
            transitionCoordinator.animateAlongsideTransition({(context: UIViewControllerTransitionCoordinatorContext!) -> Void in
                self.dimmingView.alpha  = 0.0
            }, completion:nil)
        }
    }

    override public func dismissalTransitionDidEnd(completed: Bool) {
        // If the dismissal completed, remove the dimming view
        if completed {
            self.dimmingView.removeFromSuperview()
        }
    }

    override public func frameOfPresentedViewInContainerView() -> CGRect {
        // We don't want the presented view to fill the whole container view, so inset it's frame
        var frame = self.containerView!.bounds;
        
        if traitCollection.horizontalSizeClass == .Regular && traitCollection.verticalSizeClass == .Compact {
            let height: CGFloat = 500.0
            frame = CGRect(x: (self.containerView!.frame.size.width - 375.0) / 2, y: (self.containerView!.frame.size.height - height) / 2, width: 375, height: height)
        } else if traitCollection.horizontalSizeClass == .Regular && traitCollection.verticalSizeClass == .Regular {
            let height: CGFloat = 500.0
            frame = CGRect(x: (self.containerView!.frame.size.width - 375.0) / 2, y: (self.containerView!.frame.size.height - height) / 2, width: 375, height: height)
        }
        
        return frame
    }

    override public func containerViewWillLayoutSubviews() {
        dimmingView.frame = containerView!.bounds
        presentedView()!.frame = frameOfPresentedViewInContainerView()
    }
    
    override public func containerViewDidLayoutSubviews() {
        if traitCollection.horizontalSizeClass == .Regular {
            presentedView()!.layer.cornerRadius = 15
        } else {
            presentedView()!.layer.cornerRadius = 0
        }
    }

}
