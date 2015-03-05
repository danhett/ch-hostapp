/*
The MIT License (MIT)

Copyright (c) 2015 Dan Hett
See: https://github.com/danhett/ch-hostapp

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/

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
	private static var card:MovieClip;

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
	}

	public static function saveToDesktop(msg:String, submitter:String, submitDate:String):Void
	{
		// Create the card
		card = Assets.getMovieClip ("assets:Postcard");
		
		// Create the large message readout
		var msgReadout = cast(card.getChildByName("messageReadout"), TextField);
		msgReadout.type = TextFieldType.DYNAMIC;
		msgReadout.multiline = true;
		msgReadout.wordWrap = true;
		//msgReadout.autoSize = TextFieldAutoSize.LEFT;
		msgReadout.text = msg.split("O").join("0"); // fix for weird char bug

		if(msgReadout.text.length < 45)
		{
			scaleTextToFitInTextField( msgReadout, true );	
		}
		else
		{
			scaleTextToFitInTextField( msgReadout );
		}

		// Create the small "love from..." readout
		var subReadout = cast(card.getChildByName("submitterReadout"), TextField);
		subReadout.type = TextFieldType.DYNAMIC;
		subReadout.text = "Love from " + submitter;

		// Grab a snapshot of the whole shebang
		var image:BitmapData = new BitmapData( Std.int( card.width ), Std.int( card.height ), false, 0x00FF00);
		image.draw(card);

		// Encode it and write it to the desktop
		var b:ByteArray = image.encode("png", 1);
		var fo:FileOutput = File.write( SystemPath.desktopDirectory 
										+ workingDirectoryPath 
										+ submitter  
										+ "_" + getIndex() 
										+ ".png", true);
		
		fo.writeString(b.toString());
		fo.close();

		// clear up
		image.dispose();
		image = null;
		msgReadout = null;
		subReadout = null;
		card = null;
		fo = null;
	}

	private static function getIndex():Int
	{
		return Math.round(Math.random() * 10000000);
	}


	private static function scaleTextToFitInTextField( txt : TextField, isBodge:Bool = false):Void
	{
		if(!isBodge)
		{
			var f:TextFormat = txt.getTextFormat();

			f.size = ( txt.width > txt.height ) ? txt.width : txt.height;
			txt.setTextFormat( f );

			while( txt.textWidth > 900 || txt.textHeight > 440 ) 
			{    
				f.size = f.size - 1;    
				txt.setTextFormat( f );
			}

			txt.width = txt.textWidth + 4;
	     	txt.height = txt.textHeight + 4;
		}
		else
		{
			txt.height = txt.textHeight;

	     	if(txt.height >= 440)
	     	{
	     		txt.height = 440;
	     		txt.scaleX = txt.scaleY;
	     	}
		}

		txt.x = (card.width / 2) - (txt.width / 2);
		txt.y = (card.height / 2) - (txt.height / 2);
	}

}

