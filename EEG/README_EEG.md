# Oddball Phasic Tonic EEG


Lab streaming layer (LSL) : system for synchronizing streaming data for real-time streaming, recording, and analysis of biodata. The openbci_pylsl program uses Python to establish an LSL stream that can be received using scripts in Matlab. 

LabRecorder : application from LSL that we use here to save the EEG streaming (and the timestamps of each event in the task). It creates an XDF file that you can later convert to a mat file.

More Info here:

https://github.com/OpenBCI/OpenBCI_MATLAB

https://openbci.com/index.php/forum/

__________________________________________________________
## Steps to follow to use the EEG system during the experiment:
__________________________________________________________

__1 -__ Plug the EEG Dongle first (in the first USB port from the left), and then turn the board on (a blue light should be seen in 
both the dongle and the board). If you do the opposite it's not going to work!

__2 -__Install the plugin in the terminal : 

    cd /Users/joshuagold/Psychophysics/Downloaded/OpenBCI_Python 

    If not already done: sudo -H pip install -r requirements.txt

    python user.py -p=/dev/tty.usbserial-DQ007NVN --add streamer_lsl

    To start streaming: /start
    To stop streaming: /stop
    To disconnect from serial port: /exit


__3 -__  In Matlab

Be sure to add the paths of the folder 'labstreaminglayer' (should be in the script 'pathNames.m')

--> addpath(genpath('/Users/joshuagold/Psychophysics/Downloaded/labstreaminglayer-master'))

__4 -__ Run script 'oddballRun_TonicPhasicEEG.m'

	When it is in pause, open LabRecorder. Should be found here:

	/Users/joshuagold/Psychophysics/Downloaded/labstreaminglayer-master/build/lsl_Release/lslinstall/LabRecorder 
	
	In the window LabRecorder, check all boxes, give a name to the new file and click save
	
	!!!! If Matlab crashes, run the sript 'visualizeEEG.m' in a parallel Matlab!!!!!


__5 -__ When the task is over

	- Stop the saving in the LabRecorder
	- enter /stop
		/exit
		in terminal (to stop the streaming)

_______________________
What's in the XDF file?
_______________________

In the xdf file (EEG data), you will find the timestamps under the name 'xdfdata{1, 1}.time_stamps' and the events it refers to under the name 'xdfdata{1, 1}.time_series'. 'Stim' refers to the beginning of the trial, 'Squeeze' refers to the beginning of the dominant hand response.


