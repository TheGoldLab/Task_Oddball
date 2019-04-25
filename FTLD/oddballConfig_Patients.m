% ODDBALL TASK. VERSION: novel oddball task with dynamometors + eyelink + EEG
%__________________________________________________________________________________

function [maintask, list] = oddballConfig_Patients(opposite_input_on, strength_on, novelty_on, strength, nbHand, chooseOne, subID, calibTones,calibFiles)
%% Housekeeping
%Setting up the screen
sc=dotsTheScreen.theObject;
sc.reset('displayIndex', 2); %change display index to 0 for debug (small screen). 1 for full screen. Use >1 for external monitors.

%% Setting up a list structure
list = topsGroupedList;

%Feedback on? 0 for no, 1 for yes
feedback_on = 1;

list{'Input'}{'OppositeOn'} = opposite_input_on;
list{'Input'}{'Novelty'} = novelty_on; 
list{'Input'}{'StrengthOn'} = strength_on;

trials = 3;%160;%160;%160; %160 %trial number
interval = 1; %Fixation interval required by eyelink
standardf = 1000; %standard frequency; 500
oddf = 2000; %2000; %oddball frequency: 700
p_deviant = 0.3; %probability of oddball freq

list{'Stimulus'}{'StandardFreq'} = standardf;
list{'Stimulus'}{'OddFreq'} = oddf;
list{'Stimulus'}{'ProbabilityDeviant'} = p_deviant;

if nbHand == 2
    twoHands=true;
    list{'Input'}{'twoHands'} = 1;
else
    twoHands=false;
    list{'Input'}{'twoHands'} = 0;
end
    
%Subject ID
subj_id = subID;
list{'Subject'}{'ID'} = subj_id;
startsave(list);

%Sound player
    player = dotsPlayableNote();
    player.duration = 0.5; %sound duration in seconds
    player.ampenv = tukeywin(player.sampleFrequency*player.duration)';
    
    fileSound = dotsPlayableFile(); 
    pathFile = fullfile(pwd,'/wav');
    d = dir(pathFile);
    
    list{'Stimulus'}{'Player'} = player;
    list{'Stimulus'}{'Novelty'} = fileSound;
    list{'Stimulus'}{'NoveltySounds'}  = {d.name};
    list{'Stimulus'}{'SeriesOfSounds'} = chooseOne;

%INPUT PARAMETERS
    reactionwindow = 2; 
    list{'Input'}{'ReactionWindow'} = reactionwindow;
    
% EYELINK  
    list{'Eyelink'}{'SamplingFreq'} = 1000; %Before 1000!!Check actual device sampling frequency in later version
    list{'Eyelink'}{'Fixtime'} = interval;
    screensize = get(0, 'MonitorPositions');
    screensize = screensize(2, [3, 4]); %matlab2016
    screensize = [2560        1440];% screen on right; screensize(1, [3, 4]);
    centers = screensize/2;
    list{'Eyelink'}{'Centers'} = centers;
    list{'Eyelink'}{'Invalid'} = -32768;
    
    %Setting windows for fixation:
    window_width = 0.3*screensize(1);
    window_height = 0.3*screensize(2);
    
    xbounds = [centers(1) - window_width/2, centers(1) + window_width/2];
    ybounds = [centers(2) - window_height/2, centers(2) + window_height/2];
    
    list{'Eyelink'}{'XBounds'} = xbounds;
    list{'Eyelink'}{'YBounds'} = ybounds;
    
%Data Storage
list{'Stimulus'}{'Counter'} = 0;
list{'Stimulus'}{'Playfreqs'} = zeros(1,trials); %Store frequencies played
list{'Stimulus'}{'Start'} = zeros(1,trials); % time of sound stmulus after trial start
list{'Stimulus'}{'AllDevice'} = zeros(1,trials); % time to call all timestamps
list{'Stimulus'}{'NbNovel'} = 0;
list{'Stimulus'}{'Tones'} =  calibTones;
list{'Stimulus'}{'Files'} =  calibFiles;

