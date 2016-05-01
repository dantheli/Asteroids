//
//  GameViewController.swift
//  Asteroids
//
//  Created by Daniel Li on 11/4/15.
//  Copyright © 2015 dl743. All rights reserved.
//

import UIKit
import AudioToolbox

enum Difficulty {
    case Easy
    case Medium
    case Hard
}

class GameViewController: UIViewController, UIGestureRecognizerDelegate, UICollisionBehaviorDelegate {
    
    // MARK: - ImageViews
    
    private var shipImageView: UIImageView!
    private var interactiveShipImageView: UIImageView!
    
    // MARK: - IB Connections
    
    @IBOutlet weak var pauseView: UIVisualEffectView!
    @IBOutlet weak var pauseButton: UIButton!
    @IBAction func pauseButton(sender: UIButton) {
        asteroidTimer.invalidate()
        animator.removeAllBehaviors()
        pauseView.hidden = false
        view.bringSubviewToFront(pauseView)
        UIView.animateWithDuration(0.5, animations: {
            self.resumeButton.alpha = 1
            self.restartButton.alpha = 1
            self.mainMenuButton.alpha = 1
            self.pauseView.effect = UIBlurEffect(style: .Dark)
        })
    }
    
    @IBOutlet weak var resumeButton: UIButton!
    @IBAction func resumeButton(sender: UIButton) {
        UIView.animateWithDuration(0.5, animations: {
            self.resumeButton.alpha = 0
            self.restartButton.alpha = 0
            self.mainMenuButton.alpha = 0
            self.pauseView.effect = nil
            }, completion: { Void in
                self.pauseView.hidden = true
                self.asteroidTimer = NSTimer.scheduledTimerWithTimeInterval(self.asteroidInterval, target: self, selector: #selector(GameViewController.asteroidTimerFired(_:)), userInfo: nil, repeats: true)
                self.animator.addBehavior(self.collider)
        })
    }
    
    @IBOutlet weak var restartButton: UIButton!
    @IBAction func restartButton(sender: UIButton) {
        UIView.animateWithDuration(0.5, animations: {
            self.resumeButton.alpha = 0
            self.restartButton.alpha = 0
            self.mainMenuButton.alpha = 0
            self.pauseView.effect = nil
            
            }, completion: { Void in
                
                self.pauseView.hidden = true
                self.asteroidTimer.invalidate()
                self.animator.removeAllBehaviors()
                
                for subview in self.arena.subviews {
                    if subview.isKindOfClass(UIImageView) {
                        subview.removeFromSuperview()
                    }
                }
                self.prepareForGame()
        })
    }
    
    @IBOutlet weak var mainMenuButton: UIButton!
    @IBAction func mainMenuButton(sender: UIButton) {
        let alertController = UIAlertController(title: "Really return to Main Menu?", message: "Unsaved game data will be lost", preferredStyle: .Alert)
        let quitAction = UIAlertAction(title: "Quit", style: .Destructive) { Void in
            self.performSegueWithIdentifier("quit", sender: self)
        }
        alertController.addAction(quitAction)
        let resumeAction = UIAlertAction(title: "Resume", style: .Cancel) { Void in
            
        }
        alertController.addAction(resumeAction)
        
        presentViewController(alertController, animated: true, completion: nil)
    }
    
    @IBOutlet weak var countdownLabel: UILabel!
    @IBOutlet weak var scoreLabel: UILabel!
    @IBOutlet weak var difficultyLabel: UILabel!
    
    // MARK: - Game Properties
    
    var difficulty: Difficulty = .Easy
    
    private var _score = 0
    var score: Int {
        get {
            return _score
        } set {
            _score = newValue
            scoreLabel.text = "Score: \(_score)"
        }
    }
    
    // MARK: - Mechanics
    
    private var animator: UIDynamicAnimator!
    private var collider: UICollisionBehavior!
    private var asteroidTimer: NSTimer!
    private var pusherArray = [UIPushBehavior]()
    
    private var asteroidInterval: NSTimeInterval!
    private var asteroidSize: CGFloat!
    private var asteroidSpeed: Double!
    
    private var laserDict = [UIView : UIPushBehavior]()
    private var laserPushers = [UIPushBehavior]()
    
    func shipPanGesture(sender: UIPanGestureRecognizer) {
        let shipView = sender.view!
        let translation = sender.translationInView(view)
        shipView.center = CGPoint(x: shipView.center.x + translation.x, y: shipView.center.y + translation.y)
        sender.setTranslation(CGPointZero, inView: view)
        animator.updateItemUsingCurrentState(interactiveShipImageView)
        
        if sender.state == .Began {
            interactiveShipImageView.image = UIImage(named: "spaceshipwithfire")
        }
        
        if sender.state == .Ended {
            interactiveShipImageView.image = UIImage(named: "spaceshipwithoutfire")
        }
    }
    
    func asteroidTimerFired(sender: NSTimer) {
        let x = CGFloat(arc4random_uniform(UInt32(ScreenWidth)))
        let asteroidImageView = UIImageView(frame: CGRectMake(x, 20, asteroidSize, asteroidSize))
        asteroidImageView.contentMode = .ScaleAspectFit
        asteroidImageView.image = UIImage(named: "asteroid")!
        arena.addSubview(asteroidImageView)
        
        arena.bringSubviewToFront(pauseButton)
        arena.bringSubviewToFront(scoreLabel)
        
        let angleVariation = (CGFloat(arc4random_uniform(64)) - 32) * CGFloat(M_PI/128)
        let angle = CGFloat(M_PI/2) + angleVariation
        let magnitude = CGFloat(arc4random_uniform(UInt32(asteroidSpeed*100)) + 50)/100
        
        let pusher = UIPushBehavior(items: [asteroidImageView], mode: .Instantaneous)
        pusher.active = true
        pusher.setAngle(angle, magnitude: magnitude)
        animator.addBehavior(pusher)
        pusherArray.append(pusher)
        
        collider.addItem(asteroidImageView)
        collider.collisionMode = .Everything
    }
    
    func collisionBehavior(behavior: UICollisionBehavior, beganContactForItem item1: UIDynamicItem, withItem item2: UIDynamicItem, atPoint p: CGPoint) {
        if !item1.isEqual(arena) && !item1.isEqual(arena) {
            if item1.isMemberOfClass(UIView) && !item2.isEqual(interactiveShipImageView){
                collider.removeItem(item1)
                collider.removeItem(item2)
                (item1 as! UIView).removeFromSuperview()
                (item2 as! UIImageView).removeFromSuperview()
                score += 1
            } else if item2.isMemberOfClass(UIView) && !item1.isEqual(interactiveShipImageView) {
                collider.removeItem(item1)
                collider.removeItem(item2)
                (item2 as! UIView).removeFromSuperview()
                (item1 as! UIImageView).removeFromSuperview()
                score += 1
            } else if item1.isEqual(interactiveShipImageView) || item2.isEqual(interactiveShipImageView) {
                gameOver()
            }
            for pusher in laserPushers {
                animator.removeBehavior(pusher)
            }
        }
    }
    
    func collisionBehavior(behavior: UICollisionBehavior, beganContactForItem item: UIDynamicItem, withBoundaryIdentifier identifier: NSCopying?, atPoint p: CGPoint) {
        if p.y > view.frame.height + 80 {
            if !item.isEqual(interactiveShipImageView) && !item.isMemberOfClass(UIView) {
                collider.removeItem(item)
                for pusher in pusherArray {
                    animator.removeBehavior(pusher)
                    pusherArray.removeAtIndex(pusherArray.indexOf(pusher)!)
                    pusher.removeItem(item)
                }
                (item as! UIImageView).removeFromSuperview()
                score += 1
            }
        }
        if item.isMemberOfClass(UIView) {
            for pusher in laserPushers {
                animator.removeBehavior(pusher)
            }
            collider.removeItem(item)
            (item as! UIView).removeFromSuperview()
        }
    }
    
    // MARK: - Game Over IB Connections
    
    var arena: UIView!
    
    @IBOutlet weak var gameOverLabel: UILabel!
    @IBOutlet weak var gameOverScoreLabel: UILabel!
    
    @IBOutlet weak var tryAgainButton: UIButton!
    @IBAction func tryAgainButton(sender: UIButton) {
        gameOverLabel.hidden = true
        gameOverScoreLabel.hidden = true
        tryAgainButton.hidden = true
        gameOverMainMenuButton.hidden = true
        prepareForGame()
    }
    
    @IBOutlet weak var gameOverMainMenuButton: UIButton!
    @IBAction func gameOverMainMenuButton(sender: UIButton) {
        performSegueWithIdentifier("quit", sender: self)
    }
    
    // MARK: - View Controller Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        arena = UIView(frame: CGRectMake(-80, -80, view.frame.width + 160, view.frame.height + 160))
        view.addSubview(arena)
        
        view.multipleTouchEnabled = false
        view.clipsToBounds = false
        
        view.bringSubviewToFront(pauseButton)
        view.bringSubviewToFront(scoreLabel)
        view.bringSubviewToFront(difficultyLabel)
        view.bringSubviewToFront(tryAgainButton)
        view.bringSubviewToFront(gameOverMainMenuButton)
        
        setupDifficulty()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(true)
        prepareForGame()
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    // MARK: Load and Setup Views
    
    func setupDifficulty() {
        switch difficulty {
        case .Easy:
            difficultyLabel.text = "Easy"
            
            asteroidInterval = 0.8
            asteroidSize = 60
            asteroidSpeed = 1
            break
        case .Medium:
            difficultyLabel.text = "Medium"
            
            asteroidInterval = 0.5
            asteroidSize = 60
            asteroidSpeed = 1.1
            break
        case .Hard:
            difficultyLabel.text = "Hard"
            
            asteroidInterval = 0.25
            asteroidSize = 40
            asteroidSpeed = 1.5
            break
        }
    }
    
    // MARK: Game Set Up
    
    private func prepareForGame() {
        
        gameOverLabel.hidden = false
        gameOverScoreLabel.hidden = false
        tryAgainButton.hidden = false
        gameOverMainMenuButton.hidden = false
        
        gameOverLabel.alpha = 0
        gameOverScoreLabel.alpha = 0
        tryAgainButton.alpha = 0
        gameOverMainMenuButton.alpha = 0
        
        score = 0
        
        pauseView.hidden = true
        resumeButton.alpha = 0
        restartButton.alpha = 0
        mainMenuButton.alpha = 0
        
        pauseButton.hidden = true
        scoreLabel.hidden = true
        countdownLabel.hidden = true
        view.userInteractionEnabled = false
        
        interactiveShipImageView = UIImageView(image: UIImage(named: "spaceshipwithoutfire"))
        interactiveShipImageView.hidden = false
        interactiveShipImageView.contentMode = .ScaleAspectFill
        interactiveShipImageView.userInteractionEnabled = true
        
        shipImageView = UIImageView(image: UIImage(named: "spaceshipwithfire"))
        shipImageView.transform = CGAffineTransformIdentity
        shipImageView.hidden = true
        shipImageView.contentMode = .ScaleAspectFill
        shipImageView.frame = CGRectMake(ScreenWidth/2 - GameSpaceshipWidth/2 + 80, ScreenHeight + GameSpaceshipHeight + 80, GameSpaceshipWidth, GameSpaceshipHeight)
        arena.addSubview(shipImageView)
        
        runStartAnimations()
    }
    
    private func runStartAnimations() {
        shipImageView.hidden = false
        
        UIView.animateWithDuration(2, delay: 0, options: [UIViewAnimationOptions.CurveEaseOut], animations: {
            
            let transformation = CGAffineTransformMakeTranslation(0, -UIScreen.mainScreen().bounds.height/3)
            self.shipImageView.transform = transformation
            
            }, completion: { Void in
                
                self.interactiveShipImageView.frame = self.shipImageView.frame
                self.arena.addSubview(self.interactiveShipImageView)
                self.arena.bringSubviewToFront(self.pauseView)
                self.shipImageView.removeFromSuperview()
                
                self.runCountdownAnimations(from: 3)
        })
    }
    
    private func runCountdownAnimations(from number: Int) {
        assert(number >= 0, "Countdown must start from a nonnegative number.")
        if number == 0 {
            startGame()
            countdownLabel.hidden = true
        } else {
            countdownLabel.hidden = false
            countdownLabel.text = "\(number)"
            countdownLabel.transform = CGAffineTransformMakeScale(0, 0)
            countdownLabel.alpha = 1
            
            UIView.animateWithDuration(0.2, delay: 0, options: [], animations: {
                
                self.countdownLabel.transform = CGAffineTransformMakeScale(1, 1)
                
                }, completion: { Void in
                    UIView.animateWithDuration(0.5, delay: 0.2, options: [], animations: {
                        
                        self.countdownLabel.alpha = 0
                        
                        }, completion: { Void in
                            self.runCountdownAnimations(from: number - 1)
                    })
            })
        }
    }
    
    private func startGame() {
        view.userInteractionEnabled = true
        
        scoreLabel.text = "Score: 0"
        scoreLabel.alpha = 0
        scoreLabel.hidden = false
        pauseButton.alpha = 0
        pauseButton.hidden = false
        UIView.animateWithDuration(1, animations: {
            self.pauseButton.alpha = 1
            self.scoreLabel.alpha = 1
        })
        
        // Initialize mechanics
        animator = UIDynamicAnimator(referenceView: arena)
        collider = UICollisionBehavior(items: [interactiveShipImageView])
        collider.collisionDelegate = self
        collider.translatesReferenceBoundsIntoBoundary = true
        animator.addBehavior(collider)
        
        asteroidTimer = NSTimer.scheduledTimerWithTimeInterval(asteroidInterval, target: self, selector: #selector(GameViewController.asteroidTimerFired(_:)), userInfo: nil, repeats: true)
    }
    
    private func gameOver() {
        AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
        asteroidTimer.invalidate()
        animator.removeAllBehaviors()
        
        for subview in arena.subviews {
            if subview.isKindOfClass(UIImageView) || subview.isMemberOfClass(UIView) {
                subview.removeFromSuperview()
            }
        }
        
        pauseButton.hidden = true
        scoreLabel.hidden = true
        
        gameOverLabel.hidden = false
        gameOverScoreLabel.hidden = false
        tryAgainButton.hidden = false
        gameOverMainMenuButton.hidden = false
        
        gameOverScoreLabel.text = "Score: \(score)"
        
        UIView.animateWithDuration(1, animations: {
            self.gameOverLabel.alpha = 1
            self.gameOverScoreLabel.alpha = 1
            self.tryAgainButton.alpha = 1
            self.gameOverMainMenuButton.alpha = 1
            }, completion: nil)
        
    }
    
    // MARK: 3D Touch Shooting
    
    private var pressed = false
    private var force: CGFloat = 0.0 {
        didSet {
            forceDifferential = force - oldValue
        }
    }
    
    private let NecessaryForceDifferential: CGFloat = 0.3
    private var forceDifferential: CGFloat = 0.0 {
        didSet {
            forceDoubleDifferential = forceDifferential - oldValue
        }
    }
    
    private var forceDoubleDifferential: CGFloat = 0.0
    private var location: CGPoint? = nil
    private var forceValues = [CGFloat]()
    
    private var isDraggingShip: Bool = false
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        for touch in touches {
            force = touch.force
            location = touch.locationInView(view)
            if CGRectContainsPoint(interactiveShipImageView.frame, touch.locationInView(arena)) {
                interactiveShipImageView.image = UIImage(named: "spaceshipwithfire")
                isDraggingShip = true
            }
        }
    }
    
    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        for touch in touches {
            if isDraggingShip {
                interactiveShipImageView.center = touch.locationInView(arena)
                animator.updateItemUsingCurrentState(interactiveShipImageView)
                force = touch.force
                location = touch.locationInView(view)
                
                if forceDifferential < 0 {
                    pressed = false
                }
                
                if !pressed {
                    if force == touch.maximumPossibleForce {
                        firmPress()
                    } else if forceDifferential > NecessaryForceDifferential {
                        if forceDoubleDifferential < 0 {
                            firmPress()
                        } else {
                            firmPress()
                        }
                    }
                }
            }
        }
    }
    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        force = 0
        location = nil
        isDraggingShip = false
        for touch in touches {
            if CGRectContainsPoint(interactiveShipImageView.frame, touch.locationInView(arena)) {
                interactiveShipImageView.image = UIImage(named: "spaceshipwithoutfire")
            }
        }
    }
    
    private func firmPress() {
        pressed = true
        
        // Shoot lazer
        let laser = UIView(frame: CGRectMake(interactiveShipImageView.center.x, interactiveShipImageView.center.y - 120, 1, 60))
        laser.backgroundColor = UIColor.redColor()
        arena.addSubview(laser)
        
        let pusher = UIPushBehavior(items: [laser], mode: .Instantaneous)
        pusher.active = true
        pusher.setAngle(CGFloat(-M_PI/2), magnitude: 0.1)
        laserPushers.append(pusher)
        laserDict[laser] = pusher
        animator.addBehavior(pusher)
        collider.addItem(laser)
    }

}