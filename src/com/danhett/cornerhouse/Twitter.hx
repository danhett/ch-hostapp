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

import com.danhett.App;
import StringTools;
import haxe.crypto.Base64;
import openfl.events.Event;
import openfl.events.EventDispatcher;
import openfl.events.HTTPStatusEvent;
import openfl.events.IOErrorEvent;
import openfl.events.TimerEvent;
import openfl.net.URLLoader;
import openfl.net.URLRequest;
import openfl.net.URLRequestMethod;
import openfl.net.URLRequestHeader;
import openfl.utils.Timer;
import haxe.io.Bytes;

class Twitter extends EventDispatcher 
{
	private var key:String;
	private var secret:String;
	private var bearerToken:String;

	private var hashtag:String;
	private var count:Int = 1; // number of tweets per request
	private var seconds:Int;

	private var ld:URLLoader;
	private var req:URLRequest;
	private var timer:Timer;

	private var blacklist:Array<String>;

	public function new() 
	{
		super();

		blacklist = new Array<String>();

		blacklist.push("@CornerhouseMcr");
		blacklist.push("@HOME_mcr");
		blacklist.push("@danhett");
		blacklist.push("@studioaudienced");
		blacklist.push("@rickogden");
		blacklist.push("@cornerhousetest");
	}


	/**
	 * SETUP TWITTER
	 */
	public function setupTwitter(_key:String, _secret:String):Void
	{
		App.Instance().log("Setting up twitter...");

		// get settings from config
		hashtag = App.Instance().config.TWITTER_HASHTAG;
		seconds = App.Instance().config.TWITTER_QUERY_SECONDS;

		// URL-encode the key and secret (shouldn't change, future-proofing in line with twitter's docs)
		key = StringTools.urlEncode(_key);
		secret = StringTools.urlEncode(_secret);

		// Construct a new URL request with the key/secret pair
		var authld:URLLoader = new URLLoader();
		var bytes:Bytes = Bytes.ofString(key + ":" + secret);
		var authHeader:URLRequestHeader = new URLRequestHeader("Authorization", "Basic " + Base64.encode(bytes));
		
		// Create the request
		var authreq:URLRequest = new URLRequest("https://api.twitter.com/oauth2/token");
    	authreq.method = URLRequestMethod.POST;
    	authreq.requestHeaders.push(authHeader);
       	authreq.contentType = "application/x-www-form-urlencoded;charset=UTF-8";
    	authreq.data = "grant_type=client_credentials";

    	// Listen for completion/failure
    	authld.addEventListener(Event.COMPLETE, onComplete);
    	authld.addEventListener(IOErrorEvent.IO_ERROR, onIOError);
    	authld.addEventListener(HTTPStatusEvent.HTTP_STATUS, onHTTPStatusEvent);

    	// Make the request - should return a bunch of JSON containing an access token
    	authld.load(authreq);
	}


	/**
	 * TOKEN ACQUIRED
	 */
	private function onComplete(e:Event):Void
	{
		App.Instance().showTwitterConnection(true);

		bearerToken = haxe.Json.parse(e.target.data).access_token;
		App.Instance().log("Access token recieved. Starting tweet check cycle.");

		setupTweetRequest();
	}


	/**
	 * GET MOST RECENT TWEET
	 */
	private function setupTweetRequest():Void
	{
		ld = new URLLoader();

		req = new URLRequest("https://api.twitter.com/1.1/search/tweets.json" 
											+ "?q=" + hashtag 
											+ "&result_type=recent"
											+ "&count=" + count);
		
		var authHeader:URLRequestHeader = new URLRequestHeader("Authorization", "Bearer " + bearerToken);
    	req.requestHeaders.push(authHeader);

    	ld.addEventListener(Event.COMPLETE, showTweets);
    	ld.addEventListener(IOErrorEvent.IO_ERROR, onIOError);
    	ld.addEventListener(HTTPStatusEvent.HTTP_STATUS, onHTTPStatusEvent);
    	
    	timer = new Timer(seconds * 1000);
		timer.addEventListener(TimerEvent.TIMER, loadNewTweets);
		timer.start();
	}


	/**
	 * LOAD TWEETS
	 */
	private function loadNewTweets(e:TimerEvent):Void
	{
		if(App.Instance().ACTIVE)
			ld.load(req);
	}


	/**
	 * PARSE TWEETS
	 */
	private function showTweets(e:Event):Void
	{
		App.Instance().showTwitterConnection(true);

		var json:Dynamic = haxe.Json.parse(e.target.data);

		if(json.statuses.length >= 1) // guards against weird returns, in case something barfed at the twitter end
		{
			for(i in 0...json.statuses.length)
			{
				var messageText:String = json.statuses[i].text; // TODO - strip the URLs and format correctly
				var messageSubmitter:String = json.statuses[i].user.screen_name;
				var messageDate:String = json.statuses[0].created_at;

				// only submit the message if it didn't come from the cornerhouse or dev team!
				if( isActualMessage(messageSubmitter, messageText) )
				{
					//trace("Adding message from " + messageSubmitter + ": " + messageText);
					App.Instance().addEntry(messageText, messageSubmitter, messageDate, true);
				}
				else
				{
					//trace("Shitlisted tweet from " + messageSubmitter + ": " + messageText);	
					//App.Instance().log("Tweet found from disallowed user: " + messageSubmitter + ". Not submitting."); 
				}
			}
		}
		else
		{
			App.Instance().log("No tweets found for this hashtag! Something probably went wrong...");
		}
	}


	/**
	 * BLACKLIST CHECKING
	 * Ensures the tweet hasn't come from us so we can talk about it on twitter
	 */
	private function isActualMessage(submitterText:String, messageText:String):Bool
	{
		for(s in blacklist)
		{
			// check to see if the person submitting is blacklisted
			if( s.toLowerCase().indexOf( submitterText.toLowerCase() ) != -1  )
				return false;

			// check to see if the message contains a manual retweet specifically
			// this also catches 'normal' retweets as they're formatted identically in the API
			if( messageText.toLowerCase().indexOf("rt "+s.toLowerCase()) != -1)
				return false;
		}

		// if we get here, the message is probably fine!
		return true;
	}


	/**
	 * ERROR HANDLING
	 * Called by token and also tweets API calls
	 */
	private function onIOError(e:IOErrorEvent):Void
	{
		App.Instance().log("Twitter error! Check internet connection.");

		App.Instance().showTwitterConnection(false);
	}


	/**
	 * HTTP STATUS HANDLING
	 * Called by token and also tweets API calls. Here to catch status 0, which means no connection.
	 */
	private function onHTTPStatusEvent(e:HTTPStatusEvent):Void
	{
		if(e.status == 0)
		{
			App.Instance().log("HTTP status was zero. Check internet connection.");
			App.Instance().showTwitterConnection(false);
		}
	}
}




