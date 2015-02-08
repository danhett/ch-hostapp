package com.danhett.cornerhouse;

import com.danhett.App;
import StringTools;
import haxe.crypto.Base64;
import openfl.events.Event;
import openfl.events.EventDispatcher;
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
	private var searchCount:Int = 10;

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

    	// Make the request - should return a bunch of JSON containing an access token
    	ld.load(req);
	}


	/**
	 * TOKEN ACQUIRED
	 */
	private function onComplete(e:Event):Void
	{
		bearerToken = haxe.Json.parse(e.target.data).access_token;
		App.Instance().log("Token: " + bearerToken);

		getTweetList();
	}


	/**
	 * GET MOST RECENT TWEET
	 */
	private function getTweetList():Void
	{
		var ld:URLLoader = new URLLoader();
		var variables = new URLVariables();

		var req:URLRequest = new URLRequest("https://api.twitter.com/1.1/search/tweets.json?q=%40cornerhouse&result_type=recent&count=1");
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
		var json = haxe.Json.parse(e.target.data);
		var messageText:String = json.statuses[0].text;
		var messageSubmitter:String = json.statuses[0].user.screen_name;

        App.Instance().addEntry(messageText, messageSubmitter, true);
	}
}




