package com.danhett;

import com.danhett.cornerhouse.Config;
import com.danhett.cornerhouse.Printer;
import com.danhett.cornerhouse.TwitterChecker;
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

class App extends Sprite 
{
	private var panel:MovieClip;
	private var mongo:Mongo;
    private var db:Database;
    private var readout:TextField;
    private var nameInput:TextField;
    private var messageInput:TextField;
    private var timer:Timer;
    private var config:Config;
    private var twitter:TwitterChecker;

    private var unprinted:Array<Dynamic>;

	public function new() 
	{
		super();

		setupPanel();

		getConfig();
	}

	private function setupPanel():Void
	{
		panel = Assets.getMovieClip ("assets:BaseClip");
		addChild(panel);

		readout = cast(panel.getChildByName("readout"), TextField);
		readout.type = TextFieldType.DYNAMIC;
		readout.height = 500; // fixes weird textfield scrolling bug

		nameInput = cast(panel.getChildByName("nameInput"), TextField);
		nameInput.type = TextFieldType.INPUT;

		messageInput = cast(panel.getChildByName("messageInput"), TextField);
		messageInput.type = TextFieldType.INPUT;
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

        var btn = cast(panel.getChildByName("submitBtn"), MovieClip);
		btn.buttonMode = true;
		btn.addEventListener(MouseEvent.CLICK, submitNewResponse);

		timer = new Timer(config.SECONDS * 1000);
		timer.addEventListener(TimerEvent.TIMER, findNextUnprintedMessage);
		timer.start();

		checkTwitter();
	}

	private function checkTwitter():Void
	{
		twitter = new TwitterChecker();
		twitter.setupTwitter(config.CONSUMER_KEY, config.CONSUMER_SECRET);
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
	}

	private function printMessage(msg:Dynamic):Void
	{
		print("Printing message: " + msg.message);

		//msg.hasPrinted = true;
        //db.messages.update({message: msg.message, submitDate:msg.submitDate}, msg); 

		//Printer.saveToDesktop(msg.message, msg.submitter, 999);
	}


	/**
	 * PRINTING
	 */
	private function print(msg:Dynamic):Void
	{
		readout.appendText(msg + "\n");
		readout.scrollV = readout.maxScrollV;
	}
}