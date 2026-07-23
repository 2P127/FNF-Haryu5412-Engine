package flixel.system;

import openfl.Assets;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.system.FlxAssets.FlxShader;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;

class FlxSplash extends FlxState
{
	public static var nextState:Class<FlxState>;

	inline static final LOGO_PATH:String = "assets/images/exodusLogo.png";
	inline static final SOUND_PATH:String = "assets/sounds/team.ogg";
	inline static final LOGO_PIXEL_SIZE:Int = 50;

	/**
	 * @since 4.8.0
	 */
	public static var muted:Bool = #if html5 true #else false #end;
	
	var _logo:FlxSprite;
	var _text:FlxText;
	var _logoPixelShader:SplashPixelShader;
	var _textPixelShader:SplashPixelShader;
	
	var _cachedBgColor:FlxColor;
	var _cachedTimestep:Bool;
	var _cachedAutoPause:Bool;
	
	override public function create():Void
	{
		openfl.display.FPS.setForceHidden(true);

		_cachedBgColor = FlxG.cameras.bgColor;
		FlxG.cameras.bgColor = FlxColor.BLACK;

		// This is required for sound and animation to synch up properly
		_cachedTimestep = FlxG.fixedTimestep;
		FlxG.fixedTimestep = false;

		_cachedAutoPause = FlxG.autoPause;
		FlxG.autoPause = false;

		#if FLX_KEYBOARD
		FlxG.keys.enabled = false;
		#end

		_logo = new FlxSprite().loadGraphic(LOGO_PATH);
		_logo.antialiasing = true;
		_logo.alpha = 0;
		_logoPixelShader = new SplashPixelShader();
		_logoPixelShader.pixelSize.value = [LOGO_PIXEL_SIZE];
		_logo.shader = _logoPixelShader;
		add(_logo);

		_text = new FlxText(0, 0, 220, "PRESENTS", 24);
		_text.alignment = CENTER;
		_text.alpha = 0;
		_textPixelShader = new SplashPixelShader();
		_textPixelShader.pixelSize.value = [LOGO_PIXEL_SIZE];
		_text.shader = _textPixelShader;
		add(_text);

		onResize(FlxG.width, FlxG.height);

		FlxTween.tween(_logo, {alpha: 1}, 0.75, {ease: FlxEase.quadOut});
		FlxTween.tween(_text, {alpha: 0.85}, 0.75, {ease: FlxEase.quadOut});
		FlxTween.num(LOGO_PIXEL_SIZE, 1, 1.1, {ease: FlxEase.quadOut}, updateLogoPixelation);

		#if FLX_SOUND_SYSTEM
		if (!muted)
		{
			FlxG.sound.load(Assets.getSound(SOUND_PATH)).play();
		}
		#end

		new FlxTimer().start(2.6, function(_)
		{
			FlxTween.num(1, LOGO_PIXEL_SIZE, 0.7, {ease: FlxEase.quadIn}, updateLogoPixelation);
			FlxTween.tween(_logo, {alpha: 0}, 1.0, {ease: FlxEase.quadOut, onComplete: (_)->complete()});
			FlxTween.tween(_text, {alpha: 0}, 1.0, {ease: FlxEase.quadOut});
		});
	}

	override public function destroy():Void
	{
		if (_logo != null) _logo.shader = null;
		if (_text != null) _text.shader = null;
		_logo = null;
		_text = null;
		_logoPixelShader = null;
		_textPixelShader = null;
		super.destroy();
	}

	function complete()
	{
		FlxG.cameras.bgColor = _cachedBgColor;
		FlxG.fixedTimestep = _cachedTimestep;
		FlxG.autoPause = _cachedAutoPause;
		#if FLX_KEYBOARD
		FlxG.keys.enabled = true;
		#end

		openfl.display.FPS.setForceHidden(false);
		if (Main.fpsVar != null) Main.fpsVar.setCounterVisible(ClientPrefs.showFPS);
		FlxG.switchState(Type.createInstance(nextState, []));
		FlxG.game._gameJustStarted = true;
	}

	function updateLogoPixelation(value:Float):Void
	{
		final pixelSize:Float = Math.max(1, value);
		if (_logoPixelShader != null) _logoPixelShader.pixelSize.value = [pixelSize];
		if (_textPixelShader != null) _textPixelShader.pixelSize.value = [pixelSize];
	}

	override public function onResize(Width:Int, Height:Int):Void
	{
		super.onResize(Width, Height);

		if (_logo == null || _text == null) return;

		var maxWidth:Float = FlxG.width * 0.68;
		var maxHeight:Float = FlxG.height * 0.55;
		var logoScale:Float = Math.min(maxWidth / _logo.frameWidth, maxHeight / _logo.frameHeight);
		if (logoScale > 1) logoScale = 1;

		_logo.scale.set(logoScale, logoScale);
		_logo.updateHitbox();
		_logo.x = (FlxG.width - _logo.width) / 2;
		_logo.y = (FlxG.height - _logo.height) / 2 - 36;

		_text.fieldWidth = Math.max(_logo.width, 220);
		_text.x = (FlxG.width - _text.fieldWidth) / 2;
		_text.y = _logo.y + _logo.height + 22;
	}
}

class SplashPixelShader extends FlxShader
{
	@:glFragmentSource('
		#pragma header
		uniform float pixelSize;

		void main()
		{
			float safePixelSize = max(pixelSize, 1.0);
			vec2 texelSize = safePixelSize / openfl_TextureSize;
			vec2 coord = floor(openfl_TextureCoordv / texelSize) * texelSize + texelSize * 0.5;
			gl_FragColor = flixel_texture2D(bitmap, clamp(coord, vec2(0.0), vec2(1.0)));
		}')
	public function new()
	{
		super();
		pixelSize.value = [1.0];
	}
}
