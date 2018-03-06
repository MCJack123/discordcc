# discordcc
Discord client for ComputerCraft

# How to use
* Download both files to the computer, and make sure `discordapi` is in the root folder. Then launch `discordcc`.  
* You will be asked for your email and password for your Discord account. If you have logged in before and used `/quit` to save your session, you will not need to log in again.
* From there, a list of the servers you are joined to will appear, and you can type a number to select it. Then you can choose the channel the same way.  
* The most recent messages will be printed and a prompt will appear, where you can type the messages. The messages refresh every second, so you don't have to quit to see the messages. To select a new server, type `/server`. To quit, you can use `/logout` to logout and delete your saved token or `/quit` to quit without deleting the session.  
* To read all messages in a list, type `/read`. The 50 most recent messages (more soon) will be displayed in a viewer with syntax like `less`. You can scroll up and down with the arrow keys and quit with the "Q" key. To see more help, press "H".

# Note about security
* The password is hidden and directly read into the login command (see `discordcc.lua` on line 34), where it is only sent to the Discord API in a POST request (see `discordapi` on line 780 and 618).  
* When you log in, your session token will be saved as `dstk` to the current directory. This is to allow session saving. In the future, the token will be saved only when using `/quit` and may be encrypted. If you do not want this feature, comment out line 42 in `discordcc.lua`.

# Credits
* The Discord API wrapper was originally written by videah and I have adapted it to work in ComputerCraft. The code has been combined into `discordapi` to allow easier usage by ComputerCraft. You can see the repository [here](https://github.com/videah/discord.lua).
