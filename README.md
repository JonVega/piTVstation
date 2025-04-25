# piTVstation

Relive the era of television before video streaming! Turn your Raspberry Pi 4, that uses a composite cable, into a retro tv station that plays random episodes forever using VLC. Commercials can also be added during commercial breaks or just after an episode finishes.

So far, I only tested this with a Raspberry Pi 4 using a composite cable, but I'll give an update on other models and computers.

## Getting Your piTVstation Up And Running

Alrighty then, let's start getting your piTVstation setup and ready for use!

### Imaging The Micro SD card - Part 1

1. First download the [Raspberry Pi Imager](https://www.raspberrypi.com/software/) if you haven't already
2. Then download the [Raspberry Pi Lite Image (Official Link)](https://downloads.raspberrypi.com/raspios_lite_armhf/images/raspios_lite_armhf-2024-11-19/2024-11-19-raspios-bookworm-armhf-lite.img.xz).
3. Insert the Micro SD card you want to format and open the Raspberry Pi Imager. Note that everything on the SD card will be deleted, so make sure that you're alright with that.
4. Ignore the first box and click the second box labeled `Choose OS`
5. Scroll all the way down to `Use custom` and click that
6. Select the file you downloaded from step 2
7. Lastly, click the third box `Choose Storage` and **carefully** select your Micro SD card you inserted
8. Click `Next`
9. A box should pop up, click the box labeled `Edit Settings`
10. Go ahead and set your `hostname` to whatever you desire (if using multiple Raspberry Pis, have them be different names), set your `username and password`, and set your `wireless LAN` so we can add videos to the Pi
11. If you are going to use a USB keyboard to finish setting up the Pi, then skip this step. Else, at the top you should see a tab called `Services`, click that and `enable SSH` then select `Use password authentication`.
12. Next, at the top again, click `options` then make sure `Eject media when finished` is **unchecked** and go ahead and uncheck `Enable telemetry` if you want.
13. Lastly, at the bottom click `Save` and click the box that says `Yes`, then `Yes` one more time. It shouldn't take too long, but when it's done, ignore the message saying that it's ok to remove. Yay! Part 1 is done!

### Configuring The SD Card For First Boot - Part 2

#### Using Composite

Before we insert the Micro SD card into the Raspberry Pi 4, we have do a few things so that it works on older TVs using an RCA composite cable.

+ Mac - *On the Desktop, you should see an image of a SD card called `bootfs` click that*
+ PC - *Go to your File Explorer and you should see a drive called `bootfs` click that*

1. Open the file called `config.txt` using a text editor (or Notepad / TextEdit)
2. Where is says `dtoverlay=vc4-kms-v3d`, change that line to be `dtoverlay=vc4-kms-v3d,composite` (basically add `,composite` to that line). Then save and close your text editor.
3. Now open the file called `cmdline.txt` using a text editor
4. Find where it says `quiet` and before that insert either:
	+ `video=Composite-1:720x480@60ie` for NTSC
	+ `video=Composite-1:720x576@50ie` for PAL
5. It should look something like this: `rootwait video=Composite-1:720x480@60ie quiet`. You want it in between `rootwait` and `quiet`
6. Now we can insert the Micro SD card into the Raspberry Pi! Part 2 is done!

#### Using HDMI

**STILL NEED TO TEST**

### Setting Up The Operating System - Part 3

1. Go ahead and power on the Pi with the SD card inserted. It will show a black screen for awhile, but eventually you'll see a prompt to login. It might restart again when your see the login screen, just wait bit to be sure.

*You can use a USB keyboard to continue following the steps below, but I recommend remotely logging in with your computer using SSH if you know how to do that since it might be a little hard to see using composite cables*

+ *Mac - On the top right click the magnifying glass and type `Terminal` and hit the Enter Key. Then `ssh YOUR_USER_NAME@PI_IP_ADDRESS`, you can see your Pi's IP Address on the TV screen. For example mine would be `ssh jonathan@192.168.0.6`*

2. If you haven't already, go ahead and login using your keyboard or through SSH.
3. Now that we're in the Pi, just run this command to begin the installation process: 'curl -sL https://github.com/JonVega/piTVstation/releases/download/v.25.3.0/install.sh | bash'
4. Once installation is completed, the Pi will restart and you will be greeted with a test pattern. That's our cue to start adding videos to piTVstation. Part 3 is done!

### Adding Videos - Part 4

1. piTVstation should now be available in the Network section on Mac and Windows.
2. Go ahead and connect to your piTVstation using your Pi's user name for both the User Name and Password.
3. Navigate to the `piTVstation --> videos` folder and begin copying your videos in this folder. **Note: You cannot add folders in the `video` folder, just only video files should be here!**

**If you do not want to have commercials playing, then you are done! Go ahead and eject, on macOS at least, piTVstation from the network. A random video should now be playing, and whenever you want to add more videos, go ahead and connect to the piTVstation and drop some more videos. When an episode is finished, it will automatically add your new videos for random playback. Have Fun!**

### Adding Commercials - Part 5

1. Adding commercials is just like adding videos
2. Navigate to the `piTVstation --> commercials` folder and begin copying your commercials in that folder. **Note: You cannot add folders in the `commercial` folder, just only video files should be here!**
3. Once you've added your commercials, you can now, on macOS at least, eject the piTVstation

#### What now?

So... commercials. 

By default, the piTVstation plays 3 commercials, but this can be changed. Navigate to the `scripts` folder in the `piTVstation` folder and open the file `piTVstation.sh` using a text editor. Where it says `amount_commercials=3`, change the number to as many commercials you would like and save and quit your text editor.

**But what about during playback?** You know, when an episode fades to black for a commercial break. Then you'll have to add stopmarks yourself manually. Tedious, I know, but it does help with videos that have commercials already in them or episodes that lack commercials. By adding stopmarks manually, we can ignore those commercials and resume playback or add commercials in ourselves.

In the piTVstation's video folder, you'll notice that `.txt` files were created for every video file. Like so:

```text
'The Critic s01e04.mp4'
'The Critic s01e04.txt'
```

If you look in the `.txt` file for an episode, you'll see it has a number, like:

```text
1360
```

That's the **stopmark in seconds**. You can go ahead and alter it like so:

```text
497
831
1360
```

Now when an episode reaches that mark, it will play `X` amount of commercials then resume playback. If you have the stopmarks set and later decide you're not feeling the commercials, go ahead and set `amount_commercials`, see above, to zero. You can always come change it later.

Once you have taken the time to add a bunch of stopmarks for your videos, just restart the Pi and a backup will automatically be created in the `backups` folder as a zip file.

## Some Considerations Down The Line

+ Using a USB device to watch videos from instead of just a Micro SD card
+ Import videos using USB instead of WiFi
+ Have it play selected Holiday videos during a given timeframe (I'll call this feature *The Scheduler*)
+ Change the currently playing video using a remote control or a button using GPIO
+ Is it possible to swap directories to simulate channels using just one Raspberry Pi?

## Random Tidbits

+ You could use a bunch of Pis running piTVstation to simulate channels. For example, one Pi could be *90's animation* and another could be *1950's TV*, then use a device like the ChannelPlus 3025 to map each Pi to a selected channel on your TV.
+ `vlc` is used because it supports hardware acceleration versus other video players that use software. Raspberry Pi 4 has hardware acceleration for H264 and H265 (HEVC).