package entities;

import haxepunk.*;
import haxepunk.graphics.*;
import haxepunk.input.*;
import haxepunk.masks.*;
import haxepunk.math.*;
import haxepunk.Tween;
import haxepunk.tweens.misc.*;
import haxepunk.utils.*;
import scenes.*;

class Player extends Entity
{
    public static inline var MIN_SPEED = 37.5;
    public static inline var MAX_SPEED = 150;
    public static inline var GRAVITY = 800;
    public static inline var MAX_JUMP_POWER = 400;
    public static inline var MIN_JUMP_POWER = 100;
    public static inline var MAX_JUMP_POWER_HOLD_TIME = 1;
    public static inline var MAX_FALL_SPEED = 400;
    public static inline var SPAWN_PAUSE = 0.1;

    public static var solids = ["walls", "platform"];

    public var isDead(default, null):Bool;
    private var sprite:Spritemap;
    private var velocity:Vector2;
    private var canMove:Bool;
    private var canJump:Bool;
    private var timeJumpHeld:Float;
    //private var wasOnGround:Bool;

    public function new(x:Float, y:Float) {
        super(x, y);
        mask = new Hitbox(10, 10);
        sprite = new Spritemap("graphics/player.png", 10, 10);
        sprite.add("idle", [0]);
        sprite.add("charge", [1, 0], 12);
        sprite.play("idle");
        sprite.y = 10;
        sprite.originY = 10;
        graphic = sprite;
        velocity = new Vector2();
        isDead = false;
        canMove = false;
        canJump = false;
        HXP.alarm(SPAWN_PAUSE, function() {
            canMove = true;
        });
        timeJumpHeld = 0;
        //wasOnGround = false;
    }

    override public function update() {
        if(isDead) {
            super.update();
            return;
        }
        if(canMove) {
            movement();
        }
        collisions();
        animation();
        super.update();
    }

    private function movement() {
        if(isOnGround()) {
            //if(!wasOnGround) {
                //cast(scene, GameScene).updateCamera();
            //}
            //wasOnGround = true;
            velocity.x = 0;
            velocity.y = 0;
            if(Input.pressed("jump")) {
                canJump = true;
            }
            if(Input.check("jump")) {
                timeJumpHeld += HXP.elapsed;
            }
            if(Input.released("jump") && canJump) {
                velocity.x = MathUtil.lerp(
                    MIN_SPEED,
                    MAX_SPEED,
                    Math.min(timeJumpHeld, MAX_JUMP_POWER_HOLD_TIME)
                );
                velocity.y = MathUtil.lerp(
                    -MIN_JUMP_POWER,
                    -MAX_JUMP_POWER,
                    Math.min(timeJumpHeld, MAX_JUMP_POWER_HOLD_TIME)
                );
                timeJumpHeld = 0;
            }
        }
        else {
            //wasOnGround = false;
            canJump = false;
            timeJumpHeld = 0;
        }

        var gravity:Float = GRAVITY;
        //if(Math.abs(velocity.y) < JUMP_CANCEL) {
            //gravity *= 0.5;
        //}
        velocity.y += gravity * HXP.elapsed;

        velocity.y = Math.min(velocity.y, MAX_FALL_SPEED);

        moveBy(
            velocity.x * HXP.elapsed,
            velocity.y * HXP.elapsed,
            Player.solids
        );
    }

    private function collisions() {
        if(y > GameScene.GAME_HEIGHT) {
            die();
        }
        else if(collide("hazard", x, y) != null) {
            die();
        }
    }

    private function animation() {
        sprite.scaleY = MathUtil.lerp(
            1,
            0.5,
            Ease.cubeOut(Math.min(timeJumpHeld, MAX_JUMP_POWER_HOLD_TIME))
        );
        if(timeJumpHeld >= MAX_JUMP_POWER_HOLD_TIME) {
            sprite.play("charge");
        }
        else {
            sprite.play("idle");
        }
    }

    public function die() {
        isDead = true;
        visible = false;
        explode();
        Main.sfx["die"].play();
        cast(HXP.scene, GameScene).onDeath();
    }

    private function explode() {
        var numExplosions = 50;
        var directions = new Array<Vector2>();
        for(i in 0...numExplosions) {
            var angle = (2/numExplosions) * i;
            directions.push(new Vector2(Math.cos(angle), Math.sin(angle)));
            directions.push(new Vector2(-Math.cos(angle), Math.sin(angle)));
            directions.push(new Vector2(Math.cos(angle), -Math.sin(angle)));
            directions.push(new Vector2(-Math.cos(angle), -Math.sin(angle)));
        }
        var count = 0;
        for(direction in directions) {
            direction.scale(0.8 * Math.random());
            direction.normalize(
                Math.max(0.1 + 0.2 * Math.random(), direction.length)
            );
            direction.scale(2);
            var explosion = new Particle(
                centerX, centerY, directions[count], 1, 1
            );
            explosion.layer = -99;
            HXP.scene.add(explosion);
            count++;
        }

#if desktop
        Sys.sleep(0.02);
#end
        HXP.scene.camera.shake(0.25, 4);
    }

    override public function moveCollideX(e:Entity) {
        velocity.x = 0;
        return true;
    }

    override public function moveCollideY(e:Entity) {
        velocity.y = 0;
        return true;
    }

    private function collideAny(types:Array<String>, virtualX:Float, virtualY:Float) {
        for(collideType in types) {
            var collided = collide(collideType, virtualX, virtualY);
            if(collided != null) {
                return collided;
            }
        }
        return null;
    }

    public function isOnGround() {
        return collideAny(Player.solids, x, y + 1) != null;
    }
}
