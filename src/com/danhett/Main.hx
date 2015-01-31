package com.danhett;

import com.danhett.cornerhouse.Config;
import openfl.Assets;
import openfl.display.BitmapData;
import openfl.display.Sprite;
import openfl.display.MovieClip;
import openfl.events.Event;
import openfl.events.MouseEvent;
import openfl.events.TimerEvent;
import openfl.text.TextField;
import openfl.text.TextFieldType;
import openfl.text.TextFieldAutoSize;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;
import openfl.utils.ByteArray;
import openfl.utils.SystemPath;
import openfl.utils.Timer;
import org.mongodb.Mongo;
import org.mongodb.Database;
import sys.io.FileOutput;

class Main extends Sprite 
{
	private var clip:MovieClip;
	private var mongo:Mongo;
    private var db:Database;
    private var readout:TextField;
    private var nameInput:TextField;
    private var messageInput:TextField;
    private var timer:Timer;
    private var config:Config;

    private var unprinted:Array<Dynamic>;

	public function new() 
	{
		super();

		clip = Assets.getMovieClip ("assets:BaseClip");
		addChild(clip);

		readout = cast(clip.getChildByName("readout"), TextField);
		readout.type = TextFieldType.DYNAMIC;

		nameInput = cast(clip.getChildByName("nameInput"), TextField);
		nameInput.type = TextFieldType.INPUT;

		messageInput = cast(clip.getChildByName("messageInput"), TextField);
		messageInput.type = TextFieldType.INPUT;

		getConfig();
	}

	private function getConfig():Void
	{
		print("Loading configuration...");

		config = new Config();
		config.addEventListener(Event.COMPLETE, setupDatabase);
		config.loadConfig("assets/config.xml");
	}

	private function setupDatabase(e:Event):Void
	{
		print("Connecting to database...");

		mongo = new Mongo(config.MONGO_URL, config.MONGO_PORT);
        db = mongo.chtest; 
        db.login(config.LOGIN, config.PASS); 
        
        print("Found " + db.messages.find().getDocs().length + " messages in the database.");

        var btn = cast(clip.getChildByName("submitBtn"), MovieClip);
		btn.buttonMode = true;
		btn.addEventListener(MouseEvent.CLICK, submitNewResponse);

		timer = new Timer(config.SECONDS * 1000);
		timer.addEventListener(TimerEvent.TIMER, findNextUnprintedMessage);
		timer.start();
	}


	/**
	 * SUBMIT NEW RESPONSE
	 */
	private function submitNewResponse(e:MouseEvent):Void
	{
		if(nameInput.text == "")
			print("Name required for submission.");
		else if(messageInput.text == "")
			print("Message required for submission.");
		else
		{
	        var msg = 
	        {
	            message: messageInput.text,
	            submitter: nameInput.text,
	            submitDate: Date.now(),
	            hasPrinted: false
	        };

	        db.messages.insert(msg);

	        print("Added entry to database!");
	        nameInput.text = "";
	        messageInput.text = "";
		}	
	}


	/**
	 * FIND NEW UNPRINTED MESSAGES
	 */
	private function findNextUnprintedMessage(e:TimerEvent):Void
	{
		//var found:Int = db.messages.find().getDocs().length;
		
		for(message in db.messages.find()) 
        {
            if(message.hasPrinted == false)
            {
            	var unprintedMessage = message;
            	printMessage(unprintedMessage);
            	break;
            }
        }

		//createSnapshot(db.messages.find().getDocs()[randIndex].message, db.messages.find().getDocs()[randIndex].submitter, randIndex);
	}

	private function printMessage(msg:Dynamic):Void
	{
		print("Printing message: " + msg.message);

		msg.hasPrinted = true;
        db.messages.update({message: msg.message, submitDate:msg.submitDate}, msg); 
	}


	/**
	 * CREATE SNAPSHOT
	 */
	private function createSnapshot(msg:String, submitter:String, index:Int):Void
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

		// Save the bitmap to the desktop for now - do we need to print directly from here?
		var b:ByteArray = image.encode("png", 1);
		var fo:FileOutput = sys.io.File.write( SystemPath.desktopDirectory + "/test" + index + ".png", true);
		fo.writeString(b.toString());
		fo.close();
	}


	/**
	 * PRINTING
	 */
	private function print(msg:Dynamic):Void
	{
		readout.appendText(msg + "\n");
	}
}