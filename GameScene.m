//
//  GameScene.m
//  AngryBirdDemo
//
//  Created by Romain Mullot on 05/03/2018.
//  Copyright © 2018 Romain Mullot. All rights reserved.
//

#import "GameScene.h"
#import <SceneKit/SceneKit.h>
#import "ABReferenceNode.h"
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
                
                // Set the scale mode to scale to fit the window
                scene.scaleMode = SKSceneScaleModeAspectFit;
                
                // Present the scene
                [view presentScene:scene];
            }
            
            // Debug helpers
            view.showsFPS = true;
            view.showsPhysics = true;
            view.showsDrawCount = true;
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
    
    /* Let it fly!, remove joints used in catapult launch */
    if (self.touchJoint != nil) {
        [self.physicsWorld removeJoint:self.touchJoint];
    }
    if (self.penguinJoint != nil) {
        [self.physicsWorld removeJoint:self.penguinJoint];
    }
}


-(void)update:(CFTimeInterval)currentTime {
    /* Check there is a node to track and camera is present */
    if(self.trackerNode != nil && self.camera != nil){
        
        /* Calculate horizontal distance to move */
        CGFloat moveDistance = self.trackerNode.position.x - self.lastTrackerPosition.x;
        
        /* Duration is time between updates */
        CGFloat moveDuration = currentTime - self.lastTimeInterval;
        
        /* Create a move action for the camera */
        if(self.camera.position.x + moveDistance >= 0 && self.camera.position.x + moveDistance <= 392){
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

            
                /* Move camera back to start position */
                SKAction *resetCamera = [SKAction moveToX:0 duration:1.0];
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
    if(node != nil)
    {
        /* Load our particle effect */
        SKEmitterNode *particles = [SKEmitterNode nodeWithFileNamed: @"DonutExplosion"];
        
        /* Convert node location (currently inside LevelHolder, to scene space) */
        particles.position = [self convertPoint:node.position fromNode:node];
        
        /* Restrict total particles to reduce runtime of particle */
        particles.numParticlesToEmit = 25;
        
        /* Add particles to scene */
        [self addChild:particles];
        
        /* Play SFX */
        SKAction *donutSFX = [SKAction playSoundFileNamed:@"sfx_donut" waitForCompletion: false];
        [self runAction:donutSFX];
        
        /* Create our donut removal action */
        SKAction *donutDeath = [SKAction removeFromParent];
        [node runAction:donutDeath];
    }
  
}
@end
