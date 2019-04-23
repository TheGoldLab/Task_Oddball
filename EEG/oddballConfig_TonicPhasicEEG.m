% ODDBALL TASK. VERSION: oddball task with dynamometors + eyelink.
% Effect of the tonic level is tested in this version (non dominant hand squeezes the
% dynamometor through the whole session while the dominant hand responds to the stimuli)
% Here are tested different threshold of tonic level: from 5% to 30% of the
% maximal strength.
%__________________________________________________________________________________

function [maintask, list] = oddballConfig_TonicPhasicEEG(opposite_input_on, subID, values, strength,calibTones,calibFiles, outlet)
%% Housekeeping
%Setting up the screen
sc=dotsTheScreen.theObject;
sc.reset('displayIndex',2); %change display index to 0 for debug (small screen). 1 for full screen. Use >1 for external monitors.

%% Setting up a list structure
list = topsGroupedList;

%Feedback on? 0 for no, 1 for yes
feedback_on = 1;

list{'Input'}{'OppositeOn'} = opposite_input_on;
list{'Input'}{'Condition'}= 'Medium strength'; % 1= large strength, 2=lighter grip.

nbCond = 3;
trials = 5;%710;
%120 trials per condition (med low med high and high): 360 + 350 baseline trials 
nbTen = ceil(trials/(nbCond*20));
interval = 1; %Fixation interval required by eyelink
standardf = 1000; 
oddf = 2000; 
p_deviant = 0.30; %probability of oddball freq

list{'Stimulus'}{'StandardFreq'} = standardf;
list{'Stimulus'}{'OddFreq'} = oddf;
list{'Stimulus'}{'ProbabilityDeviant'} = p_deviant;
list{'EEG'}{'Outlet'} = outlet;

%Subject ID
subj_id = subID;
list{'Subject'}{'ID'} = subj_id;
startsave(list);

%Sound player
    player = dotsPlayableNote();
    player.duration = 0.5; %sound duration in seconds
    player.ampenv = tukeywin(player.sampleFrequency*player.duration)';
    list{'Stimulus'}{'Player'} = player;

%INPUT PARAMETERS
    reactionwindow = 2; %time of the trial
    list{'Input'}{'ReactionWindow'} = reactionwindow;
    
% EYELINK  
    list{'Eyelink'}{'SamplingFreq'} = 1000; 
    list{'Eyelink'}{'Fixtime'} = interval;
    screensize = get(0, 'MonitorPositions');
    screensize = screensize(1, [3, 4]); % normally 2
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
list{'Stimulus'}{'Tones'} =  calibTones;
list{'Stimulus'}{'Files'} =  calibFiles;

list{'Eyelink'}{'TimestampsResponsesRH'} = zeros(1,trials); 
list{'Eyelink'}{'TimestampsResponsesLH'} = zeros(1,trials);
list{'Eyelink'}{'TimestampsStim'} = zeros(1,trials); % time of the beginning of the trial (not of the sound) 

list{'Input'}{'TimestampsStimLH'} = zeros(1,trials);
list{'Input'}{'TimestampsStimRH'} = zeros(1,trials); % time of the stimulus in the dynamometer clock
list{'Input'}{'MaxRH'} = -1 * ones(1,trials); % strength associated to the trial response with the dynamometer
list{'Input'}{'MaxLH'} = -1 * ones(1,trials); 
list{'Input'}{'TimeMaxRH'} = zeros(1,trials); % time response of the dynamometer (in second)
list{'Input'}{'TimeMaxLH'} = zeros(1,trials); 
list{'Input'}{'Choices'} = zeros(1,trials); % Storing whether subject squeezed the dynamometer
list{'Input'}{'Corrects'} = ones(1,trials)*-33; % Storing correctness of answers. Initialized to 33 so we know if there was no input during a trial with 33.
list{'Input'}{'ResponseRH'} = zeros(1,trials);
list{'Input'}{'StrengthMax'} = strength;

%list{'EEG'}{'Outlet'} = outlet;

list{'Delay'}{'PlayCheck'} =  zeros(1,trials); 

%% Input: SET UP HAND DYNAMOMETER
disp('Loading library DYN...');
% create dynamometer object
dRH=dynamometer(1);
dRH.start;
timeToD_RH  = GetSecs;

