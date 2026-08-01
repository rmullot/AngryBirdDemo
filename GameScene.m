//
//  GameScene.m
//  AngryBirdDemo
//
//  Created by Romain Mullot on 05/03/2018.
//  Copyright © 2018 Romain Mullot. All rights reserved.
//

#import "GameScene.h"
#import "ABReferenceNode.h"

@interface GameScene () {
    CGSize _backgroundOriginalSize;
}
@end

@implementation GameScene

- (void)setTrackerNode:(SKNode*)newValue {
    if(newValue != nil){
        /* Set tracker */
        _trackerNode = newValue;
        self.lastTrackerPosition = newValue.position;
    }
    
}

- (void)sceneDidLoad {
    // Setup your scene here
    self.lastTrackerPosition = CGPointZero;
    self.lastTimeInterval = 0;
    
}

-(void) didMoveToView:(SKView *)view{
    /* Set reference to catapultArm SKSpriteNode */
    self.catapultArm = (SKSpriteNode *)[self childNodeWithName:@"catapultArm"];
    self.catapult = (SKSpriteNode *)[self childNodeWithName:@"catapult"];
    self.cantileverNode = (SKSpriteNode *)[self childNodeWithName:@"cantileverNode"];
    self.touchNode = (SKSpriteNode *)[self childNodeWithName:@"touchNode"];
    self.background = (SKSpriteNode *)[self childNodeWithName:@"background"];
    _backgroundOriginalSize = self.background.size;
    [self resizeBackgroundToFillScreen];
    [self clampCameraXWithinBackground];

    /* Set reference to levelHolder SKNode */
    self.levelHolder = [self childNodeWithName:@"levelHolder"];
    
    /* Set reference to buttonRestart SKSpriteNode */
    self.buttonRestart = (ABButtonNode *)[self childNodeWithName:@"//buttonRestart"];
    
    /* Setup button selection handler */
    self.buttonRestart.selectedHandler = ^void(void){
        if(self.view != nil){
            
            // Load the SKScene from 'GameScene.sks'
            SKScene *scene = [SKScene nodeWithFileNamed: @"GameScene"];
            if(scene != nil){
                
                // Resize the scene to match the actual screen size, so its
                // coordinate system (camera bounds, node positions) reflects
                // the real device size instead of a fixed design canvas.
                scene.scaleMode = SKSceneScaleModeResizeFill;

                // Present the scene
                [view presentScene:scene];
            }
            
            // Debug helpers
            view.showsFPS = NO;
            view.showsPhysics = NO;
            view.showsDrawCount = NO;
        }
    };
    
    /* Load Level 1 */
    NSString *resourcePath = [[NSBundle mainBundle] pathForResource: @"Level1" ofType: @"sks"];
    SKReferenceNode *level = [SKReferenceNode referenceNodeWithURL:[NSURL fileURLWithPath:resourcePath]];
    [self.levelHolder addChild:level];
    
    /* Initialize catapult arm physics body of type alpha */
    SKPhysicsBody *catapultArmBody = [SKPhysicsBody bodyWithTexture:self.catapultArm.texture size: self.catapultArm.size];
    
    /* Mass needs to be heavy enough to hit the penguin with sufficient force */
    catapultArmBody.mass = 0.5;
    
    /* No need for gravity otherwise the arm will fall over */
    catapultArmBody.affectedByGravity = false;
    
    /* Improves physics collision handling of fast moving objects */
    catapultArmBody.usesPreciseCollisionDetection = true;
    
    /* Assign the physics body to the catapult arm */
    self.catapultArm.physicsBody = catapultArmBody;
    
    /* Pin joint catapult and catapult arm */
    SKPhysicsJointPin *catapultPinJoint = [SKPhysicsJointPin jointWithBodyA:self.catapult.physicsBody bodyB:self.catapultArm.physicsBody anchor:CGPointMake(-91 ,-55)];
    [self.physicsWorld addJoint:catapultPinJoint];
    
    /* Spring joint catapult arm and cantilever node */
    SKPhysicsJointSpring *catapultSpringJoint = [SKPhysicsJointSpring jointWithBodyA:self.catapultArm.physicsBody bodyB:self.cantileverNode.physicsBody anchorA: CGPointMake(self.catapultArm.position.x+15,self.catapultArm.position.y+30) anchorB:self.cantileverNode.position];
    [self.physicsWorld addJoint:catapultSpringJoint];
    
    /* Make this joint a bit more springy */
    catapultSpringJoint.frequency = 1.5;
    
    /* Set physics contact delegate */
    self.physicsWorld.contactDelegate = self;
    
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    
    /* There will only be one touch as multi touch is not enabled by default */
    for(UITouch *touch in touches){
        
        /* Grab scene position of touch */
        CGPoint location = [touch locationInNode: self];
        
        /* Get node reference if we're touching a node */
        SKNode * touchedNode = [self nodeAtPoint:location];
        
        /* Is it the catapult arm? */
        if ([touchedNode.name  isEqual: @"catapultArm"]){
            
            /* Reset touch node position */
            self.touchNode.position = location;
            
            /* Spring joint touch node and catapult arm */
            self.touchJoint = [SKPhysicsJointSpring jointWithBodyA:self.touchNode.physicsBody bodyB:self.catapultArm.physicsBody anchorA:location anchorB:location];
            [self.physicsWorld addJoint:self.touchJoint];
            
            /* Add a new penguin to the scene */
            ABReferenceNode *penguin = [ABReferenceNode nodeWithFileNamed:@"Penguin"];
            [self addChild:penguin];
            
            /* Position penguin in the catapult bucket area */
            penguin.avatar.position =  CGPointMake(self.catapultArm.position.x +32, self.catapultArm.position.y + 50);
            
            /* Improves physics collision handling of fast moving objects */
            penguin.avatar.physicsBody.usesPreciseCollisionDetection = true;
            
            /* Setup pin joint between penguin and catapult arm */
            self.penguinJoint = [SKPhysicsJointPin jointWithBodyA:self.catapultArm.physicsBody bodyB:penguin.avatar.physicsBody anchor:penguin.avatar.position];
            [self.physicsWorld addJoint:self.penguinJoint];

            /* Track whether the arm has actually been pulled back before it's allowed to release the penguin */
            self.armHasBeenPulled = false;
            self.touchHasEnded = false;
            
            /* Set tracker to follow penguin */
            self.trackerNode = penguin.avatar;
        }
    }
}
- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event{
    /* Called when a touch moved */
    
    /* There will only be one touch as multi touch is not enabled by default */
    for(UITouch *touch in touches){
        
        /* Grab scene position of touch and update touchNode position */
        CGPoint location = [touch locationInNode: self];
        self.touchNode.position = location;
        
    }
}
- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    /* Called when a touch ended */
    
    /* Let it fly!, remove the touch joint so the spring can snap the arm back.
       The penguin stays pinned to the arm until it releases itself in update:,
       once the arm has swung back past its resting rotation - otherwise the
       penguin separates before the arm accelerates and simply drops. */
    if (self.touchJoint != nil) {
        [self.physicsWorld removeJoint:self.touchJoint];
    }
    self.touchHasEnded = true;
}


