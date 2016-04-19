//
//  MenuViewController.swift
//  Asteroids
//
//  Created by Daniel Li on 11/4/15.
//  Copyright © 2015 dl743. All rights reserved.
//

import UIKit

class MenuViewController: UIViewController {

    @IBOutlet weak var backgroundImageView: UIImageView!
    @IBOutlet weak var menuContainerView: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    
    private var control: HMSegmentedControl!
    
    @IBOutlet weak var playButton: UIButton!
    @IBAction func playButton(sender: UIButton) {
        timer.invalidate()
        UIView.animateWithDuration(0.2, delay: 0.0, options: [UIViewAnimationOptions.CurveEaseIn, UIViewAnimationOptions.BeginFromCurrentState], animations: {
            
            let scale = CGAffineTransformMakeScale(5, 5)
            self.menuContainerView.transform = scale
            self.menuContainerView.alpha = 0
            
            self.backgroundImageView.alpha = 0
            
            for subview in self.view.subviews {
                if !(subview === UILabel.self) && !(subview === UIButton.self) && !(subview === UISegmentedControl.self) {
                    subview.alpha = 0
                }
            }
            
            }, completion: { Void in
                self.backgroundImageView.layer.removeAllAnimations()
                self.backgroundImageView.transform = CGAffineTransformIdentity
                self.performSegueWithIdentifier("startGame", sender: self)
        })
    }
    
    func timerFired(sender: NSTimer) {
        throwAsteroid()
    }
    
    private var timer: NSTimer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupSegmentedControl()
        
        timer = NSTimer.scheduledTimerWithTimeInterval(0.5, target: self, selector: #selector(MenuViewController.timerFired(_:)), userInfo: nil, repeats: true)
        
        playButton.layer.cornerRadius = 10
        
    }
    
    private func setupSegmentedControl() {
        control = HMSegmentedControl(sectionTitles: ["Easy", "Medium", "Hard"])
        control.frame = CGRectMake(0, 0, ScreenWidth, 40)
        control.center = CGPointMake(ScreenWidth/2, ScreenHeight/2)
        control.backgroundColor = UIColor.clearColor()
        control.selectionIndicatorHeight = 4.0
        control.selectionIndicatorLocation = HMSegmentedControlSelectionIndicatorLocationDown
        control.selectionStyle = HMSegmentedControlSelectionStyleFullWidthStripe
        control.addTarget(self, action: nil, forControlEvents: .ValueChanged)
        menuContainerView.addSubview(control)
    }
    
    private var notified: Bool {
        get {
            let defaults = NSUserDefaults.standardUserDefaults()
            return defaults.boolForKey("notified3d")
        }
        set {
            let defaults = NSUserDefaults.standardUserDefaults()
            defaults.setBool(newValue, forKey: "notified3d")
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(true)
        
        UIView.animateWithDuration(50, delay: 0, options: [UIViewAnimationOptions.Repeat, UIViewAnimationOptions.CurveLinear], animations: {
            let scale = CGAffineTransformMakeScale(2, 2)
            self.backgroundImageView.transform = scale
            }, completion: nil)
        
        if !notified {
            let alertController = UIAlertController(title: "Notice About Shooting Lasers", message: "Only force-touch enabled devices (iPhone 6s and 6s+ and newer) can utilize the shooting capability. Test this out on a real device. To shoot, press firmly on the spaceship while dragging it.", preferredStyle: .Alert)
            let okayAction = UIAlertAction(title: "Got it", style: .Default, handler: nil)
            alertController.addAction(okayAction)
            presentViewController(alertController, animated: true, completion: nil)
            notified = true
        }
    }
    
    func throwAsteroid() {
        
        let side = arc4random_uniform(3)
        let x: CGFloat!
        let y: CGFloat!
        
        var transformX: CGFloat!
        var transformY: CGFloat!
        
        if side == 0 { // Left
            x = CGFloat(-AsteroidWidth)
            y = CGFloat(arc4random_uniform(UInt32(ScreenHeight + 2*AsteroidHeight))) - AsteroidHeight
            
            transformX = ScreenWidth + 2*AsteroidHeight
            if y < ScreenHeight/2 {
                transformY = ScreenHeight - y
            } else {
                transformY = -y
            }
            transformY = transformY * CGFloat((arc4random_uniform(151) + 50)/100)
            
        } else if side == 1 { // Right
            x = CGFloat(ScreenWidth)
            y = CGFloat(arc4random_uniform(UInt32(ScreenHeight + 2*AsteroidHeight))) - AsteroidHeight
            
            transformX = -ScreenWidth - 2*AsteroidHeight
            if y < ScreenHeight/2 {
                transformY = ScreenHeight - y
            } else {
                transformY = -y
            }
            transformY = transformY * CGFloat((arc4random_uniform(151) + 50)/100)
            
        } else if side == 2 { // Top
            x = CGFloat(arc4random_uniform(UInt32(ScreenWidth + 2*AsteroidWidth))) - AsteroidWidth
            y = CGFloat(-AsteroidHeight)
            
            transformY = ScreenHeight + 2*AsteroidHeight
            if x < ScreenWidth/2 {
                transformX = ScreenWidth - x
            } else {
                transformX = -x
            }
            transformX = transformX * CGFloat((arc4random_uniform(151) + 50)/100)
            
        } else { // Bottom
            x = CGFloat(arc4random_uniform(UInt32(ScreenWidth + 2*AsteroidWidth))) - AsteroidWidth
            y = CGFloat(ScreenHeight)
            
            transformY = -ScreenHeight - 2*AsteroidHeight
            if x < ScreenWidth/2 {
                transformX = ScreenWidth - x
            } else {
                transformX = -x
            }
            transformX = transformX * CGFloat((arc4random_uniform(151) + 50)/100)
        }
        
        let asteroid = UIImageView(image: UIImage(named: "asteroid"))
        asteroid.frame = CGRect(x: x, y: y, width: AsteroidWidth, height: AsteroidHeight)
        view.addSubview(asteroid)
        view.bringSubviewToFront(menuContainerView)
        
        let duration = Double(arc4random_uniform(3) + 1)
        let delay = (Double(arc4random_uniform(19) + 1))/10
        
        
        UIView.animateWithDuration(duration, delay: delay, options: [.CurveLinear, .AllowUserInteraction], animations: {
            
            asteroid.transform = CGAffineTransformMakeTranslation(transformX, transformY)
            
            }, completion: { finished in
                asteroid.removeFromSuperview()
        })
        
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    @IBAction func returnToMainMenu(segue: UIStoryboardSegue) {
        menuContainerView.alpha = 1
        menuContainerView.transform = CGAffineTransformIdentity
        
        backgroundImageView.alpha = 1
        
        throwAsteroid()
        throwAsteroid()
        throwAsteroid()
        
        timer = NSTimer.scheduledTimerWithTimeInterval(0.5, target: self, selector: #selector(MenuViewController.timerFired(_:)), userInfo: nil, repeats: true)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let destination = segue.destinationViewController as? GameViewController {
            if control.selectedSegmentIndex == 0 {
                destination.difficulty = .Easy
            } else if control.selectedSegmentIndex == 1 {
                destination.difficulty = .Medium
            } else {
                destination.difficulty = .Hard
            }
        }
    }
    
}

