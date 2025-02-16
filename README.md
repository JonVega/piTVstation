# piTVstation

Turn your Raspberry Pi 4, that uses a composite cable, into a retro tv station that plays random episodes forever. Commercials can also be added during commercial breaks or just after an episode finishes.

I'm currently working on setting up this up to be more streamlined and user friendly. But until then, you can start having fun and relive the era of television before video streaming.

So far, I only tested this with a Raspberry Pi 4 using a composite cable, but I'll give an update on other models and computers.

## Getting your piTVstation up and running

Alrighty then, let's start getting your piTVstation setup and ready for use!

*if you know how to image a Raspberry Pi micro SD card and access the Pi using SFTP and SSH, then download [this image (Official Raspberry Pi Link)](https://downloads.raspberrypi.com/raspios_lite_armhf/images/raspios_lite_armhf-2024-11-19/2024-11-19-raspios-bookworm-armhf-lite.img.xz) and skip to `Configuring the SD card for first boot`*

### Imaging the Micro SD card

1. First download the [Raspberry Pi Imager](https://www.raspberrypi.com/software/) if you haven't already
2. Then download the [Raspberry Pi Lite x64 Image (Official Link)](https://downloads.raspberrypi.com/raspios_lite_armhf/images/raspios_lite_armhf-2024-11-19/2024-11-19-raspios-bookworm-armhf-lite.img.xz) (`2024-11-19-raspios-bookworm-armhf-lite.img.xz`)
3. Insert the Micro SD card you want to format and open the Raspberry Pi Imager. Note that everything on the SD card will be deleted, so make sure that you're alright with that
4. Ignore the first box and click the second box labeled `Choose OS`
5. Scroll all the way down to `Use custom` and click that
6. Select the file you downloaded from step 2
7. Lastly, click the third box `Choose Storage` and **carefully** select your Micro SD card you inserted
8. Click `Next`
9. A box should pop up, click the box labeled `Edit Settings`
10. Go ahead and set your `hostname` to whatever you desire (if using multiple Raspberry Pis, have them be different names), set your `username and password`, and set your `wireless LAN` so we can add videos to the Pi
11. At the top you should a tab called `Services`, click that and `enable SSH` then select `Use password authentication`
12. Next, At the top again, click `options` then make sure `Eject media when finished` is **unchecked** and go ahead and uncheck `Enable telemetry` if you want.
12. Lastly, at the bottom click `Save` and click the box that says `Yes`, then `Yes` one more time. It shouldn't take too long, but when it's done, ignore the message saying that it's ok to remove. Yay! Part 1 is done!

### Configuring the SD card for first boot

#### Composite Cable

Before we insert the Micro SD card into the Raspberry Pi 4, we have do a few things so that it works on older TVs using RCA composite cables.

Mac - On the Desktop, you should see an image of a SD card called `bootfs` click that
PC - Go to your File Explorer and you should see a drive called `bootfs` click that

1. Open the file called `config.txt` using a text editor (or Notepad / TextEdit)
2. Where is says `dtoverlay=vc4-kms-v3d`, change that line to be `dtoverlay=vc4-kms-v3d,composite` (basically add `,composite` to that line). Then save and close your text editor.
3. Now open the file called `cmdline.txt` using a text editor
4. Find where it says `quiet` and before that insert either:
	+ `video=Composite-1:720x480@60ie` for NTSC
	+ `video=Composite-1:720x576@50ie` for PAL
5. It should look something like this: `rootwait video=Composite-1:720x480@60ie quiet`. You want it in between `rootwait` and `quiet`
6. Now we can insert the Micro SD card into the Raspberry Pi! Part 2 is done!

### Setting up the operating system

1. Go ahead and power on the Pi with the SD card inserted. It will show a black screen for awhile, but eventually you'll see a prompt to login

*You can use a USB keyboard to continue following the steps below, but I recommend remotely logging in with your computer using SSH if you know how to do that since it might be a little hard to see using composite cables*

Mac - On the top right click the magnifying glass and type `Terminal` and hit the Enter Key. Then `ssh YOUR_USER_NAME@PI_IP_ADDRESS`, you can see your Pi's IP Address on the TV screen. For example mine would be `ssh jonathan@192.168.0.6`

2. If you haven't already, go ahead and login.
3. Now that we're in the Pi, let's get a few programs that are needed and have piTVstation installed.
4. Type `mkdir -p ~/piTVstation/{scripts,videos,commercials}`
5. Type `sudo apt update`
6. Now lets download `vlc` and `mediainfo`. Type `sudo apt install vlc mediainfo` and hit enter. That will download two programs that are currently needed to get the piTVstation running.
7. Once that's done, we need to get the piTVstation script.
8. This command is pretty long, but please type `wget -P ~/piTVstation/scripts https://github.com/JonVega/piTVstation/archive/refs/tags/v.25.2.0.zip`
9. Then type `unzip -j ~/piTVstation/scripts/v.25.2.0.zip -d ~/piTVstation/scripts/`
10. Then lastly, type `sudo chmod 755 ~/piTVstation/scripts/{createStopmarks.sh,piTVstation.sh}`
11. We now have the scripts needed to run piTVstation, so next let's add videos to the Pi! Part 3 is done!

### Adding videos

1. Videos are added to the folder called `videos` in the `piTVstation` folder. You can use the `scp` command to transfer them to your Pi or an application like WinSCP on Windows or Fetch on Mac.
2. If you like using the terminal then type something like this to transfer a directory of videos `scp VIDEO.mp4 PI_USERNAME@PI_IP_ADDRESS:~/piTVstation/videos`. Mine would be like `scp ~/Downloads/videos/* jonathan@192.168.0.6:~/piTVstation/videos`, this example transfers all my video files from a folder called `videos` in my `Downloads` folder on my Mac to the piTVstation's video folder.

### Adding commercials

1. Adding commercials is just like adding videos, but instead of `~/piTVstation/videos` it's `~/piTVstation/commercials`. An example would be `scp ~/Downloads/commercials/* jonathan@192.168.0.6:~/piTVstation/commercials`, this example transfers all my commercial video files from a folder called `commercials` in my `Downloads` folder on my Mac to the piTVstation's commercial folder.

### Configuring piTVstation

1. Let's set the Pi to automatically start the piTVstation when powered on, go ahead and type this `sudo nano /etc/systemd/system/piTVstation.service`
2. Then paste this (or type it out if using a keyboard):

```text
[Unit]
Description=Runs piTVStation script forever
After=multi-user.target

[Service]
Type=simple
Restart=on-failure
User=jonathan
ExecStart=/home/jonathan/piTVstation/scripts/piTVstation.sh

[Install]
WantedBy=multi-user.target
```

3. Now where it says `User=jonathan`, replace `jonathan` with your Pi's username
4. And where it says `ExecStart=/home/jonathan/piTVstation/scripts/piTVstation.sh`, change the `jonathan` part to your Pi's username
5. Press `Control + O`, then hit the Enter key, then `Control + X` to quit
6. Then back at the terminal, type `sudo chmod 644 /etc/systemd/system/piTVstation.service`
7. Then type `sudo systemctl daemon-reload`
8. Then `sudo systemctl enable piTVstation.service`
9. Lastly, let's restart the Pi by typing `sudo shutdown -r now`

### What now?

## Considerations down the line

+ SAMBA server on boot to add videos wirelessly, versus using SFTP to transfer files
+ Using a USB device to watch video from instead of just a Micro SD card
+ Making a pre-configured image to make installation a breeze, or just making setup process faster and easier

## Random tidbits

+ `vlc` is used because it supports hardware acceleration versus other video players that use software. Raspberry Pi 4 has hardware acceleration for H264 and H265 (HEVC).