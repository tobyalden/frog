package entities;

import haxepunk.*;
import haxepunk.graphics.*;
import haxepunk.masks.*;
import haxepunk.math.*;
import haxepunk.Tween;
import haxepunk.tweens.motion.*;
import haxepunk.tweens.misc.*;
import haxepunk.utils.*;
import scenes.*;

class MovingPlatform extends Entity
{
    public static inline var SPEED = 40;

    private var sprite:ColoredRect;
    private var path:LinearPath;
    private var oldPosition:Vector2;
    private var pathPoints:Array<Vector2>;

    public function new(x:Float, y:Float, width:Int, height:Int, pathPoints:Array<Vector2>) {
        super(x, y);
        this.pathPoints = pathPoints;
        type = "platform";
        mask = new Hitbox(width, height);
        sprite = new ColoredRect(width, height, 0xFF0000);
        graphic = sprite;
        //path = new LinearPath(TweenType.Looping);
        //for(point in pathPoints) {
            //path.addPoint(point.x, point.y);
        //}
        //path.setMotionSpeed(SPEED);
        //addTween(path, true);
        oldPosition = new Vector2();
    }

    public function shiftPathPointsX(shiftX:Float) {
        path = new LinearPath(TweenType.Looping);
        for(point in pathPoints) {
            point.x += shiftX;
            path.addPoint(point.x, point.y);
        }
        path.setMotionSpeed(SPEED);
        addTween(path, true);
    }

    override public function update() {
        var player = cast(scene, GameScene).player;

        // Horizontal movement
        var carryPlayer = (
            player.collideWith(this, player.x, player.y + 1) != null
            && player.collide("walls", player.x, player.y + 1) == null
        );
        moveTo(path.x, y);
        if(carryPlayer) {
            player.moveBy(path.x - oldPosition.x, 0, ["walls", "platform"]);
        }
        if(collideWith(player, x, y) != null) {
            if(centerX < player.centerX) {
                player.moveTo(right, player.y);
            }
            else if(centerX > player.centerX) {
                player.moveTo(left - player.width, player.y);
            }
        }

        // Vertical movement
        carryPlayer = (
            player.collideWith(this, player.x, player.y + 1) != null
            && player.collide("walls", player.x, player.y + 1) == null
        );
        moveTo(x, path.y);
        if(player.collideWith(this, player.x, player.y) != null && player.y < y) {
            carryPlayer = true;
        }
        if(carryPlayer) {
            player.moveTo(player.x, top - player.height, ["walls", "platform"]);
        }
        else if(player.collideWith(this, player.x, player.y) != null) {
            player.moveTo(player.x, bottom);
        }

        oldPosition.setTo(x, y);
        super.update();

    }
}
