package com.danhett;

import com.danhett.cornerhouse.Config;
import com.danhett.cornerhouse.Machine;
import com.danhett.cornerhouse.Printer;
import com.danhett.cornerhouse.Twitter;

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

import org.mongodb.Cursor;
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
    private var twitter:Twitter;
    private var found:Bool;

    private var unprinted:Array<Dynamic>;

	private function new() 
	{
		super();

		self_reference = this;

		setupPanel();

		getConfig();
	}


	/**
	 * PANEL SETUP
	 */
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

		var btn = cast(panel.getChildByName("submitBtn"), MovieClip);
		btn.buttonMode = true;
		btn.addEventListener(MouseEvent.CLICK, submitNewResponse);
	}


	/**
	 * LOAD CONFIGURATION
	 */
	private function getConfig():Void
	{
		log("Loading configuration...");

		config = new Config();
		config.addEventListener(Event.COMPLETE, onConfigurationFound);
		config.loadConfig("assets/config.xml");
	}


	/**
	 * CONFIGURATION FOUND - SET UP COMPONENTS
	 */
	private function onConfigurationFound(e:Event):Void
	{
		log("Configuration loaded. Setting up.");

		connectToDatabase();

		connectToTwitter();

		startMonitoring();
	}


	/**
	 * LOG INTO MONGODB
	 */
	private function connectToDatabase():Void
	{
		mongo = new Mongo(config.MONGO_URL, config.MONGO_PORT);
        db = mongo.chtest; 
        db.login(config.LOGIN, config.PASS); 
        
        log("Connected to database. Found " + db.messages.find().getDocs().length + " messages.");
	}


	/**
	 * START GETTING TWEETS
	 */
	private function connectToTwitter():Void
	{
		twitter = new Twitter();
		twitter.setupTwitter(config.CONSUMER_KEY, config.CONSUMER_SECRET);
	}


	/**
	 * START GETTING TWEETS
	 */
	private function startMonitoring():Void
	{
		timer = new Timer(config.SECONDS * 1000);
		timer.addEventListener(TimerEvent.TIMER, findNextUnprintedMessage);
		timer.start();
	}


	/**
	 * SUBMIT TEST RESPONSE
	 */
	private function submitNewResponse(e:MouseEvent):Void
	{
		if(nameInput.text == "")
			log("Name required for submission.");
		else if(messageInput.text == "")
			log("Message required for submission.");
		else
		{
	        addEntry(messageInput.text, nameInput.text);
	        nameInput.text = "";
	        messageInput.text = "";

	        log("Added entry to database!");
		}	
	}


	/**
	 * PUSH ENTRY INTO DATABASE
	 * Used for test panel, and also adding new tweets into the DB
	 */
	public function addEntry(_message:String, _submitter:String, _isTweet:Bool = false):Void
	{
		var msg = 
        {
            message: _message,
            submitter: _submitter,
            submitDate: Date.now(),
            hasPrinted: false,
            isTweet: _isTweet
        };

        // Important: check to see if this message already exists
        if(!existsInDatabase(msg))
        {
        	log("Adding new message to database: " + msg.message);

        	db.messages.insert(msg);
        }
        else
        {
    		// message is already in the database, do nothing for now
        }
	}


	/**
	 * CHECK IF MESSAGE ALREADY EXISTS
	 * Stops duplicate tweets being pushed into the database
	 */
	public function existsInDatabase(msg:Dynamic):Bool
	{
		var query = db.messages.find( {message: msg.message, submitter: msg.submitter } ).getDocs();

		if(query.length > 0)
			return true;

		return false;
	}


	/**
	 * FIND NEXT UNPRINTED MESSAGES
	 * This method is continually called on a timer
	 */
	private function findNextUnprintedMessage(e:TimerEvent):Void
	{		
		found = false;

		for(message in db.messages.find()) 
        {
            if(message.hasPrinted == false)
            {
            	var unprintedMessage = message;
            	printMessage(unprintedMessage);
            	found = true;
            	break;
            }
        }
	}


	/**
	 * SEND TO PRINTER
	 * Physically prints the message, invalidates it in the DB, and activates the machine!
	 */
	private function printMessage(msg:Dynamic):Void
	{
		log("Printing message...");

		// Set the entry to printed in the database
		msg.hasPrinted = true;
        db.messages.update({message: msg.message, submitDate:msg.submitDate}, msg); 

        // Print the actual card (saves it to a directory)
		Printer.saveToDesktop(msg.message, msg.submitter, msg.submitDate);

		// Signal the arduino to light up the machine and move about
		Machine.activate();
	}


	/**
	 * LOGGING
	 */
	public function log(msg:Dynamic):Void
	{
		readout.appendText(msg + "\n");
		readout.scrollV = readout.maxScrollV;
	}


	/**
	 * DIRTY SINGLETON
	 */
	private static var self_reference:App;
	public static function Instance():App { return self_reference; }
}