dLH=dynamometer(2);
dLH.start;
timeToD_LH = GetSecs;

thresRH = 0.40;
valthresholdRH = strength(1) * thresRH;
list{'Input'}{'ThresholdStrength'} = thresRH;


% translation from dynamometer LH to gauge (line on screen that represents
% required strength)
maxp = 1;%max x points of gauge on screen
nbPoints = 150;
eqS = linspace(0,strength(2)/3,nbPoints); 
eqG = linspace(-maxp,maxp,length(eqS));% equivalence of strength eqS on gauge (line on screen)
eqP = linspace(0,nbPoints/3,length(eqS));
[~,idMedLow] = min(abs(eqP-values(1)));
[~,idMedH1] = min(abs(eqP-values(2)));
[~,idHigh1] = min(abs(eqP-values(3)));

basLow = -maxp;
basMedLow = eqG(idMedLow); 
basMedHigh = eqG(idMedH1); 
basHigh = eqG(idHigh1); 
baseline = [basLow;basMedLow;basMedHigh;basHigh];

list{'Input'}{'DynamometerRH'} = dRH;
list{'Input'}{'DynamometerLH'} = dLH; 
list{'Input'}{'DynamometerStartRH'} = timeToD_RH; 
list{'Input'}{'DynamometerStartLH'} = timeToD_LH; 
list{'Input'}{'ThresholdRH'} = valthresholdRH;
list{'Input'}{'minStrength'} = 10; % see if this is ok
list{'Input'}{'BasValue'} = baseline;
list{'Input'}{'Gauge'} = [eqS;eqG];
list{'Input'}{'Debut'} = true;

%% Graphics:
% Create some drawable objects. Configure them with the constants above.

list{'Graphics'}{'gray'} = [0.65 0.65 0.65];

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
    fp.color = list{'Graphics'}{'gray'};
    fp.typefaceName = 'Calibri';
    fp.fontSize = 40;
    fp.isBold = 0;
    fp.string = '+';
    fp.x = 0;
    fp.y = 0;

  % outer circle
%     maxSize = 1;
    arcWidth = 0.03;
    list{'Graphics'}{'CircleWidth'} = arcWidth;
    sizeOutCircle = 0.5;
    list{'Graphics'}{'CircleSize'} = sizeOutCircle;
    arc = dotsDrawableArcs();
    arc.xCenter = 0;
    arc.yCenter = 0;
    arc.startAngle = 0;
    arc.sweepAngle = 360;
    arc.nPieces = 100;
    arc.rInner = sizeOutCircle;%radius
    arc.rOuter = sizeOutCircle + arcWidth;
    arc.colors = list{'Graphics'}{'gray'};
    
    % circle that fits the strength of the RH
    fitarc = dotsDrawableArcs();
    fitarc.xCenter = 0;
    fitarc.yCenter = 0;
    fitarc.startAngle = 0;
    fitarc.sweepAngle = 360;
    fitarc.nPieces = 100;
    fitarc.rInner = 0;
    fitarc.rOuter = 0;
    fitarc.colors = list{'Graphics'}{'gray'};

    % Gauge strength
    % line on screen
    g = dotsDrawableLines();
    g.xFrom = -maxp;
    g.xTo = maxp;
    g.yFrom = 1.1;
    g.yTo = 1.1;
    g.pixelSize = 3;
    g.colors =  list{'Graphics'}{'gray'};
    % Range of strength
    l1 = dotsDrawableLines();
    l1.xFrom  = basLow(1);
    l1.xTo    = basLow(1);
    l1.yFrom  = 1.4;
    l1.yTo    = 0.8;
    l1.pixelSize = 2.5;
    l1.colors = list{'Graphics'}{'gray'};
    % target on gauge
    t = dotsDrawableTargets();
    t.xCenter = 0;
    t.yCenter = 1.1;
    t.width = 0.20;
    t.height = 0.20;
    t.colors = list{'Graphics'}{'gray'};

    %Graphical ensemble
    ensemble = dotsEnsembleUtilities.makeEnsemble('Fixation Point', false);
    texture     = ensemble.addObject(checkTexture1);
    arcOut      = ensemble.addObject(arc);
    arcStrength = ensemble.addObject(fitarc);
    dot         = ensemble.addObject(fp); 
    gauge       = ensemble.addObject(g);
    movingDot   = ensemble.addObject(t);
    limit1      = ensemble.addObject(l1);
    
    list{'Graphics'}{'Dot Index'} = dot;
    list{'Graphics'}{'MovingCircle'} = arcStrength;
    list{'Graphics'}{'Moving Dot'} = movingDot;
    list{'Graphics'}{'BoundL'} = limit1;
    
    % tell the ensembles how to draw a frame of graphics
    %   the static drawFrame() takes a cell array of objects
    ensemble.automateObjectMethod(...
    'draw', @dotsDrawable.drawFrame, {}, [], true);
    
    list{'Graphics'}{'Ensemble'} = ensemble;
    
