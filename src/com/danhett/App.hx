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

package com.danhett;

import com.danhett.cornerhouse.Config;
import com.danhett.cornerhouse.Printer;
import com.danhett.cornerhouse.Submitter;
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
    private var printTimer:Timer;
    private var twitter:Twitter;
    private var found:Bool;
    private var toggleBtn:MovieClip;
    private var testPrint:MovieClip;
    private var unprinted:Array<Dynamic>;

    private var appModeMarker:MovieClip;
    private var databaseMarker:MovieClip;
    private var twitterMarker:MovieClip;

    private var submitter:Submitter;

    public var config:Config;
    public var ACTIVE:Bool = true;

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

		nameInput = cast(panel.getChildByName("nameInput"), TextField);
		nameInput.type = TextFieldType.INPUT;

		messageInput = cast(panel.getChildByName("messageInput"), TextField);
		messageInput.type = TextFieldType.INPUT;

		var btn = cast(panel.getChildByName("submitBtn"), MovieClip);
		btn.buttonMode = true;
		btn.addEventListener(MouseEvent.CLICK, submitNewResponse);

		testPrint = cast(panel.getChildByName("testPrint"), MovieClip);
		testPrint.stop();
		testPrint.buttonMode = true;
		testPrint.addEventListener(MouseEvent.CLICK, doTestPrint);

		toggleBtn = cast(panel.getChildByName("activeToggle"), MovieClip);
		toggleBtn.stop();
		toggleBtn.buttonMode = true;
		toggleBtn.addEventListener(MouseEvent.CLICK, toggleMachine);

		appModeMarker = cast(panel.getChildByName("appModeMarker"), MovieClip);
		appModeMarker.stop();

		databaseMarker = cast(panel.getChildByName("databaseMarker"), MovieClip);
		databaseMarker.stop();

		twitterMarker = cast(panel.getChildByName("twitterMarker"), MovieClip);
		twitterMarker.stop();
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

		showAppMode(config.LIVE);

		Printer.setupFolders();

		connectToDatabase();

		connectToTwitter();

		startMonitoring();

		submitter = new Submitter();
	}


	/**
	 * LOG INTO MONGODB
	 */
	private function connectToDatabase():Void
	{
        try
        {
    		mongo = new Mongo(config.MONGO_URL, config.MONGO_PORT);
        	
			if(config.LIVE)
				db = mongo.chlive;
			else
	        	db = mongo.chtest;

    		db.login(config.LOGIN, config.PASS); 
        
        	log("Connected to database!");

        	showDBConnection(true);
        }
        catch(err:Dynamic)
        {
        	log("ERROR! Couldn't connect to the database. Check internet connection.");

        	showDBConnection(false);
        }
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

		// make the print timer
		printTimer = new Timer(config.PRINT_SECONDS * 1000);
		printTimer.addEventListener(TimerEvent.TIMER, allowPrintingAgain);
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
	public function addEntry(_message:String, _submitter:String, _date:String = "", _isTweet:Bool = false):Void
	{
		var msg = 
        {
            message: _message,
            submitter: _submitter,
            submitDate: _date == "" ? Date.now().toString() : _date,
            hasPrinted: false,
            messageType: _isTweet == false ? "website" : "tweet"
        };

        if(_isTweet)
        	msg.submitter = "@" + _submitter;

        // Important: check to see if this message already exists!
        // Probably much better ways to do this stuff. 
        if(!existsInDatabase(msg))
        {
        	log("Adding new message to database: " + msg.message);

    		submitter.submit(msg);
        }
	}


	/**
	 * CHECK IF MESSAGE ALREADY EXISTS
	 * Stops duplicate tweets being pushed into the database
	 */
	public function existsInDatabase(msg:Dynamic):Bool
	{
		try
		{
			var query = db.messages.find( {message: msg.message, submitter: msg.submitter } ).getDocs();

			if(query.length > 0)
				return true;
		}
		catch(err:Dynamic)
		{
			log("ERROR: existsInDatabase() check failed");
			return false;
		}

		return false;
	}


	/**
	 * FIND NEXT UNPRINTED MESSAGES
	 * This method is continually called on a timer
	 */
	private function findNextUnprintedMessage(e:TimerEvent):Void
	{		
		if(ACTIVE)
		{
			try
			{
				var message = db.messages.findOne({hasPrinted:false});
				
				if(message != null)
					printMessage(message);
				else
					log("No messages to print");
			}
			catch(err:Dynamic)
			{
				log("ERROR: findNextUnprintedMessage() call failed: " + err);
			}
		}
	}


	/**
	 * SEND TO PRINTER
	 * Physically prints the message, invalidates it in the DB, and activates the machine!
	 */
	private function printMessage(msg:Dynamic, isTest:Bool = false):Void
	{
		log("------------------------");
		log("Printing new message from " + msg.submitter + "\n" + msg.message);
		log("------------------------");

		if(!isTest)
		{
			try
        	{
    			// Set the entry to printed in the database
				msg.hasPrinted = true;
		        db.messages.update({message:msg.message, submitter:msg.submitter, submitDate:msg.submitDate}, msg);

        		showDBConnection(true);
    		}
    		catch(err:Dynamic)
    		{
    			log("Error contacting database...");
    			showDBConnection(false);
    		}
		}

        // Print the actual card (saves it to a directory
        try
        {
        	Printer.saveToDesktop(msg.message, msg.submitter, msg.submitDate);
        	stopPrintingWhilePrinting();
        }
        catch(err:Dynamic)
        {
        	log("ERROR: saving to desktop failed");
        }
	}


	/**
	 * SUPPRESS PRINTING FOR PRINT PERIOD
	 * Stops the printer printing another message for a short amount of time.
	 * This is to stop tons of messages stacking up and lets us have a faster query.
	 */
	private function stopPrintingWhilePrinting():Void
	{
		log("Print triggered! Waiting until print cycle finishes...");

		ACTIVE = false;
		toggleBtn.gotoAndStop(2);

		printTimer.start();
	}

	private function allowPrintingAgain(e:TimerEvent):Void
	{
		printTimer.stop();

		ACTIVE = true;
		toggleBtn.gotoAndStop(1);

		log("Printing is allowed again.");
	}


	/**
	 * MACHINE TOGGLE
	 * Suppresses printing, used for maintenance
	 */
	private function toggleMachine(e:MouseEvent):Void
	{
		ACTIVE = !ACTIVE;

		if(ACTIVE)
			toggleBtn.gotoAndStop(1);
		else
			toggleBtn.gotoAndStop(2);
	}


	/**
	 * TEST PRINT
	 * Writes a test printout to the machine
	 */
	private function doTestPrint(e:MouseEvent):Void
	{
		if(ACTIVE)
		{
			var msg = 
	        {
	            message: "This is a test message. #cornerhousescribbler.",
	            submitter: "Johnny Tester",
	            submitDate: Date.now(),
	            hasPrinted: false,
	            messageType: "website"
	        };

	        printMessage(msg, true);
		}
		else
		{
			log("Woah there. Something's already printing, hold on.");
		}
	}


	/**
	 * LOGGING
	 */
	public function log(msg:Dynamic):Void
	{
		readout.appendText(msg + "\n");
		readout.scrollV = readout.numLines;
	}

	public function showAppMode(isLive:Bool):Void
	{
		if(isLive)
			appModeMarker.gotoAndStop(2);
		else
			appModeMarker.gotoAndStop(1);
	}

	public function showDBConnection(_isConnected:Bool):Void
	{
		if(_isConnected)
			databaseMarker.gotoAndStop(2);
		else
			databaseMarker.gotoAndStop(1);
	}

	public function showTwitterConnection(_isConnected:Bool):Void
	{
		if(_isConnected)
			twitterMarker.gotoAndStop(2);
		else
			twitterMarker.gotoAndStop(1);
	}


	/**
	 * DIRTY SINGLETON
	 */
	private static var self_reference:App;
	public static function Instance():App { return self_reference; }
}