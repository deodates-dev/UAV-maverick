## Installation
There are two ways to get started with Maverick:  
[Download OS Images](#os-Images)  (Much faster!)  
  *_or_*  
[Bootstrap Maverick](#bootstrap-Maverick)  (More fun!)

---

### OS Images

Initial images are available for the following platforms.  Volunteers to produce images for other platforms welcome :)

- [Raspberry Pi (All models)](http://www.maverick.one/downloads/maverick-1.1.1-raspberry.img.xz)
- [Intel Joule (ISO)](http://www.maverick.one/downloads/maverick-1.1.1-joule.iso)
- [Intel Joule (tar)](http://www.maverick.one/downloads/maverick-1.1.1-joule.tar)
- [Ubuntu Dev VM (ova)](http://www.maverick.one/downloads/maverick-1.1.1-ubuntuvm.ova)
- [Odroid XU3/XU4](http://www.maverick.one/downloads/maverick-1.0.4-odroidxu4.img.xz)

These initial images require an 8Gb or larger SD card.

The easiest way to write the images to SD card is using the excellent [Etcher](https://etcher.io/)

#### Joule Instructions
Joule 570 has a fast 16Gb onboard eMMC storage.  The Joule 550 only has 8Gb onboard storage and should work but has not been tested, and will have little space free after flashing.  Further efficiencies will be made in the future to leave more space.  Flashing onboard MMC is more tricky than booting from an SD card, so this platform uses a Clonezilla flashing mechanism.
- Write the ISO file to an SD card (like the one that comes with the Joule), or write the tar file to a USB stick, and boot from it.  Follow the default prompts and it should flash Maverick to the onboard eMMC drive.
- Reboot, take the SD card out and boot to the newly flashed OS
- Login as 'mav' user (default password is 'wingman')
- Run 'wifi-setup' to setup wireless networking so you can connect to it, as there is no onboard ethernet
- Reboot again to activate the new network settings
- [Get Started](#get-Started)

####  Raspberry/Odroid Instructions
Getting Maverick working on the Raspberry or Odroid is straight forward.
- Write the image files to SD card (no need to uncompress if you use [Etcher](https://etcher.io/))
- Boot from the SD card
- (Optionally) Run 'wifi-setup' to setup wireless networking
- [Get Started](#get-Started)

#### Get Started
If the installation and network setup was successful, you should now be able to connect over ssh:  
Joule: `ssh maverick-joule.local`  
Raspberry: `ssh maverick-raspberry.local`  
Odroid: `ssh maverick-odroidxu4.local`  
Ubuntu VM: `ssh maverick-ubuntuvm.local`  

You can also connect to the Web interface from any web browser:  
Joule: http://maverick-joule.local/  
Raspberry: http://maverick-raspberry.local/  
Odroid: http://maverick-odroidxu4.local/  
Ubuntu VM: http://maverick-ubuntuvm.local/  

The Web IDE that is available as a link from the web interface has a browser based SSH client which is open at the bottom of the window by default and logged in to the mav user, and is a very convenient tool for quick command line access.

?> **Note: The username is 'mav' and the default password is 'wingman' for both ssh and web access.**

After logging in, it's strongly recommended to firstly update and configure Maverick, in particular this will expand the root filesystem to fill the SD card you are using:
```bash
sudo apt update
maverick self-update
maverick configure
sudo reboot
```
When you reboot, it will resize the partitions and filesystems for you.

See what Maverick services are running:  
`maverick status`

The OS images are distributed with the dev environment active at boot.  This contains a lot of dev services that should be turned in flight mode, or on particularly slow/low power computers.  To turn the dev services off, change to the flight environment:  
`maverick --env=flight configure`

See more things you can do with the `maverick` command:  
[maverick Usage](#usage)

---

### Bootstrap Maverick

!> Warning: This can take a LONG time depending on the hardware and speed of internet connection.  A full development install on a slow computer like a Raspberry Pi can take over 12 hours.  A full development install on a faster computer like an Intel Joule will typically take 1-2 hours.

- Maverick can be run from any new or existing OS installation.
- The provided OS images are simply a fresh vendor OS with Maverick run and are provided for convenience, as initial Maverick runs can take a long time due to compiling and installing lots of software.
- Once the initial Maverick run is complete, the system should be in exactly the same state as if installed from OS image.

First update the OS, download Maverick and do a bootstrap run and reboot:
```bash
$ sudo apt-get update && sudo apt-get -y upgrade
sudo apt-get install -y git && git clone https://github.com/fnoop/maverick.git --depth 1
cd maverick && sudo ./bin/maverick --env=bootstrap configure
sudo reboot
```
Next, login as the 'mav' user (default password is 'wingman') and run Maverick with an end-state environment:  
For flight/production environment: `maverick --env=flight configure`  
Or for development environment: `maverick --env=dev configure`

Maverick will then calculate what needs to be done on the system and perform the changes, based on the configuration and underlying code.  This process can take a long time - between 1 and 24 hours depending on the speed of the hardware and network.  It provides output as it goes along but when doing large components (like compiling a large piece of software) it can appear to pause for a while.
______

## Usage
Maverick has a single main command: `maverick`.  It takes one mandatory argument which is a command.  If you run it without an argument, it will display a (hopefully) helpful usage screen.

### Self Update
self-update command updates Maverick itself.  If new features, bugfixes etc have been developed then this downloads the new code from github and self updates.  Note in order to take advantage of the new code, `maverick configure` must be run.  
`maverick self-update`

### Configure
The main action of maverick is to apply the combination of code and configuration to the system, mainly through the Configuration Management system (Puppet).  Initial runs can take hours to complete as it compiles code, applies configuration, sets up services etc.  Subsequent runs can take as little as a minute to complete if there are no or only very small updates to apply.  Even if there are no apparent updates, every time Maverick is run it scans the entire system to ensure it complies with the state described in the code and given configuration.  
`maverick configure`

There are three optional parameters for configure:
- --dryrun: this shows what changes would be applied to the system without actually applying them
- --env: this changes the system to a new environment.  Currently defined environments are _bootstrap_, _flight_ or _dev_.
- --module: this restricts the configure to a single module, any other changes will be ignored.  Modules are as named in ~/software/maverick/manifests/maverick-modules: *maverick_network*, *maverick_fc*, *maverick_vision* etc, eg.:  

`maverick configure --dryrun --env=dev --module=maverick_vision`

### Status/Info
Maverick gives some useful info/status:
- Status of running Maverick services:  
`maverick status`
- System info:  
`maverick info`
- Network info:  
`maverick netinfo`

### Start/Stop/Restart
Maverick services (lefthand most column in `maverick status` output) can be easily started and stopped.  Note that Maverick services are implemented using systemd services with a 'maverick-' prefix, so the 'visiond' Maverick service is equivalent to 'maverick-visiond' systemd service (eg. `sudo systemctl status maverick-visiond`):
- Start service  
`maverick start <service>`
eg.
```bash
maverick status
maverick start mavros@sitl
maverick status
```
- Stop service  
`maverick stop <service>`
eg.
```bash
maverick status
maverick start visiond
maverick status
```
- Restart service is a convenience shortcut to stop and start a service:  
`maverick restart visiond`

### Log
While a lot of service output is logged to /srv/maverick/var/log, as the services are controlled through systemd some output is (only) available from the system journal.  Maverick provides a shortcut to view the latest live output for a service journal (equivalent to `sudo journalctl -u maverick-<service>`):  
`maverick log <service>`  
 eg.  
`maverick log mavproxy@fc`

### Enable/Disable
As well as starting and stopping services, Maverick can also set the services state at boot, which is called enabling and disabling as with systemd.  The difference between start and enable is that start starts the service immediately, whereas enable does not start the service immediately, but marks it to be started at boot time.  Most Maverick services are configured to start and enable, or stop and disable.  
`maverick enable visiond`  
 or
`maverick disable visiond`  

---

## Layout and Config

### Layout
Maverick has a simple layout and is consistent across all platforms.  As part of the bootstrap, Maverick creates a 'mav' OS user which all services run under, and almost everything under Maverick control lives in the mav user home directory - /srv/maverick.  The exceptions to this are various config and manifests that need to live within OS system paths, for example /etc/systemd for service manifests and /etc/profile.d for various environment variables.  

Within /srv/maverick (the home directory for mav user), there are four main areas:
 - code : all coding, from ardupilot to dronecode to python to sample code
 - data : contains maverick and app config, app data, video output etc
 - software : all compiled and installed maverick software components, including maverick itself
 - var : all temporary or runtime files, logs, build areas

** Note: The '~' in Linux means the current user home directory, so ~/ in the Maverick 'mav' user is /srv/maverick/ **

These areas are designed so that the ~/code and ~/data directories will contain files that you will want to backup.  The ~/software directory and all the components within are installed as part of maverick install, do not need to be backed up and should not be altered.  The ~/var directory does not need to be backed up and contains temporary files created by various software components or running processes.

### Maverick Config
There are numerous methods of changing maverick config, and the config itself is extensive and complex.  The underlying mechanisms and various config options are explored further in [About](/about#about-maverick) and [Modules](/modules/intro).  However, to get started a single config file can be used: **~/data/config/maverick/localconf.json**.

#### localconf.json
This file can be used to set any parameter within the Maverick manifests.  It contains some basic sample config entries to get you started, but any class::parameter setting can be used here.  This file is 'frozen' from git and can never be committed back, so is a good place to put settings like passwords and wifi access details.  A helper utility 'wifi-setup' will help you setup wifi settings within localconf.json more easily.  If any settings are changed, added or removed in localconf.json, `maverick configure` needs to be run to activate these changes.

#### Maverick code branch
The `maverick self-update` command updates the Maverick software itself from github, which is the primary mechanism for updating Maverick.  By default it updates from the 'stable' branch, which contains the latest code that has had at least some testing and review.  The config file *~/data/config/maverick-branch.conf* contains the github branch that Maverick will use to update.  Simply change this from 'stable' to 'master' and run `maverick self-update` to switch to the latest development code.  Unless you want to test changes to Maverick under development, it is strongly recommended to leave this as stable.

### App Config

#### Controlled config
'Controlled config' is where the config for an app or component is controlled by Maverick.  The config is controlled by changing/adding/deleting parameters in localconf.json and running `maverick configure`.  Maverick then calculates the influence of the parameters and generates the config.  It is important to note that in most cases if the generated config is changed manually it will be overwritten by Maverick the next time a configure run is performed.

Why have Controlled Config?  In some circumstances, the config for an app or component can be quite complex and difficult to setup, or once set is unlikely to be changed much.  Maverick tries to automate as much as possible for the end user and automating configuration is part of this process.  In addition, controlling config through localconf parameters allows the possibility of complete automation for building or cloning companion computers, all with consistent and repeatable settings.

#### Uncontrolled config
Uncontrolled config are traditional config files for apps or components that are not controlled by Maverick and can be altered by traditional editing.  In most cases default config files are provided by Maverick into ~/data/config, from which point on they are left for the end user to change as they wish.  This makes more sense where the user will want to quickly and easily alter settings, for example camera resolution.

All config settings are described in details in the [Modules](/modules/intro) documentation.