%SCREEN

    % also put dotsTheScreen into its own ensemble
    screen = dotsEnsembleUtilities.makeEnsemble('screen', false);
    screen.addObject(dotsTheScreen.theObject());

    % automate the task of flipping screen buffers
    screen.automateObjectMethod('flip', @nextFrame);
      
% Get blocks of trials
    trialsType = [];
    for i=1:nbTen
        nextBlock = randperm(3)+1;
        nextBlocks = [ones(10,1)*nextBlock(1);ones(10,1); ones(10,1) * nextBlock(2);...
            ones(10,1);ones(10,1)*nextBlock(3); ones(10,1)]; 
        if i==nbTen
            trialsType = [trialsType ; nextBlocks(1:nbCond*20-10)];
        else
            trialsType = [trialsType ; nextBlocks];
        end     
    end
    list{'Input'}{'Block'} = trialsType';
    
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
                 'Start', {despin dot}, {}, {}, 0, 'Stimulus';
                 'CheckReady', {}, {}, {@checkReady list}, 0, 'Stimulus';
                 'Stimulus', {stimulusfunc list}, {}, {}, 0, 'ReadDyno';
                 'ReadDyno', {}, {@readStrengthBaseline, list}, {}, reactionwindow, 'CheckFix';
                 'CheckFix', {@checkFixation list}, {}, {}, 0, 'Feedback'
                 'Feedback', {}, {checkfunc list}, {}, 0, '';
                 'Correct', {despin dot}, {}, {}, 0, '';
                 'Incorrect', {spin dot}, {}, {}, 0.1, ''};

                    
Machine.addMultipleStates(stimList);
contask = topsConcurrentComposite();
contask.addChild(ensemble);
contask.addChild(Machine);

maintask = topsTreeNode();
maintask.iterations = trials;
maintask.addChild(contask);

end

%% Accessory Functions

function playstim(list)

    %Adding current iteration to counter
    counter = list{'Stimulus'}{'Counter'};
    counter = counter + 1;
        disp(['trial: ',int2str(counter)]);
    list{'Stimulus'}{'Counter'} = counter;
   
    %importing important list objects
    player = list{'Stimulus'}{'Player'};
    standardf = list{'Stimulus'}{'StandardFreq'};
    oddf = list{'Stimulus'}{'OddFreq'};  
    p_deviant  = list{'Stimulus'}{'ProbabilityDeviant'};
    calibTones  = list{'Stimulus'}{'Tones'};
    outlet =list{'EEG'}{'Outlet'}; % EEG object
    boundl = list{'Graphics'}{'BoundL'};
    drawable  = list{'Graphics'}{'Ensemble'};
    baseline = list{'Input'}{'BasValue'};
    trialsType = list{'Input'}{'Block'};
    prev   = list{'Stimulus'}{'Playfreqs'};
    
    if counter >1
        prevTrial  =  prev(counter-1);
    end
    % reset trial
    list{'Input'}{'Debut'} = true;
    
   % Shift bounds
    if trialsType(counter) == 1 % no bound when no grip required
        drawable.setObjectProperty('isVisible', false, boundl);
    else
        %gauge
        drawable.setObjectProperty('isVisible', true, boundl);
        drawable.setObjectProperty('xFrom',baseline(trialsType(counter)), boundl);
        drawable.setObjectProperty('xTo',baseline(trialsType(counter)), boundl);
    end
    
    % Dice roll to decide if odd, standard or novelty if apply
    rollDev = rand;
    if counter >1 && trialsType(counter) ~= trialsType(counter-1) || counter >1 && prevTrial == oddf
        % so that the first trial of each block is not an oddball and that
        % there are not 2 oddballs in a row
        frequency = standardf;
    else
        frequency(rollDev >  p_deviant) = standardf;
        frequency(rollDev <= p_deviant) = oddf;
    end
    
    % Save frequency
    playfreqs = list{'Stimulus'}{'Playfreqs'};
    playfreqs(counter) = frequency;
    list{'Stimulus'}{'Playfreqs'} = playfreqs;
    disp(['Type: ',int2str(frequency)]);
   
    % Prepare to play standard or oddball sounds---------------------------  
       if frequency == standardf
           freq = calibTones.calibratedVoltagesMean(1);
       else
           freq = calibTones.calibratedVoltagesMean(2);
       end
       player.frequency = frequency;
       player.intensity = freq;
       player.prepareToPlay;
           %Prepping player and playing
           tic
           timeDyn = GetSecs;
           list{'Stimulus'}{'TimeDyn'} = timeDyn;
           newsample = Eyelink('NewestFloatSample');
           outlet.push_sample({'Stim'});   % send label stim to EEG timestamps
           timeAf =toc;
       player.play;
   
    afStim = GetSecs;
    stimTime = afStim-timeDyn; 
    % How long the stimulus takes to ring
    stimTps = list{'Stimulus'}{'Start'};
    stimTps(counter) = stimTime;
    list{'Stimulus'}{'Start'}= stimTps;
    
    % How long to get all timestamps
    stimAll = list{'Stimulus'}{'AllDevice'};
    stimAll(counter) = timeAf;
    list{'Stimulus'}{'AllDevice'}= stimAll;
    
    % TIMESTAMPS STIM
    % Eye tracker 
    eyetime = list{'Eyelink'}{'TimestampsStim'}; 
    eyetime (counter)= newsample.time;
    list{'Eyelink'}{'TimestampsStim'} = eyetime; % in msc
    
