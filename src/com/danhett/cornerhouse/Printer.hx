package com.danhett.cornerhouse;

import haxe.xml.Fast;
import openfl.Assets;
import openfl.display.BitmapData;
import openfl.display.MovieClip;
import openfl.events.Event;
import openfl.events.EventDispatcher;
import openfl.text.TextField;
import openfl.text.TextFieldType;
import openfl.text.TextFieldAutoSize;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;
import openfl.utils.ByteArray;
import openfl.utils.SystemPath;
import sys.io.File;
import sys.io.FileOutput;
import sys.FileSystem;

class Printer extends EventDispatcher 
{
	public static var LIVE_DIR_NAME:String = '/queue/';
	public static var TEST_DIR_NAME:String = '/test_queue/';
	public static var workingDirectoryPath:String;

	public function new() 
	{
		super();
	}

	public static function setupFolders():Void
	{
		if( !FileSystem.exists( SystemPath.desktopDirectory + LIVE_DIR_NAME) )
			FileSystem.createDirectory( SystemPath.desktopDirectory + LIVE_DIR_NAME );

		if( !FileSystem.exists( SystemPath.desktopDirectory + TEST_DIR_NAME) )
			FileSystem.createDirectory( SystemPath.desktopDirectory + TEST_DIR_NAME );

		if(App.Instance().config.LIVE)
			workingDirectoryPath = LIVE_DIR_NAME;
		else
			workingDirectoryPath = TEST_DIR_NAME;

		trace("Working in " + workingDirectoryPath);
	}

	public static function saveToDesktop(msg:String, submitter:String, submitDate:String):Void
	{
		var card:MovieClip = Assets.getMovieClip ("assets:Postcard");
		var msgReadout = cast(card.getChildByName("readout"), TextField);
		msgReadout.type = TextFieldType.DYNAMIC;
		msgReadout.multiline = true;
		msgReadout.wordWrap = true;

		var form:TextFormat = new TextFormat();
		form.color = 0xCA3032;
		form.size = 55;
		form.font = "Arial";
		form.align = TextFormatAlign.CENTER;
		form.leading = 20;

		msgReadout.defaultTextFormat = form;
		msgReadout.text = msg;


		var subReadout = cast(card.getChildByName("submitter"), TextField);
		subReadout.type = TextFieldType.DYNAMIC;
		subReadout.text = "Submitted by: " + submitter;

		var image:BitmapData = new BitmapData( Std.int( card.width ), Std.int( card.height ), false, 0x00FF00);
		image.draw(card);

		var b:ByteArray = image.encode("png", 1);
		var fo:FileOutput = File.write( SystemPath.desktopDirectory + "/queue/" + submitter  + "_" + getIndex() + ".png", true);
		fo.writeString(b.toString());
		fo.close();
	}

	private static function getIndex():Int
	{
		return Math.round(Math.random() * 10000);
	}
}