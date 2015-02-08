package com.danhett.cornerhouse;

import com.danhett.App;
import openfl.events.EventDispatcher;

class Machine extends EventDispatcher 
{
	public function new() 
	{
		super();
	}

	public static function activate():Void
	{
		App.Instance().log("Activating the machine!");
	}
}