-(void)update:(CFTimeInterval)currentTime {
    /* Release the penguin once the finger has left the screen AND the arm has
       swung back past its resting rotation, so it inherits the arm's velocity
       instead of falling straight down. Gating on touchHasEnded keeps the
       penguin glued to the arm for as long as the player is still holding the
       screen, even if the arm's rotation happens to cross back through rest
       while they're still dragging. The pull direction (positive or negative
       zRotation) depends on which way the player drags, so it's recorded the
       first time the arm moves noticeably, then the penguin is released once
       the rotation crosses back to the opposite side of rest - this avoids
       hardcoding a pull direction that may not match how the arm actually
       rotates, and avoids releasing on the very first frame while the arm is
       still at rest (0). */
    /* Safety net: re-clamp the camera into the background's bounds every
       frame. The pan/reset logic below only ever nudges the camera towards
       the bounds it computed at that moment, so if self.size settles to its
       final value a frame or two after a resize (e.g. once the device's safe
       area/Dynamic Island layout is finalized), a stale target can leave the
       camera a few points outside the *current* bounds, exposing a sliver of
       empty scene background. Recomputing and clamping unconditionally here
       is cheap and makes that impossible to observe. */
    [self clampCameraXWithinBackground];

    if (self.penguinJoint != nil) {
        CGFloat armRotation = self.catapultArm.zRotation;
        if (!self.armHasBeenPulled) {
            if (fabs(armRotation) > 0.05) {
                self.armWasPulledNegative = (armRotation < 0);
                self.armHasBeenPulled = true;
            }
        } else if (self.touchHasEnded) {
            BOOL hasSwungBackPastRest = self.armWasPulledNegative ? (armRotation >= 0) : (armRotation <= 0);
            if (hasSwungBackPastRest) {
                [self.physicsWorld removeJoint:self.penguinJoint];
                self.penguinJoint = nil;
            }
        }
    }

    /* Check there is a node to track and camera is present */
    if(self.trackerNode != nil && self.camera != nil){
        
        /* Calculate horizontal distance to move */
        CGFloat moveDistance = self.trackerNode.position.x - self.lastTrackerPosition.x;
        
        /* Duration is time between updates */
        CGFloat moveDuration = currentTime - self.lastTimeInterval;

        /* Clamp the camera so it never scrolls past the edges of the background.
           Derived from the background's actual position/size and the scene's
           current size (self.size) - which reflects the real screen size when
           using SKSceneScaleModeResizeFill - instead of a hardcoded bound that
           only matched one specific design canvas size. */
        CGFloat minCameraX = 0;
        CGFloat maxCameraX = 0;
        [self cameraClampMinX:&minCameraX maxX:&maxCameraX];

        /* Create a move action for the camera */
        if(self.camera.position.x + moveDistance >= minCameraX && self.camera.position.x + moveDistance <= maxCameraX){
            SKAction *moveCamera = [SKAction moveByX:moveDistance y:0 duration:moveDuration];
            [self.camera runAction:moveCamera];
        }
        
        /* Store last tracker position */
        self.lastTrackerPosition = self.trackerNode.position;
        
        /* Has penguin come to a near stand still */
        CGFloat idleVelocity = 0.15;
        
        /* Is the penguin currently joined to the catapult */
        int nodeJoints = (int)self.trackerNode.physicsBody.joints.count;
        CGFloat length = sqrt(self.trackerNode.physicsBody.velocity.dx*self.trackerNode.physicsBody.velocity.dx + self.trackerNode.physicsBody.velocity.dy*self.trackerNode.physicsBody.velocity.dy);
        if(length < idleVelocity && nodeJoints == 0) {
                
                /* Reset tracker node */

            
                /* Move camera back to start position - clamped into the
                   background's bounds, since x=0 (the level's authored
                   start) can fall outside them on a wider-than-design
                   screen. */
                SKAction *resetCamera = [SKAction moveToX:[self cameraHomeX] duration:1.0];
                [self.camera runAction:resetCamera];
                
                /* Reset catapult arm */
                self.catapultArm.physicsBody.velocity = CGVectorMake(0,0);
                self.catapultArm.physicsBody.angularVelocity = 0.0;
                self.catapultArm.zRotation = 0;
                self.catapultArm.position = CGPointMake(-81,31);
                
                /* Remove penguin */
            SKAction * removeNode = [SKAction removeFromParent];
            [self.trackerNode runAction:removeNode];
//            self.trackerNode = nil;
            }
    }
    
    /* Store current update step time */
    self.lastTimeInterval = currentTime;

}

