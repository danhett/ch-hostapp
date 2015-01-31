package;

import openfl.Assets;
import openfl.display.BitmapData;
import openfl.display.Sprite;
import openfl.display.MovieClip;
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
	private var MONGO_URL:String = "ds029821.mongolab.com";
	private var MONGO_PORT:Int = 29821;
	private var LOGIN:String = "danhett";
	private var PASS:String = "ch123";
	private var seconds:Int = 4; // delay for each db query

	private var clip:MovieClip;
	private var mongo:Mongo;
    private var db:Database;
    private var readout:TextField;
    private var nameInput:TextField;
    private var messageInput:TextField;
    private var timer:Timer;

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

		setupDatabase();
	}

	private function setupDatabase():Void
	{
		print("Connecting to database...");

		mongo = new Mongo(MONGO_URL, MONGO_PORT);
        db = mongo.chtest; 
        db.login(LOGIN, PASS); 
        
        print("Found " + db.messages.find().getDocs().length + " messages in the database.");

        /*
        for(message in db.messages.find()) 
        {
            print(message);
        }
        */

        var btn = cast(clip.getChildByName("submitBtn"), MovieClip);
		btn.buttonMode = true;
		btn.addEventListener(MouseEvent.CLICK, submitNewResponse);

		timer = new Timer(seconds * 1000);
		timer.addEventListener(TimerEvent.TIMER, findUnprintedMessages);
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
	            submitDate: '5th January 2015',
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
	private function findUnprintedMessages(e:TimerEvent):Void
	{
		var found:Int = db.messages.find().getDocs().length;

		var randIndex:Int = Math.round(Math.random() * found);
		print("Printing message " + randIndex + " of " + found + ": " + db.messages.find().getDocs()[randIndex].message);

		createSnapshot(db.messages.find().getDocs()[randIndex].message, db.messages.find().getDocs()[randIndex].submitter, randIndex);
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

		// Saving the BitmapData
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