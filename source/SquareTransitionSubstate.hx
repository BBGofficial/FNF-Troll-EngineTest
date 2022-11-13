package;

import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.transition.FlxTransitionSprite.TransitionStatus;
import flixel.addons.transition.TransitionSubstate;
import flixel.math.*;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.addons.display.shapes.FlxShapeBox;
import flixel.util.FlxTimer;

typedef SquareTransitionInfo = {
	var sX:Null<Float>;
	var sY:Null<Float>;
	var sW:Null<Float>;
	var sH:Null<Float>;
	
	var eX:Null<Float>;
	var eY:Null<Float>;
	var eW:Null<Float>;
	var eH:Null<Float>;

	var dur:Null<Float>;
}

class SquareTransitionSubstate extends TransitionSubstate
{
	public static var info:SquareTransitionInfo = cast {};

	var _finalDelayTime:Float = 0.0;

	public static var defaultCamera:FlxCamera;
	public static var nextCamera:FlxCamera;

	var funkyRectangle:FlxShapeBox;

	public override function destroy():Void
	{
		super.destroy();

		if (funkyRectangle != null)
			funkyRectangle.destroy();
		
		finishCallback = null;
	}

	function onFinish(f:FlxTimer):Void
	{
		if (finishCallback != null)
		{
			finishCallback();
			finishCallback = null;
		}
	}

	function delayThenFinish():Void
	{
		new FlxTimer().start(_finalDelayTime, onFinish); // force one last render call before exiting
	}

	override public function start(status: TransitionStatus){
		var cam = nextCamera != null ? nextCamera : (defaultCamera!=null?defaultCamera:FlxG.cameras.list[FlxG.cameras.list.length - 1]);
		cameras = [cam];

		nextCamera = null;

		// peak programming
		if (info.sX == null)
			info.sX = 0;
		if (info.sY == null)
			info.sY = 0;
		if (info.sW == null)
			info.sW = 0;
		if (info.sH == null)
			info.sH = 0;
		if (info.eX == null)
			info.eX = 0;
		if (info.eY == null)
			info.eY = 0;
		if (info.eW == null)
			info.eW = 0;
		if (info.eH == null)
			info.eH = 0;

		if (info.dur == null)
			info.dur = 0.3;

		funkyRectangle = new FlxShapeBox(info.sX, info.sY, info.sW, info.sH, {thickness: 3, color: FlxColor.fromRGB(255, 242, 0)}, FlxColor.BLACK);
		funkyRectangle.cameras = cameras;
		add(funkyRectangle);

		FlxTween.tween(
			funkyRectangle, 
			{
				x: info.eX, 
				y: info.eY,
				width: info.eW,
				height: info.eH,
				shapeWidth: info.eW,
				shapeHeight: info.eH
			}, 
			info.dur,
			{
				ease: FlxEase.quadOut,
				onComplete: function(t:FlxTween){delayThenFinish();}
			}
		);
	}
}