-(void)didBeginContact:(SKPhysicsContact *)contact{
    /* Physics contact delegate implementation */
    
    /* Get references to the bodies involved in the collision */
    SKPhysicsBody *contactA = contact.bodyA;
    SKPhysicsBody *contactB = contact.bodyB;
    
    /* Get references to the physics body parent SKSpriteNode */
    SKSpriteNode *nodeA = (SKSpriteNode*)contactA.node;
    SKSpriteNode *nodeB = (SKSpriteNode*)contactB.node;
    
    /* Was a donut involved? */
    if(contactA.categoryBitMask == 2 || contactB.categoryBitMask == 2){
        
        /* Was it more than a gentle nudge? */
        if(contact.collisionImpulse > 2.0){
            
            /* Kill Donut(s) */
            if(contactA.categoryBitMask == 2){
               [self dieDonut:nodeA];
            }
            if(contactB.categoryBitMask == 2){
                 [self dieDonut:nodeB];
            }
        }
    }
}
-(void)dieDonut:(SKNode*)node{
    /* Donut death*/
    if(node != nil && node.parent != nil)
    {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            /* Load our particle effect */
            SKEmitterNode *particles = [SKEmitterNode nodeWithFileNamed: @"DonutExplosion"];
            
            /* Convert node location (currently inside LevelHolder, to scene space) */
            particles.position = [self convertPoint:node.position fromNode:node];
            
            /* Restrict total particles to reduce runtime of particle */
            particles.numParticlesToEmit = 10;
            
            /* Add particles to scene */
            [self addChild:particles];
            
            /* Play SFX */
            SKAction *donutSFX = [SKAction playSoundFileNamed:@"sfx_poof.caf" waitForCompletion: false];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self runAction:donutSFX completion:^{
                    [node removeFromParent];//runAction:donutDeath
                }];
            }) ;
        });
       
        

    }

}

