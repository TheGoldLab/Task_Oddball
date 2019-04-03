# Oddball

__________________________________________________________
Steps to follow to make the EEG system work with Matlab:
__________________________________________________________

1 - Plug the EEG Dongle first (in the first USB port from the left), and then turn the board on (a blue light should be seen in 
both the dongle and the board). If you do this opposite it's not going to work!

2 - Install the plugin in terminal : 

    sudo -H pip install -r requirements.txt

    cd /Users/joshuagold/Psychophysics/Projects/EEG_projects/OpenBCI_Python

    python user.py -p=/dev/tty.usbserial-DQ007NVN --add streamer_lsl

    To start streaming: /start
    To stop streaming: /stop
    To disconnect from serial port: /exit


3 -  In Matlab

Be sure to add the paths: labstreaminglayer

--> addpath(genpath('/Users/joshuagold/Psychophysics/Projects/python_projects/labstreaminglayer-master'))

To visualize streaming
Vis_stream()
Info to add in the window:
10
5
150
1:9
250
10
[4 5 50 60]

To start streaming:
Select Online Analysis > Read input from… > Lab streaming layer…

	•	To load an .xdf file, type in the command line:
streams = load_xdf('your_file_name.xdf')


Useful command line:
open -a Finder /nameFolder