if twoHands
    list{'Eyelink'}{'TimestampsResponsesRH'} = zeros(1,trials); 
    list{'Eyelink'}{'TimestampsResponsesLH'} = zeros(1,trials);
else
    list{'Eyelink'}{'TimestampsResponses'} = zeros(1,trials);
end

list{'Eyelink'}{'TimestampsStim'} = zeros(1,trials); % time of the beginning of the trial (not of the sound) 

if twoHands
    list{'Input'}{'TimestampsStimLH'} = zeros(1,trials);
    list{'Input'}{'TimestampsStimRH'} = zeros(1,trials); % time of the stimulus in the dynamometer clock
    list{'Input'}{'MaxRH'} = -1 * ones(1,trials); % strength associated to the trial response with the dynamometer
    list{'Input'}{'MaxLH'} = -1 * ones(1,trials); 
    list{'Input'}{'TimeMaxRH'} = zeros(1,trials); % time response of the dynamometer (in second)
    list{'Input'}{'TimeMaxLH'} = zeros(1,trials);
    list{'Input'}{'ResponseRH'} = zeros(1,trials);
    list{'Input'}{'ResponseLH'} = zeros(1,trials);
else
    list{'Input'}{'TimestampsStim'} = zeros(1,trials);   
    list{'Input'}{'Max'} = -1 * ones(1,trials); % strength associated to the trial response with the dynamometer
    list{'Input'}{'TimeMax'} = zeros(1,trials); % time response of the dynamometer (in second)
    list{'Input'}{'Response'} = zeros(1,trials);
end

list{'Input'}{'Choices'} = zeros(1,trials); % Storing whether subject squeezed the dynamometer
list{'Input'}{'Corrects'} = ones(1,trials)*-33; % Storing correctness of answers. Initialized to 33 so we know if there was no input during a trial with 33.

list{'Delay'}{'PlayCheck'} =  zeros(1,trials); 

%% Input: SET UP HAND DYNAMOMETER
disp('Loading library DYN...');
% create dynamometer object

if twoHands
    dRH=dynamometer(1);
    dRH.start;
    timeToD_RH  = GetSecs;

    dLH=dynamometer(2);
    dLH.start;
    timeToD_LH = GetSecs;
       
    list{'Input'}{'DynamometerRH'} = dRH;
    list{'Input'}{'DynamometerLH'} = dLH; 
    list{'Input'}{'DynamometerStartRH'} = timeToD_RH; 
    list{'Input'}{'DynamometerStartLH'} = timeToD_LH; 
else
    d=dynamometer;
    d.start;
    timeToD = GetSecs;
    list{'Input'}{'Dynamometer'} = d;
    list{'Input'}{'DynamometerStart'} = timeToD; 
end
    
list{'Input'}{'minStrength'} = 10;

%% Graphics:
% Create some drawable objects. Configure them with the constants above.