- (void)didChangeSize:(CGSize)oldSize {
    [super didChangeSize:oldSize];
    [self resizeBackgroundToFillScreen];
    [self clampCameraXWithinBackground];
}

/* Grow the background to cover the current viewport (self.size) on devices
   whose screen is bigger than the design canvas the level was authored for,
   without ever shrinking it below its authored size - which would break the
   camera clamp logic below that relies on the background's bounds. */
- (void)resizeBackgroundToFillScreen {
    if (self.background == nil || CGSizeEqualToSize(_backgroundOriginalSize, CGSizeZero)) {
        return;
    }
    CGFloat targetWidth = MAX(_backgroundOriginalSize.width, self.size.width);
    CGFloat targetHeight = MAX(_backgroundOriginalSize.height, self.size.height);
    self.background.size = CGSizeMake(targetWidth, targetHeight);
}

/* The horizontal camera range - in scene coordinates - within which the
   viewport stays fully covered by the background. Shared by the initial
   camera placement and the panning clamp in update:. */
- (void)cameraClampMinX:(CGFloat *)minX maxX:(CGFloat *)maxX {
    if (self.background == nil) {
        *minX = 0;
        *maxX = 0;
        return;
    }
    CGFloat halfViewWidth = self.size.width / 2.0;
    CGFloat backgroundLeftEdge = self.background.position.x - (self.background.size.width * self.background.anchorPoint.x);
    CGFloat backgroundRightEdge = self.background.position.x + (self.background.size.width * (1.0 - self.background.anchorPoint.x));
    *minX = backgroundLeftEdge + halfViewWidth;
    *maxX = backgroundRightEdge - halfViewWidth;
}

/* The level was authored assuming the camera starts at x=0, which only kept
   the viewport within the background on the original design canvas. On a
   wider device (SKSceneScaleModeResizeFill grows self.size to match the real
   screen), that viewport can extend past the background's left/right edge,
   showing empty scene background behind it. Re-center/clamp the camera into
   the background's bounds whenever the size is known. */
- (void)clampCameraXWithinBackground {
    if (self.background == nil || self.camera == nil) {
        return;
    }
    self.camera.position = CGPointMake([self clampCameraX:self.camera.position.x], self.camera.position.y);
}

/* Clamp an arbitrary target x into the background's bounds. */
- (CGFloat)clampCameraX:(CGFloat)x {
    CGFloat minCameraX = 0;
    CGFloat maxCameraX = 0;
    [self cameraClampMinX:&minCameraX maxX:&maxCameraX];
    if (minCameraX > maxCameraX) {
        return (minCameraX + maxCameraX) / 2.0;
    }
    return MIN(MAX(x, minCameraX), maxCameraX);
}

/* Where the camera should sit when "returning to the catapult/bear" - the
   level's authored home position (x=0), clamped into the background's
   bounds so it never drifts back into the empty-scene gap on wide screens. */
- (CGFloat)cameraHomeX {
    return [self clampCameraX:0];
}

@end
