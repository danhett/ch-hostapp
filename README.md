# Cornerhouse Scribbler
# Host Application
The root monitoring application for the Scribbler installation project, created for Cornerhouse Manchester.

This application continually monitors both a mongoDB database and a twitter hashtag, to pull down new messages for print. Once  printed, the messages are invalidated to prevent repeat prints. Messages are then written to a directory on the host machine, which is monitored by a system process so they can be printed, and lights/motors activate.

Requires Haxe/OpenFL, uses Matt Tuttle’s MonogoDB have wrapper (https://github.com/MattTuttle/mongo-haxe-driver)
