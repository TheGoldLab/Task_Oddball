%% ODDBALL EXPERIMENT

clear all; clear all; close all;
pathNames2013(); 

%%___________________________________
firstBlock = false;
%___________________________________

% 2 - Load max strength
load('strengthAll.mat');
if size(strengthAll,1) == 1
     strengthSb  = mean(strengthAll(1,:));
else
     strengthSb  = [mean(strengthAll(1,:)), mean(strengthAll(2,:))]; % RH THEN LH
end
load('calibTones.mat');
load('calibFiles.mat');

% 3 - Calibrate eyetracke/stopr
Screen('Preference','SkipSyncTests', 1);
[subID, EDFfilename] = MKEyelinkCalibrate();

% 4 - Call previous parameters of novel sounds
if firstBlock 
    chooseOne = randperm(numel(3:102)); %list of random number
else
    load('whichNovel.mat');
    chooseOne = whichNovel;
end

% 5 - Prepare parameters of experiment
[task, list] = oddballConfig_Patients(1,0,1,strengthSb, chooseOne,subID, calibTones,calibFiles);
% First argument is whether button is pressed for odd frequencies (0) or for
% standard frequencies(1)
% Second argument is whether a strong grip is required to validate the
% motor response:  1= strong grip, 0=light grip.
% Third argument: are novelty sounds included or not?


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
    d1 = list{'Input'}{'Dynamometer'};
    d1.stop; 
    timeseries = d1.get_buffer; % dynamometer data of the whole expe
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
Data.WhichNovel      =  list{'Stimulus'}{'SeriesOfSounds'};

if size(strengthSb,2) == 2
    Data.StimTimeRH_D       = list{'Input'}{'TimestampsStimRH'}; %Time of the stimulus in the dynamometer clock
    Data.StimTimeLH_D       = list{'Input'}{'TimestampsStimLH'}; 
    Data.Corrects           = list{'Input'}{'Corrects'}; %Storing correctness of answers (1= true, 0=false). Initialized to 33 so we know if there was no input during a trial with 33.
    Data.ChoiceResponseRH_D = list{'Input'}{'ResponseRH'}; %Storing subject response timestamp (dynamometer clock)
    Data.ChoiceResponseLH_D = list{'Input'}{'ResponseLH'}; %Storing subject response timestamp (dynamometer clock)
    Data.StrengthResponseRH = list{'Input'}{'MaxRH'};
    Data.StrengthResponseLH = list{'Input'}{'MaxLH'};
    Data.StrengthMaxTimeRH  = list{'Input'}{'TimeMaxRH'};
    Data.StrengthMaxTimeLH  = list{'Input'}{'TimeMaxLH'};
    Data.StrengthOn         = list{'Input'}{'StrengthOn'}; 

    Data.ChoiceResponseRH_E = list{'Eyelink'}{'TimestampsResponsesRH'}; %Storing subject response timestamp (eyelink clock)
    Data.StimTime_E         = list{'Eyelink'}{'TimestampsStim'};  %Store eyelink timestamps (in milliseconds) 
    Data.ChoiceResponseLH_E = list{'Eyelink'}{'TimestampsResponsesLH'}; %Storing subject response timestamp (eyelink clock)

    Data.strengthRH        = strengthSb(1); %Max
    Data.strengthLH        = strengthSb(2);
    Data.strengthAllExpeRH = timeseriesRH; % grips's strength during the whole session
    Data.strengthAllExpeLH = timeseriesLH;
else
    Data.StimTime_D       = list{'Input'}{'TimestampsStim'}; %Time of the stimulus in the dynamometer clock
    Data.Corrects           = list{'Input'}{'Corrects'}; %Storing correctness of answers (1= true, 0=false). Initialized to 33 so we know if there was no input during a trial with 33.
    Data.ChoiceResponse_D = list{'Input'}{'Response'}; %Storing subject response timestamp (dynamometer clock)
    Data.StrengthResponse = list{'Input'}{'Max'};
    Data.StrengthMaxTime  = list{'Input'}{'TimeMax'};
    Data.StrengthOn         = list{'Input'}{'StrengthOn'}; 

    Data.ChoiceResponse_E = list{'Eyelink'}{'TimestampsResponses'}; %Storing subject response timestamp (eyelink clock)
    Data.StimTime_E         = list{'Eyelink'}{'TimestampsStim'};  %Store eyelink timestamps (in milliseconds) 
    Data.strength        = strengthSb; %Max

end
    
Data.LatencyDevice   = list{'Stimulus'}{'AllDevice'}; %Time to call timestamps all devices
Data.StartRing       = list{'Stimulus'}{'Start'}; % Time it takes for stimulus to start after start trial (seconds)
Data.strengthAllExpe = timeseries; % grips's strength during the whole session


% save which novel sounds I played in previous blocks
fr = list{'Stimulus'}{'Playfreqs'};
numNovel = sum(isnan(fr)==1);
whichNovel = list{'Stimulus'}{'SeriesOfSounds'};
whichNovel = whichNovel(numNovel+1:end);
save('whichNovel.mat','whichNovel');

% --> To know if the task required to press the buttons for the oddballs
% (0) or the standard sounds (1) as referred initialy in the call of the 
% dreamOddballConfig_Eyelink function (third argument), refer to these
% arguments in the list: list{'Input'}{'OppositeOn'}.
% Similarly to know if the distractors were on: list{'Distractor'}{'On'}

%% Convert files in mat files

edfdata = edfmex(EDFfilename,'.edf');

%% Saving

save([list{'Subject'}{'Savename'} '_List'  '.mat'],'list')
save([ list{'Subject'}{'Savename'} '_Data' '.mat'], 'Data')
save([ list{'Subject'}{'Savename'}  '_EDF' '.mat'], 'edfdata')