list{'graphics'}{'gray'} =  [0.65 0.65 0.65];
list{'graphics'}{'fixation diameter'} = 0.4;

    % instruction messages
    m = dotsDrawableText();
    m.color = list{'graphics'}{'gray'};
    m.fontSize = 48;
    m.x = 0;
    m.y = 0;

    % texture -- due to Kamesh
    isoColor1 = [30 30 30];
    isoColor2 = [40 40 40];
    checkerH = 10;
    checkerW = 10;

    checkTexture1 = dotsDrawableTextures();
    checkTexture1.textureMakerFevalable = {@kameshTextureMaker,...
    checkerH,checkerW,[],[],isoColor1,isoColor2};
    
    % replacing fixation point with fixation cross
    fp = dotsDrawableText();
    fp.isVisible = true;
    fp.color = list{'graphics'}{'gray'};
    fp.typefaceName = 'Calibri';
    fp.fontSize = 68;% was 68;
    fp.isBold = 0;
    fp.string = '+';
    fp.x = 0;
    fp.y = 0;
    
    %--> When the subject makes an error the + become a x on the next trial
    
    %Text prompts
    readyprompt = dotsDrawableText();
    readyprompt.string = 'Ready?';
    readyprompt.fontSize = 42;
    readyprompt.typefaceName = 'Calibri';
    readyprompt.isVisible = false; 
    
    buttonprompt = dotsDrawableText();
    buttonprompt.string = 'press the A button to get started';
    buttonprompt.fontSize = 24;
    buttonprompt.typefaceName = 'Calibri';
    buttonprompt.y = -2;
    buttonprompt.isVisible = false;

    %Graphical ensemble
    ensemble = dotsEnsembleUtilities.makeEnsemble('Fixation Point', false);
    texture = ensemble.addObject(checkTexture1);
    ready = ensemble.addObject(readyprompt);
    button = ensemble.addObject(buttonprompt);
    dot = ensemble.addObject(fp);
    
    list{'Graphics'}{'Ensemble'} = ensemble;
    list{'Graphics'}{'Dot Index'} = dot;
    
    % tell the ensembles how to draw a frame of graphics
    %   the static drawFrame() takes a cell array of objects
    ensemble.automateObjectMethod(...
    'draw', @dotsDrawable.drawFrame, {}, [], true);

%SCREEN

    % also put dotsTheScreen into its own ensemble
    screen = dotsEnsembleUtilities.makeEnsemble('screen', false);
    screen.addObject(dotsTheScreen.theObject());

    % automate the task of flipping screen buffers
    screen.automateObjectMethod('flip', @nextFrame);
      

%% Runnables

%Setting various anonymous functions based on exp. conditions

checkfunc = @(x) checkinput(x); 
stimulusfunc = @(x) playstim(x); 

if feedback_on
    spin = @(index) ensemble.setObjectProperty('rotation', 45, index);
    despin = @(index) ensemble.setObjectProperty('rotation', 0, index);
else
    spin = @(index) ensemble.setObjectProperty('rotation', 0, index);
    despin = @(index) ensemble.setObjectProperty('rotation', 0, index);
end

%STATE MACHINE
Machine = topsStateMachine();
stimList = {'name', 'entry', 'input', 'exit', 'timeout', 'next';
                 'Start', {despin dot}, {}, {}, 0, 'CheckReady';
                 'CheckReady', {}, {}, {@checkReady list}, 0, 'Stimulus';
                 'Stimulus', {stimulusfunc list}, {}, {}, 0, 'CheckFix';
                 'CheckFix', {@checkFixation list}, {}, {}, 0, 'Feedback';
                 'Feedback', {}, {checkfunc list}, {}, 0, '';
                 'Correct', {despin dot}, {}, {}, 0, '';
                 'Incorrect', {spin dot}, {}, {}, 0.200, ''};
           
Machine.addMultipleStates(stimList);

contask = topsConcurrentComposite();
contask.addChild(ensemble);
contask.addChild(Machine);

maintask = topsTreeNode();
maintask.iterations = trials;
maintask.addChild(contask);
end

%% Accessory Functions

