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
import sys.io.FileOutput;

class Printer extends EventDispatcher 
{
	public function new() 
	{
		super();
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
		var fo:FileOutput = sys.io.File.write( SystemPath.desktopDirectory + "/queue/" + submitter  + "_" + getIndex() + ".png", true);
		fo.writeString(b.toString());
		fo.close();
	}

	private static function getIndex():Int
	{
		return Math.round(Math.random() * 10000);
	}
}