end


function next_state_ = readStrengthBaseline (list)

    % Timer
    debut = list{'Input'}{'Debut'};
     if debut
         list{'Input'}{'Debut'} = false;
         list{'Input'}{'Timer'} = 1;
         list{'Input'}{'Press'} = false;
         list{'Input'}{'TrialStrengthRH'} = zeros(1200,1);
         list{'Input'}{'TrialTimeRH'} = zeros(1200,1);
         i=1;  
     else
         i = list{'Input'}{'Timer'} +1;
         list{'Input'}{'Timer'} = i;
     end
     
    % Import variables
    next_state_ = 'position';
    eqS2G = list{'Input'}{'Gauge'};% equivalence strength to gauge
    movingdot = list{'Graphics'}{'Moving Dot'}; % graphic component og the target on the gauge
    drawable  = list{'Graphics'}{'Ensemble'};
    startExpeRH  = list{'Input'}{'DynamometerStartRH'};
    dRH = list{'Input'}{'DynamometerRH'};
    dLH = list{'Input'}{'DynamometerLH'};
    startMove = list{'Input'}{'minStrength'};
    timeDyn  = list{'Stimulus'}{'TimeDyn'};
    counter  = list{'Stimulus'}{'Counter'};
    pressRH  = list{'Input'}{'Press'};
    startExpeLH  = list{'Input'}{'DynamometerStartLH'};
    maxStrength = list{'Input'}{'StrengthMax'};
    maxRH = maxStrength(1);
    sizeOutCircle = list{'Graphics'}{'CircleSize'};
    arcStrength = list{'Graphics'}{'MovingCircle'};
    arcWidth = list{'Graphics'}{'CircleWidth'};
    thresholdStrength = list{'Input'}{'ThresholdStrength'};
    outlet =list{'EEG'}{'Outlet'}; % EEG object
   
    
    % LH -----------------------------------------------------------------
    if true
        trialS_LH = dLH.read;
        [~,idxG]  = min(abs(eqS2G(1,:) - repmat(trialS_LH, length(eqS2G),1)'));
        converted =  eqS2G(2,idxG);  
        drawable.setObjectProperty('xCenter',converted,movingdot);
    % RH -----------------------------------------------------------------
        trialS_RH  = dRH.read;
        percStrength = trialS_RH/maxRH;
        widthC = (percStrength * sizeOutCircle)/thresholdStrength;
        drawable.setObjectProperty('rInner',widthC,arcStrength);
        drawable.setObjectProperty('rOuter',widthC+arcWidth,arcStrength);
        tpsRH = GetSecs;
        
        % Check for movement
        if trialS_RH > startMove && pressRH == false
            list{'Input'}{'Press'} = true;
            % Timestamp start movement:
            % Dyn time
            timeDynamometerRH = list{'Input'}{'ResponseRH'};
            timeDynamometerRH(counter) = tpsRH - startExpeRH;
            list{'Input'}{'ResponseRH'} = timeDynamometerRH;
            % Eyetracker time
            sampleRH = Eyelink('NewestFloatSample');
            eyetimeDynRH = list{'Eyelink'}{'TimestampsResponsesRH'}; 
            eyetimeDynRH (counter)= sampleRH.time;
            list{'Eyelink'}{'TimestampsResponsesRH'}  = eyetimeDynRH; 
            list{'Input'}{'Press'} = true;
            % EEG time
            outlet.push_sample({'Squeeze'});     
        end

    if i == 1 
   % Time Stim Starts - Dynamometer RH
        playtimesRH = list{'Input'}{'TimestampsStimRH'};
        playtimesRH(counter) = timeDyn - startExpeRH;
        list{'Input'}{'TimestampsStimRH'}= playtimesRH;
   % Time Stim Starts - Dynamometer LH
        playtimesLH = list{'Input'}{'TimestampsStimLH'};
        playtimesLH(counter) = timeDyn - startExpeLH;
        list{'Input'}{'TimestampsStimLH'} = playtimesLH;      
    end

    % Store pressure history on each trial 
    pressureRH = list{'Input'}{'TrialStrengthRH'};
    pressureRH(i) = trialS_RH;
    list{'Input'}{'TrialStrengthRH'} = pressureRH;
    
    % Timestamp of the dynamometer 
    timePressRH = list{'Input'}{'TrialTimeRH'};
    timePressRH(i) = tpsRH;
    list{'Input'}{'TrialTimeRH'} = timePressRH;
    
    tic

    end
end
   

function string = checkinput(list)

    %import important list objects
    counter        = list{'Stimulus'}{'Counter'};
    valthresholdRH = list{'Input'}{'ThresholdRH'};
    trialS_RH      = list{'Input'}{'TrialStrengthRH'}; 
    trialS_timeRH  = list{'Input'}{'TrialTimeRH'};
    startMove      = list{'Input'}{'minStrength'}; 

    %To check if correct
    opposite_input_on = list{'Input'}{'OppositeOn'};
    freqlist = list{'Stimulus'}{'Playfreqs'};
    oddf = list{'Stimulus'}{'OddFreq'};
    standardf = list{'Stimulus'}{'StandardFreq'};
     
    % by default
    correct = 0; 
   
    % Max grip strength during trial
    [maxTrialRH, idxRH] = max(trialS_RH);
    timeMaxRH = trialS_timeRH(idxRH);
    disp(['Max strength RH: ',int2str(maxTrialRH)]);
    
    % Check if trial is correct
    if opposite_input_on == 1
        checkfreq = standardf; %If opposite input is on, subjects must press button for standard frequency
    else
        checkfreq = oddf;
    end
    
    % it depends on the type of trial and the max strength recorded
    if freqlist(counter)== checkfreq && maxTrialRH > startMove 
        correct = 1;
    elseif freqlist(counter)~= checkfreq && maxTrialRH < startMove 
        correct = 1;
    end
   
    
    if correct == 1
        string = 'Correct';
    else
        string = 'Incorrect';
    end
            
    % Max grip
    valMaxRH = list{'Input'}{'MaxRH'};
    valMaxRH(counter) = maxTrialRH;
    list{'Input'}{'MaxRH'} = valMaxRH;
    
    % Time max grip
    valMaxRH = list{'Input'}{'TimeMaxRH'};
    valMaxRH(counter) = timeMaxRH;
    list{'Input'}{'TimeMaxRH'} = valMaxRH;

    %Storing user input 
    corrects = list{'Input'}{'Corrects'};
    corrects(counter) = correct;
    list{'Input'}{'Corrects'} = corrects;
    
    %check delay btw end reaction window and end trial
    valDelay = list{'Delay'}{'PlayCheck'};
    valDelay(counter) = toc;
    list{'Delay'}{'PlayCheck'} = valDelay;
    
end  

    
function checkFixation(list)
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