function string = checkinput(list)

    %import important list objects
    counter        = list{'Stimulus'}{'Counter'};
    twoHands       = list{'Input'}{'twoHands'};
    if twoHands == 1
        trialS_RH      = list{'Input'}{'TrialStrengthRH'}; 
        trialS_LH      = list{'Input'}{'TrialStrengthLH'};
        trialS_timeRH  = list{'Input'}{'TrialTimeRH'};
        trialS_timeLH  = list{'Input'}{'TrialTimeLH'};
    else
        trialS      = list{'Input'}{'TrialStrength'}; 
        trialS_time = list{'Input'}{'TrialTime'};
    end
    startMove      = list{'Input'}{'minStrength'}; 

    %To check correct
    opposite_input_on = list{'Input'}{'OppositeOn'};
    freqlist = list{'Stimulus'}{'Playfreqs'};
    oddf = list{'Stimulus'}{'OddFreq'};
    standardf = list{'Stimulus'}{'StandardFreq'};
     
    % by default
    correct = 0; 
   
    % Max grip strength during trial
    if twoHands == 1
        [maxTrialRH, idxRH] = max(trialS_RH);
        [maxTrialLH, idxLH] = max(trialS_LH);
        timeMaxRH = trialS_timeRH(idxRH);
        timeMaxLH = trialS_timeLH(idxLH);
    else
        [maxTrial, idx] = max(trialS);
        timeMax = trialS_time(idx);
    end
    
    % Check if trial is correct
    if opposite_input_on == 1
        checkfreq = standardf; 
    else
        checkfreq = oddf;
    end
    
    if twoHands ==1
        if freqlist(counter)== checkfreq && maxTrialRH >= startMove && maxTrialLH >= startMove
            correct = 1;
        elseif freqlist(counter)~= checkfreq && maxTrialRH < startMove && maxTrialLH < startMove
            correct = 1;
        end
    else
        if freqlist(counter)== checkfreq && maxTrial >= startMove 
            correct = 1;
        elseif freqlist(counter)~= checkfreq && maxTrial < startMove 
            correct = 1;
        end
    end
   
    
    if correct == 1
        string = 'Correct';
    else
        string = 'Incorrect';
    end
            
    % Max grip
    if twoHands == 1
        valMaxRH = list{'Input'}{'MaxRH'};
        valMaxRH(counter) = maxTrialRH;
        list{'Input'}{'MaxRH'} = valMaxRH;
        valMaxLH = list{'Input'}{'MaxLH'};
        valMaxLH(counter) = maxTrialLH;
        list{'Input'}{'MaxLH'} = valMaxLH;

        disp(['strength RH: ',int2str(maxTrialRH)]);
        disp(['strength LH: ',int2str(maxTrialLH)]);

        % Time max grip
        valMaxRH = list{'Input'}{'TimeMaxRH'};
        valMaxRH(counter) = timeMaxRH;
        list{'Input'}{'TimeMaxRH'} = valMaxRH;
        valMaxLH = list{'Input'}{'TimeMaxLH'};
        valMaxLH(counter) = timeMaxLH;
        list{'Input'}{'TimeMaxLH'} = valMaxLH;
    else
        valMax = list{'Input'}{'Max'};
        valMax(counter) = maxTrial;
        list{'Input'}{'Max'} = valMax;
      
        disp(['strength : ',int2str(maxTrial)]);

        % Time max grip
        valMax = list{'Input'}{'TimeMax'};
        valMax(counter) = timeMax;
        list{'Input'}{'TimeMax'} = valMax;
    end

    %Storing user input 
    corrects = list{'Input'}{'Corrects'};
    corrects(counter) = correct;
    list{'Input'}{'Corrects'} = corrects;
    
    %check delay btw end reaction window and end trial
    valDelay = list{'Delay'}{'PlayCheck'};
    valDelay(counter) = toc;
    list{'Delay'}{'PlayCheck'} = valDelay;
    
end



