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
import openfl.net.URLLoader;
import openfl.net.URLRequest;
import openfl.net.URLRequestMethod;
import openfl.net.URLVariables;
import openfl.net.URLRequestHeader;
import haxe.io.Bytes;

class Twitter extends EventDispatcher 
{
	private var key:String;
	private var secret:String;
	private var bearerToken:String;

	private var hashtag:String = "cornerhouse";
	private var count:Int = 10;

	public function new() 
	{
		super();
	}


	/**
	 * SETUP TWITTER
	 */
	public function setupTwitter(_key:String, _secret:String):Void
	{
		App.Instance().log("Setting up twitter...");

		// URL-encode the key and secret (shouldn't change, future-proofing in line with twitter's docs)
		key = StringTools.urlEncode(_key);
		secret = StringTools.urlEncode(_secret);

		// Construct a new URL request with the key/secret pair
		var ld:URLLoader = new URLLoader();
		var variables = new URLVariables();
		var bytes:Bytes = Bytes.ofString(key + ":" + secret);
		var authHeader:URLRequestHeader = new URLRequestHeader("Authorization", "Basic " + Base64.encode(bytes));
		
		// Create the request
		var req:URLRequest = new URLRequest("https://api.twitter.com/oauth2/token");
    	req.method = URLRequestMethod.POST;
    	req.requestHeaders.push(authHeader);
       	req.contentType = "application/x-www-form-urlencoded;charset=UTF-8";
    	req.data = "grant_type=client_credentials";

    	// Listen for completion/failure
    	ld.addEventListener(Event.COMPLETE, onComplete);
    	ld.addEventListener(IOErrorEvent.IO_ERROR, onIOError);
    	ld.addEventListener(HTTPStatusEvent.HTTP_STATUS, onHTTPStatusEvent);

    	// Make the request - should return a bunch of JSON containing an access token
    	ld.load(req);
	}


	/**
	 * TOKEN ACQUIRED
	 */
	private function onComplete(e:Event):Void
	{
		bearerToken = haxe.Json.parse(e.target.data).access_token;
		App.Instance().log("Access token recieved. Starting tweet check cycle.");


		getTweetList();
	}


	/**
	 * GET MOST RECENT TWEET
	 */
	private function getTweetList():Void
	{
		var ld:URLLoader = new URLLoader();
		var variables = new URLVariables();

		var req:URLRequest = new URLRequest("https://api.twitter.com/1.1/search/tweets.json?q=%40" 
											+ hashtag 
											+ "&result_type=recent&count="
											+ count);
		var authHeader:URLRequestHeader = new URLRequestHeader("Authorization", "Bearer " + bearerToken);
    	req.requestHeaders.push(authHeader);

    	// TODO - add handling for bad HTTP statuses and whatever else
    	ld.addEventListener(Event.COMPLETE, showTweets);
    	
    	ld.load(req);
	}


	/**
	 * PARSE TWEETS
	 */
	private function showTweets(e:Event):Void
	{
		var json:Dynamic = haxe.Json.parse(e.target.data);

		if(json.statuses.length >= 1) // guards against weird returns, in case something barfed at the twitter end
		{
			for(i in 0...json.statuses.length)
			{
				var messageText:String = json.statuses[i].text; // TODO - strip the URLs and format correctly
				var messageSubmitter:String = json.statuses[i].user.screen_name;

		        App.Instance().addEntry(messageText, messageSubmitter, true);
			}
		}
		else
		{
			App.Instance().log("No tweets found for this hashtag! Something probably went wrong...");
		}
	}


	/**
	 * ERROR HANDLING
	 * Called by token and also tweets API calls
	 */
	private function onIOError(e:IOErrorEvent):Void
	{
		App.Instance().log("Twitter error! Check internet connection.");
	}


	/**
	 * HTTP STATUS HANDLING
	 * Called by token and also tweets API calls. Here to catch status 0, which means no connection.
	 */
	private function onHTTPStatusEvent(e:HTTPStatusEvent):Void
	{
		if(e.status == 0)
			App.Instance().log("HTTP status was zero. Check internet connection.");
	}
}




