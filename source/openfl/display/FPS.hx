package openfl.display;

import haxe.Timer;
import openfl.events.Event;
import openfl.text.TextField;
import openfl.text.TextFormat;
import flixel.FlxG;
import flixel.math.FlxMath;
#if gl_stats
import openfl.display._internal.stats.Context3DStats;
import openfl.display._internal.stats.DrawCallContext;
#end
#if flash
import openfl.Lib;
#end
#if openfl
import openfl.system.System;
#end

import openfl.system.Capabilities;

// C++ implementation for memory usage
#if cpp
@:cppFileCode('
#include <windows.h>
#include <psapi.h>

extern "C" double getMemoryUsageMB() {
    PROCESS_MEMORY_COUNTERS_EX memInfo;
    if (GetProcessMemoryInfo(GetCurrentProcess(), (PROCESS_MEMORY_COUNTERS*)&memInfo, sizeof(memInfo))) {
        return memInfo.WorkingSetSize / (1024.0 * 1024.0);
    }
    return -1;
}
')
#end


class FPS extends TextField
{
    public static var fpsText:TextField;
    public static var forceHidden:Bool = false;
    // Optional override for full overlay text (set by mods/Lua). If not null, replaces default content.
    public static var overrideText:String = null;
    // Optional extra info line appended to the default overlay (ignored if overrideText is used)
    public static var extraInfo:String = null;
    // Optional color override for the overlay text.
    public static var customColorOverride:Null<Int> = null;

    public var currentFPS(default, null):Int;

    @:noCompletion private var cacheCount:Int;
    @:noCompletion private var currentTime:Float;
    @:noCompletion private var times:Array<Float>;

    public function new(x:Float = 10, y:Float = 10, color:Int = 0x000000)
    {
        super();

        this.x = x;
        this.y = y;

        currentFPS = 0;
        selectable = false;
        mouseEnabled = false;
        defaultTextFormat = new TextFormat("VCR OSD Mono", 15, color);
        autoSize = LEFT;
        multiline = true;

        cacheCount = 0;
        currentTime = 0;
        times = [];

        #if flash
        addEventListener(Event.ENTER_FRAME, function(e)
        {
            var time = Lib.getTimer();
            __enterFrame(time - currentTime);
        });
        #end

        FPS.createFPSText();
    }

    public static function createFPSText() {
        fpsText = new TextField();
        fpsText.defaultTextFormat = new TextFormat("VCR OSD Mono", 14, 0xFFFFFFFF);
        fpsText.text = " ";
        fpsText.x = 5;
        fpsText.y = 5;
        fpsText.width = 200;
        fpsText.height = 50; 
        fpsText.border = false;
        fpsText.background = true;
        fpsText.backgroundColor = 0x000000;
        fpsText.textColor = 0xA8FFFFFF;
        fpsText.autoSize = LEFT;
        fpsText.alpha = 0.6;
        fpsText.visible = !forceHidden && ClientPrefs.showFPS;
        openfl.Lib.current.addChild(fpsText);
    }

    public static function setForceHidden(hidden:Bool):Void
    {
        forceHidden = hidden;
        if (fpsText != null) fpsText.visible = !hidden && ClientPrefs.showFPS;
    }

    public function setCounterVisible(show:Bool):Void
    {
        visible = show;
        if (fpsText != null) fpsText.visible = show && !forceHidden;
    }

    @:noCompletion
    private #if !flash override #end function __enterFrame(deltaTime:Float):Void
    {
        if (forceHidden && FlxG.state != null
            && Type.getClassName(Type.getClass(FlxG.state)) != "flixel.system.FlxSplash")
        {
            forceHidden = false;
            setCounterVisible(ClientPrefs.showFPS);
        }

        if (forceHidden || !ClientPrefs.showFPS) {
            if (fpsText != null) {
                fpsText.visible = false;
            }
            return;
        }

        if (fpsText != null) {
            fpsText.visible = true;
        }

        currentTime += deltaTime;
        times.push(currentTime);

        while (times[0] < currentTime - 1000)
        {
            times.shift();
        }

        var currentCount = times.length;
        currentFPS = Math.round((currentCount + cacheCount) / 2);
        if (currentFPS > ClientPrefs.framerate) currentFPS = ClientPrefs.framerate;

        if (currentCount != cacheCount)
        {
            var maxFPS = ClientPrefs.framerate;
            var fpsString = "FPS: " + currentFPS;
            var memoryMegas:Float = 0;
            var memoryString = "";
            var rawOS = Capabilities.os.toLowerCase();
            var osShort = "Unknown";
            if (rawOS.indexOf("windows") != -1) {
                osShort = "Windows";
                if (rawOS.indexOf("10") != -1) osShort += " 10";
                else if (rawOS.indexOf("11") != -1) osShort += " 11";
                else if (rawOS.indexOf("7") != -1) osShort += " 7";
            }
            else if (rawOS.indexOf("mac") != -1) {
                osShort = "macOS";
            }
            else if (rawOS.indexOf("linux") != -1) {
                osShort = "Linux";
            }
            else if (rawOS.indexOf("android") != -1) {
                osShort = "Android";
            }
            else if (rawOS.indexOf("ios") != -1) {
                osShort = "iOS";
            }
            var osString = ClientPrefs.showOS ? ("\nOS: " + osShort) : "";

            #if cpp
            memoryMegas = untyped __global__.getMemoryUsageMB();
            memoryMegas = FlxMath.roundDecimal(memoryMegas, 1);
            if (memoryMegas >= 1000) {
                var memoryGigas:Float = memoryMegas / 1000;
                memoryGigas = FlxMath.roundDecimal(memoryGigas, 2);
                memoryString = " • RAM: " + memoryGigas + " GB";
            } else {
                memoryString = " • RAM: " + memoryMegas + " MB";
            }
            #end

            // If override text is provided, use it entirely; otherwise build default and append extraInfo if present
            if (overrideText != null) {
                fpsText.htmlText = overrideText;
            } else {
                if (ClientPrefs.showRAM) {
                    fpsText.htmlText = fpsString + memoryString + osString;
                } else {
                    fpsText.htmlText = fpsString + osString;
                }
                if (extraInfo != null && extraInfo.length > 0) {
                    fpsText.htmlText += "\n" + extraInfo;
                }
            }

            // Default color is semi-white; pick red under heavy load unless custom override is set
            if (customColorOverride != null) {
                fpsText.textColor = customColorOverride;
            } else {
                fpsText.textColor = 0xA8FFFFFF;
                if (memoryMegas > 3000 || currentFPS <= ClientPrefs.framerate / 2)
                {
                    fpsText.textColor = 0xFFFF0000;
                }
            }

            #if (gl_stats && !disable_cffi && (!html5 || !canvas))
            fpsText.htmlText += "\ntotalDC: " + Context3DStats.totalDrawCalls();
            fpsText.htmlText += "\nstageDC: " + Context3DStats.contextDrawCalls(DrawCallContext.STAGE);
            fpsText.htmlText += "\nstage3DDC: " + Context3DStats.contextDrawCalls(DrawCallContext.STAGE3D);
            #end

            fpsText.htmlText += "\n";
        }

        cacheCount = currentCount;
    }
}
