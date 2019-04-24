
%% ODDBALL EXPERIMENT

clear all, clear all, close all;
pathNames();

% 1 - Load max strength
load('strengthAll.mat'); % RH THEN LH 
load('calibTones.mat');
load('calibFiles.mat');
strengthSb  = [mean(strengthAll(1,:)), mean(strengthAll(2,:))]; 

% 2- Assign thresholds
    valuesThreshold = [5 10 15 20 25 30];
    vals = valuesThreshold([randperm(2,1),randperm(2,1)+2,randperm(2,1)+4]);


% 4 - Prepare parameters of experiment
[task, list] = oddballConfig_TonicPhasic_PRETEST(0, vals, ...
    'test', strengthSb, calibTones,calibFiles);
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


Eyelink('Shutdown');
