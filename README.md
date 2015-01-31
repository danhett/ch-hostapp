# leaveamessage
The host application for our installation project for Cornerhouse Manchester.

This application continually monitors both a mongoDB database and a twitter hashtag, to pull down new messages for print. Once  printed, the messages are invalidated to prevent repeat prints.

Requires Haxe/OpenFL, uses Matt Tuttle’s MonogoDB have wrapper (https://github.com/MattTuttle/mongo-haxe-driver)