function playstim(list)

    %Adding current iteration to counter
    counter = list{'Stimulus'}{'Counter'};
    counter = counter + 1;
    list{'Stimulus'}{'Counter'} = counter;
    disp(['trial: ',int2str(counter)]);
   
    %importing important list objects
    twoHands  = list{'Input'}{'twoHands'};
    player    = list{'Stimulus'}{'Player'};
    standardf = list{'Stimulus'}{'StandardFreq'};
    oddf      = list{'Stimulus'}{'OddFreq'};
    reactionwindow = list{'Input'}{'ReactionWindow'};
    
    if twoHands == 1
        dRH = list{'Input'}{'DynamometerRH'};
        dLH = list{'Input'}{'DynamometerLH'};
        startExpeRH  = list{'Input'}{'DynamometerStartRH'};
        startExpeLH  = list{'Input'}{'DynamometerStartLH'};
    else
        d = list{'Input'}{'Dynamometer'};
        startExpe  = list{'Input'}{'DynamometerStart'};
    end
        
    startMove = list{'Input'}{'minStrength'}; 
    fileSound = list{'Stimulus'}{'Novelty'};
    p_deviant  = list{'Stimulus'}{'ProbabilityDeviant'};
    novelty_on = list{'Input'}{'Novelty'};
    sounds     = list{'Stimulus'}{'NoveltySounds'};
    chooseOne  = list{'Stimulus'}{'SeriesOfSounds'};
    calibTones  = list{'Stimulus'}{'Tones'};
    calibFiles  = list{'Stimulus'}{'Files'};
    prev        = list{'Stimulus'}{'Playfreqs'};
    if counter >1
        prevTrial  =  prev(counter-1);
    end
    
    %Dice roll to decide if odd, standard or novelty if apply
    playerNovelty = false;
    if counter >1 && prevTrial == oddf || counter >1 && isnan(prevTrial) == 1
        % so that the first trial of each block is not an oddball and that
        % there are not 2 oddballs in a row
        frequency = standardf;
        player.frequency = frequency;
    else
        rollDev = rand;
        frequency(rollDev >  p_deviant) = standardf;
        frequency(rollDev <= p_deviant) = oddf;
        player.frequency = frequency;
        if rollDev <= p_deviant && novelty_on == 1
            rollNovel = rand;
            if rollNovel > 0.7
                %Adding current iteration of novel trial
                nbNovel = list{'Stimulus'}{'NbNovel'};
                nbNovel =  nbNovel + 1;
                list{'Stimulus'}{'NbNovel'} = nbNovel;
                playerNovelty = true;
                frequency = NaN;
                nameSound = sounds{chooseOne(nbNovel)+2};  
                freq = calibFiles.calibratedVoltagesMean(chooseOne(nbNovel));
                fileSound.intensity = freq;
                fileSound.fileName = nameSound;
            end
        end
    end
    
   if playerNovelty
       fileSound.prepareToPlay;
           %Prepping player and playing
           tic
           timeDyn   = GetSecs;
           newsample = Eyelink('NewestFloatSample');
           timeAf =toc;
       fileSound.play;
   else
       if frequency == standardf
           freq = calibTones.calibratedVoltagesMean(1);
       else
           freq = calibTones.calibratedVoltagesMean(2);
       end
       player.intensity = freq;
       player.prepareToPlay;
           %Prepping player and playing
           tic
           timeDyn   = GetSecs;
           newsample = Eyelink('NewestFloatSample');
           timeAf =toc;
       player.play;
   end

    %____________________________________________________________________
    % STIMULUS STARTS
    %--------------------------------------------------------------------
    afStim = GetSecs;
    stimTime = afStim-timeDyn; %assess how long it takes for the stim to be played
    
    %read the dynamometer in the reaction time window
    tic
    switch twoHands
        case 1 % Two hands------------------------------------------------
            pressRH = false; pressLH = false;
            i=1;
            while toc < reactionwindow - stimTime
                % read the dyn
                trialS_RH(i) = dRH.read;
                tpsRH(i) = GetSecs;
                trialS_LH(i) = dLH.read;
                tpsLH(i) = GetSecs;
                % check for movement
                if trialS_RH(i)> startMove && pressRH == 0
                    sampleRH = Eyelink('NewestFloatSample');
                    timeDynMovRH = tpsRH(i);
                    pressRH = true;
                else if trialS_LH(i)> startMove && pressLH == 0
                    sampleLH = Eyelink('NewestFloatSample');
                    timeDynMovLH = tpsLH(i);
                    pressLH = true;
                    end
                end
                i=i+1;
            end
        
        case 0 % One hand------------------------------------------------
            press = false;
            i=1;
            while toc < reactionwindow - stimTime
                % read the dyn
                trialS(i) = d.read;
                tps(i)    = GetSecs;
                % check for movement
                if trialS(i)> startMove && press == 0
                    sample = Eyelink('NewestFloatSample');
                    timeDynMov = tps(i);
                    press = true;
                end
                i=i+1;
            end
    end
  
    tic %check how long it takes to go to checkInput
    
    % TIMESTAMPS STIM
    % Eye tracker 
    eyetime = list{'Eyelink'}{'TimestampsStim'}; 
    eyetime (counter)= newsample.time;
    list{'Eyelink'}{'TimestampsStim'} = eyetime; % in msc

    if twoHands == 1
        % Dynamometer RH
        playtimesRH = list{'Input'}{'TimestampsStimRH'};
        playtimesRH(counter) = timeDyn - startExpeRH;
        list{'Input'}{'TimestampsStimRH'}= playtimesRH;

        % Dynamometer LH
        playtimesLH = list{'Input'}{'TimestampsStimLH'};
        playtimesLH(counter) = timeDyn - startExpeLH;
        list{'Input'}{'TimestampsStimLH'} = playtimesLH;
  
        %TIMESTAMPS START MOVEMENT
        if pressRH && pressLH
            % Eye tracker
            eyetimeDynRH = list{'Eyelink'}{'TimestampsResponsesRH'}; 
            eyetimeDynRH (counter)= sampleRH.time;
            list{'Eyelink'}{'TimestampsResponsesRH'}  = eyetimeDynRH; % in msc
            eyetimeDynLH = list{'Eyelink'}{'TimestampsResponsesLH'}; 
            eyetimeDynLH (counter)= sampleLH.time;
            list{'Eyelink'}{'TimestampsResponsesLH'}  = eyetimeDynLH; % in msc

            % Dynamometer
            timeDynamometerRH = list{'Input'}{'ResponseRH'};
            timeDynamometerRH(counter) = timeDynMovRH - startExpeRH;
            list{'Input'}{'ResponseRH'} = timeDynamometerRH;
            timeDynamometerLH = list{'Input'}{'ResponseLH'};
            timeDynamometerLH(counter) = timeDynMovLH - startExpeLH;
            list{'Input'}{'ResponseLH'} = timeDynamometerLH;
        end
    
        % Store pressure history on each trial
        list{'Input'}{'TrialStrengthRH'}= trialS_RH; 
        list{'Input'}{'TrialStrengthLH'}= trialS_LH;

        % Timestamp of the dynamometer for the first two seconds
        list{'Input'}{'TrialTimeRH'} = tpsRH;
        list{'Input'}{'TrialTimeLH'} = tpsLH;
    
    else % ONE HAND
        % Dynamometer 
        playtimes = list{'Input'}{'TimestampsStim'};
        playtimes(counter) = timeDyn - startExpe;
        list{'Input'}{'TimestampsStim'}= playtimes;
  
        %TIMESTAMPS START MOVEMENT
        if press
            % Eye tracker
            eyetimeDyn = list{'Eyelink'}{'TimestampsResponses'}; 
            eyetimeDyn (counter)= sample.time;
            list{'Eyelink'}{'TimestampsResponses'}  = eyetimeDyn; % in msc
           
            % Dynamometer
            timeDynamometer = list{'Input'}{'Response'};
            timeDynamometer(counter) = timeDynMov - startExpe;
            list{'Input'}{'Response'} = timeDynamometer; 
        end
    
        % Store pressure history on each trial
        list{'Input'}{'TrialStrength'}= trialS; 

        % Timestamp of the dynamometer for the first two seconds
        list{'Input'}{'TrialTime'} = tps;
    end
    
    % how long does the stimulus take to ring
    stimTps = list{'Stimulus'}{'Start'};
    stimTps(counter) = stimTime;
    list{'Stimulus'}{'Start'}= stimTps;
    
    % How long to get all timestamps
    stimAll = list{'Stimulus'}{'AllDevice'};
    stimAll(counter) = timeAf;
    list{'Stimulus'}{'AllDevice'}= stimAll;
    
    % Save frequency
    playfreqs = list{'Stimulus'}{'Playfreqs'};
    playfreqs(counter) = frequency;
    list{'Stimulus'}{'Playfreqs'} = playfreqs;
    
    disp(['type: ',int2str(frequency)]);
    
