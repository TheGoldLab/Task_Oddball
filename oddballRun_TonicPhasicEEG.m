

%% ODDBALL EXPERIMENT

clear all, clear all, close all;
pathNames();

% Prepare EEG
 % Info related to EEG
MetaDataOddball();
 % Visualize EEG streaming
visualizeEEG();
 % Load library EEG & markers outlet
lib = lsl_loadlib();
infoMkr = lsl_streaminfo(lib,'MyMarkerStream','Markers',1,0,'cf_string','myuniquesourceid23443');
outletMkr = lsl_outlet(infoMkr,0,1);

% 1 - Load max strength
load('strengthAll.mat'); % RH THEN LH 
load('calibTones.mat');
load('calibFiles.mat');
strengthSb  = [mean(strengthAll(1,:)), mean(strengthAll(2,:))]; 

% 2- Assign thresholds
prompt = 'Is it the first session? [Y/N]';
resp   = input(prompt,'s');
if strcmp(resp,'y') || strcmp(resp,'Y')
    valuesThreshold = [5 10 15 20 25 30];
    vals = valuesThreshold([randperm(2,1),randperm(2,1)+2,randperm(2,1)+4]);
else
    prompt = 'What are the thresholds of the tonic condition? ';
    vals = input(prompt);
end

% 3 - Calibrate eyetracke/stopr
Screen('Preference','SkipSyncTests', 0);
[subID, EDFfilename] = MKEyelinkCalibrate();

% 4 - Prepare parameters of experiment
[task, list] = oddballConfig_TonicPhasic(0, subID, vals, ...
    strengthSb, calibTones,calibFiles,outletMkr);
% First argument is whether button is pressed for odd frequencies (0) or for
% standard frequencies(1)

%% Open and close window experiment
dotsTheScreen.openWindow();
task.run
dotsTheScreen.closeWindow();


%% Close dynamometer
if size(strengthSb,2) == 2
    d1 = list{'Input'}{'DynamometerRH'};
    d2 = list{'Input'}{'DynamometerLH'};
    d1.stop; d2.stop;
    timeseriesRH = d1.get_buffer; % dynamometer data of the whole expe
    timeseriesLH = d2.get_buffer; 
    d1.close; d2.close;
else
    d1 = list{'Input'}{'DynamometerRH'};
    d1.stop; 
    timeseriesRH = d1.get_buffer; % dynamometer data of the whole expe
    d1.close; 
end
       
clear d*


%% Saving Eyelink Data File
%Close file, stop recording
    Eyelink('StopRecording');
    Eyelink('Command','set_idle_mode');
    WaitSecs(0.5);
    Priority();
    Eyelink('CloseFile');

    try
        fprintf('Receiving data file ''%s''\n', EDFfilename );
        status=Eyelink('ReceiveFile', EDFfilename);
        if status > 0
            fprintf('ReceiveFile status %d\n', status);
        end
        if 2==exist(EDFfilename, 'file')
            fprintf('Data file ''%s'' can be found in ''%s''\n', EDFfilename, pwd );
        end
    catch rdf
        fprintf('Problem receiving data file ''%s''\n', EDFfilename );
        rdf;
    end


%% Post-Processing

Data.StandardFreq    = list{'Stimulus'}{'StandardFreq'};
Data.OddFreq         = list{'Stimulus'}{'OddFreq'};
Data.ProbDeviant     = list{'Stimulus'}{'ProbabilityDeviant'};
Data.StimFrequencies = list{'Stimulus'}{'Playfreqs'};% Store whether the trial triggered a standard sound or an oddball
Data.TimeStimStarts  = list{'Stimulus'}{'Start'}; % (in sd) how long it takes for the stimulus to start after beginning of trial

Data.StimTimeRH_D       = list{'Input'}{'TimestampsStimRH'}; %Time of the stimulus in the dynamometer clock
Data.StimTimeLH_D       = list{'Input'}{'TimestampsStimLH'};
Data.Corrects           = list{'Input'}{'Corrects'}; %Storing correctness of answers (1= true, 0=false). Initialized to 33 so we know if there was no input during a trial with 33.
Data.ChoiceResponseRH_D = list{'Input'}{'ResponseRH'}; %Storing subject response timestamp (dynamometer clock)
Data.StrengthResponseRH = list{'Input'}{'MaxRH'};
Data.StrengthMaxTimeRH  = list{'Input'}{'TimeMaxRH'};
Data.Blocks             = list{'Input'}{'Block'};
Data.PercStrengthRH     = list{'Input'}{'Condition'};

Data.ChoiceResponseRH_E = list{'Eyelink'}{'TimestampsResponsesRH'}; %Storing subject response timestamp (eyelink clock)
Data.StimTime_E         = list{'Eyelink'}{'TimestampsStim'};  %Store eyelink timestamps (in milliseconds) 

Data.LatencyDevice = list{'Stimulus'}{'AllDevice'}; %Time to call timestamps all devices
Data.StartRing     = list{'Stimulus'}{'Start'}; % Time it takes for stimulus to start after start trial (seconds)

Data.strengthRH        = strengthSb(1); %Max
Data.strengthLH        = strengthSb(2);
Data.strengthAllExpeRH = timeseriesRH; % grips's strength during the whole session
Data.strengthAllExpeLH = timeseriesLH;
Data.ThresLH           = vals;

%% Convert files in mat files
edfdata = edfmex(EDFfilename,'.edf');

%% Saving

save([list{'Subject'}{'Savename'} '_List'],'list')
save([ list{'Subject'}{'Savename'} '_Data' '.mat'], 'Data')
save([ list{'Subject'}{'Savename'}  '_EDF' '.mat'], 'edfdata')

Eyelink('Shutdown');
