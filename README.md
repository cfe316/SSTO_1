# Three SSTOs for use with KOS and RemoteTech
Oxcart, Pickup, and U-Haul lift up to 4.5, 9, and 22 tons, resp., without a worry!
These mid-career SSTO craft are programmed for hands-off takeoff from the launchpad to 100km circular orbit, and for also landing near KSC.

![The three SSTO rockets: Oxcart, Pickup, and U-Haul](http://i.imgur.com/5GZjWdr.jpg "The three SSTO rockets: Oxcart, Pickup, and U-Haul")

By using two, four, and eight JX-4 "Whiplash" turbojets as a first stage, rather than R.A.P.I.E.R. engines, they can be used profitably during the middle of your career.

![The three SSTOs in orbit](http://i.imgur.com/toiXWJI.jpg "The three SSTOs in orbit")

The smallest one, Oxcart uses the nuclear engine once oxygen runs out, and the two larger ones use the Poodle and Skipper.

Each sports a Reflectron DP-10 as well as one of the Communotron Omni antennas for communications in-orbit. 

## Installation

In order to use these scripts, put the `source` folder and the `pack.sh` script into your KOS `Script` folder. Run `pack.sh`: 
this remove comments and extra lines from the source files so that the scripts can fit in 10kilocharacters, and places the files
in the `Script` folder so that KOS can see them.

## Launch

To use KOS to launch one of these rockets, run the scripts `launchone.ks` for Oxcart, `launchtwo.ks` for Pickup, or `launchthree.ks` for the U-Haul.
Each of them will load the template file `launchskel.ks` automatically. Your vehicle should reach a circular 100km orbit in a few minutes,
at which point the script will end.

## Landing

Once in orbit, when it's time to land, make sure that the fairing has been jettisoned. 
Run the KOS commands

    delete launchskel.
    copy landingone from archive.
    run landingone.

With `landingone` replaced with `landingtwo` or `landingthree` as appropriate the vehicle, as with launching.

Note that the crafts intentionally tumble when landing: this reduces heat on any one solar panel or antenna.
Landing is accomplished with parachutes, and then using the turbojets to slow the final descent to 4-6 m/s. 
Landing generally takes place a few kilometers west of KSC, but the craft are also rated for splashdown.

![Propulsive landing](http://i.imgur.com/wqx4Rd0.jpg "Propulsive landing")
![Splashdown!](http://i.imgur.com/dDXo3lQ.png "Splashdown!")

Enjoy!