end

function checkFixation(list)
    %disp('Checking Fix')
    %Import values
    fixtime = list{'Eyelink'}{'Fixtime'};
    fs = list{'Eyelink'}{'SamplingFreq'};
    invalid = list{'Eyelink'}{'Invalid'};
    xbounds = list{'Eyelink'}{'XBounds'};
    ybounds = list{'Eyelink'}{'YBounds'};
    
    fixms = fixtime*fs; %Getting number of fixated milliseconds needed
    
    %Initializing the structure that temporarily holds eyelink sample data
    eyestruct = Eyelink( 'NewestFloatSample');
    
    fixed = 0;
    while fixed == 0
        %Ensuring eyestruct does not get prohibitively large. 
        %After 30 seconds it will clear and restart. This may cause longer
        %than normal fixation time required in the case that a subject
        %begins fixating close to this 30 second mark. 
        if length(eyestruct) > 30000
            eyestruct = Eyelink( 'NewestFloatSample');
        end
        
        %Adding new samples to eyestruct
        newsample = Eyelink( 'NewestFloatSample');
        if newsample.time ~= eyestruct(end).time %Making sure we don't get redundant samples
            eyestruct(end+1) = newsample;
        end

        
        whicheye = ~(eyestruct(end).gx == invalid); %logical index of correct eye
        
        if sum(whicheye) < 1
            whicheye = 1:2 < 2; %Defaults to collecting from left eye if both have bad data
        end
        
        xcell = {eyestruct.gx};
        ycell = {eyestruct.gy};
        
        time = [eyestruct.time];
        xgaze = cellfun(@(x) x(whicheye), xcell);
        ygaze = cellfun(@(x) x(whicheye), ycell);
        
        %cleaning up signal to let us tolerate blinks
        if any(xgaze > 0) && any(ygaze > 0)
            xgaze(xgaze < 0) = [];
            ygaze(ygaze < 0) = [];
            time(xgaze < 0) = []; %Applying same deletion to time vector
        end
        
        %Program cannot collect data as fast as Eyelink provides, so it's
        %necessary to check times for samples to get a good approximation
        %for how long a subject is fixating
        endtime = time(end);
        start_idx = find((time <= endtime - fixms), 1, 'last');
        
        if ~isempty(start_idx)
            lengthreq = length(start_idx:length(xgaze));
        else
            lengthreq = Inf;
        end
        
        if length(xgaze) >= lengthreq;
            if all(xgaze(start_idx :end)  >= xbounds(1) & ... 
                    xgaze(start_idx :end) <= xbounds(2)) && ...
                    all(ygaze(start_idx :end) >= ybounds(1) & ...
                    ygaze(start_idx :end) <= ybounds(2))
                
                fixed = 1;
                eyestruct = [];
            end
        end
        
    end
    
    %disp('Fixated')
    
end

function checkReady(list)
    if list{'Stimulus'}{'Counter'} < 1
        checkFixation(list);
    else
        return
    end
end



function startsave(list)
    %creates a viable savename for use outside of function, to save file
    ID = list{'Subject'}{'ID'};
    appendno = 0;
    savename = [ID num2str(appendno) '_Oddball'];
    
    %Checking if file already exists, if so, changes savename by appending
    %a number
    while exist([savename '.mat'])
        appendno = appendno + 1;
        savename = [ID num2str(appendno) '_Oddball'];
    end
    
    list{'Subject'}{'Savename'} = savename;
end