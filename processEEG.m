% SCRIPT TO PROCESS EEG SIGNALS
% simple example of the steps to follow.
% -----------------------------------------------------------------------------------------------------------

% YOU NEED TO DOWNLOAD EEGLAB and CHRONUX
addpath('C:\PATH\eeglab14_1_1b');
addpath(genpath('C:\PATH\Chronux'));


freq = varXDF.xdf{1, 1}.info.effective_srate; % frequency 
nbCh = varXDF.xdf{1, 1}.info.channel_count; % number of channels
loc = {'Fz','Fp1','Fp2','Cz','C4','Pz','P4','P3'};
chanlocs = struct('labels', {'Fz','Fp1','Fp2','Cz','C4','Pz','P4','P3'}); % Your eeg channels 
%pop_chanedit( chanlocs ); % to edit chanLocs.ced file

%% 1 - import file
eeglab();
eventsEEG(); load('events.mat'); 
eegdata = [varXDF.xdf{1, 1}.time_series;events]; save('eegdata.mat','eegdata');
load('eegdata.mat')
eegImp = importdata('eegdata.mat');
EEG = pop_importdata('data',eegImp,'srate',freq);

%% 2 - Import events (beginning of trials)
EEG = pop_chanevent(EEG,9,'edge','leading');

%% 3 - Specify channels locations
EEG = pop_chanedit(EEG,'load','chanLocs.ced'); % you have to create this file 
[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, CURRENTSET+1, 'setname', 'Continuous Raw EEG Data', 'overwrite', 'on');  

%% 4 - Filter data
% highpass filter cutoff (here: 0.1Hz & 125Hz)
freqFilt = round(EEG.srate/2)-1;
sRateLow = 125;
[EEG, com, b] = pop_eegfiltnew(EEG,0.1);
[EEG, com, b] = pop_eegfiltnew(EEG,[],sRateLow);

% PLOT to have an idea how it looks like
plotSpec = true;
fBand = 1:sRateLow;
bwT_coh = [5 9];
params   = struct('tapers',bwT_coh,'pad',0,'Fs',freq,'fpass', fBand,'err',0,'trialave',0);
if plotSpec
    for i =1 : length(loc)
        [S,f]= mtspectrumc(eegImp(i,:),params); %before cleaning
        [S_filt,f_filt]= mtspectrumc(EEG.data(i,:),params); % after filters 
                figure; hold on;
                subplot(2,1,1); plot(f,pow2db(S));
                subplot(2,1,2); plot(f_filt,pow2db(S_filt));
                title(['channel: ',loc{i}]) 
    end
end

% Remove 60Hz (the range you choose depends on how it looks from previous plot)
range1=59;
range2=61;
d = designfilt('bandstopiir','FilterOrder',2, ...
                    'HalfPowerFrequency1',range1,'HalfPowerFrequency2',range2, ...
                    'DesignMethod','butter','SampleRate',freq);
 for i =1:length(loc)
     buttLoop = filtfilt(d,double(eegout.data(i,:)));
     eegout.data(i,:) = buttLoop;
     clear buttLoop
 end

%% 5 - reject by eye - VERY IMPORTANT STEP!!!!
% must save the dataset before (or it doesn't work!!)
[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, CURRENTSET+1, 'setname', 'Continuous EEG Data Filtered', 'overwrite', 'on');  
pop_eegplot(EEG,1,1,1);

%% 6 - Getting rid of bad channels (if any)
[EEG, indelec, measure, com] = pop_rejchan(EEG,'elec',1:8,'threshold',5,'norm','on');

pop_signalstat(EEG, 1);
badCh = % enter here which channel if any[];
eegout = pop_interp(eegout, badCh, 'spherical');

%% re-reference
eegout = pop_reref(EEG,[],'exclude',badCh);
figure(); plot(eegImp(4,:),'-g');hold on; plot(eegout.data(4,:),'-r');
plot(eegout2.data(4,:),'-c');


%% 7 - Making epochs
EEG = pop_epoch(EEG, {'1' '2'} , [-1 1]);

%% 8 - Baseline removal
EEG = pop_rmbase(EEG, [-200 0]);

%% 9 - Detrend (remove linear drift)
EEG = eeg_detrend(EEG);

%% 6 - Save dataset
[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, CURRENTSET+1, 'setname', 'Continuous EEG Data epochs', 'overwrite', 'on');  
%[ALLEEG EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);

 %% RUNNING ICA (remouve eye/movements artefacts)
chId = % channels on which you run ICA [1:8];
EEG = pop_runica(EEG,'icatype','runica','chanind',chId); 
EEG.srate=round(EEG.srate);
pop_selectcomps(EEG); %vizualise composants
pop_eegplot(EEG,0) % plot components ICA

% to reject composants:
comp = %for example: [1] 
EEG = pop_subcomp(EEG, comp,1,0);

% save
[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, CURRENTSET+1, 'setname', 'Continuous EEG Data epochs after ICA', 'overwrite', 'on');  
 

%% Visually inspect epoch

pop_eegplot(EEG,1,1,1)

 
 %% 7 - Reject artefacts --> pop_rejmenu(eegout, 1) for window menu
 
 chId= % channels that you keep [];
 
 %7.1 Extremes values
 [EEG IdxAbnVal] = pop_eegthresh(EEG, 1, chId, -100, ...
                100, round(EEG.xmin), round(EEG.xmax),0,1);
 %7.2 Rejecting abnormal trends 
 EEG = pop_rejtrend(EEG, 1, chId, ...
                EEG.pnts, 0.5, 0.4, 0, 1,1);
 %7.3 Rejecting improbable data
  [EEG, locthresh, globthresh, nrej]= pop_jointprob(EEG, 0,...
      chId,4,4);
 %7.4 Rejecting abnormally distributed data 
 [EEG, locthresh, globthresh, nrej] = pop_rejkurt(EEG, 1,...
                   chId,4,4);
 %7.5 Rejecting abnormal spectra 
 [EEG, IdxAbnSpec] = pop_rejspec(EEG,1, 'elecrange',chId,...
     'threshold',[-40 40],'freqlimits',[0 2],'method','fft'); 
 
 [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, CURRENTSET+1, 'setname', 'EEG Data epochs after artefacts rejection', 'overwrite', 'on');  

%% running ICA again (if needed)

 chId = [1 :8];
 OUT_EEG = pop_runica(eegout,'icatype','runica','chanind',chId); 
 OUT_EEG.srate=round(eegout.srate);
 OUT_EEG = pop_selectcomps(OUT_EEG); %vizualise composants
 % to reject composants:
 comp = [1]; %3
 OUT_EEG = pop_subcomp(OUT_EEG, comp,1,0);
 
 
 %% Create ERPs (depends on your channels)
pop_erpimage(EEG,1)
figure; pop_erpimage(EEG,1,[4],[[]],'Cz',20,1,{ '2'},[],'type' ,'yerplabel','\muV','erp','on','cbar','on','topo', { [4] EEG.chanlocs EEG.chaninfo } );
figure; pop_erpimage(EEG,1, [5],[[]],'C4',20,1,{ '2'},[],'type' ,'yerplabel','\muV','erp','on','cbar','on','topo', { [4] EEG.chanlocs EEG.chaninfo } );
figure; pop_erpimage(EEG,1, [6],[[]],'Pz',20,1,{ '2'},[],'type' ,'yerplabel','\muV','erp','on','cbar','on','topo', { [4] EEG.chanlocs EEG.chaninfo } );
figure; pop_erpimage(EEG,1, [7],[[]],'P4',10,1,{ '2'},[],'type' ,'yerplabel','\muV','erp','on','cbar','on','topo', { [7] EEG.chanlocs EEG.chaninfo } );
figure; pop_erpimage(EEG,1, [8],[[]],'P3',10,1,{ '2'},[],'type' ,'yerplabel','\muV','erp','on','cbar','on','topo', { [7] EEG.chanlocs EEG.chaninfo } );
figure; pop_erpimage(EEG,1, [1],[[]],'Fz',10,1,{ '2'},[],'type' ,'yerplabel','\muV','erp','on','cbar','on','topo', { [7] EEG.chanlocs EEG.chaninfo } );

figure; pop_erpimage(EEG,1,[4],[[]],'Cz',20,1,{ '1'},[],'type' ,'yerplabel','\muV','erp','on','cbar','on','topo', { [4] EEG.chanlocs EEG.chaninfo } );
figure; pop_erpimage(EEG,1, [5],[[]],'C4',20,1,{ '1'},[],'type' ,'yerplabel','\muV','erp','on','cbar','on','topo', { [4] EEG.chanlocs EEG.chaninfo } );
figure; pop_erpimage(EEG,1, [6],[[]],'Pz',20,1,{ '1'},[],'type' ,'yerplabel','\muV','erp','on','cbar','on','topo', { [4] EEG.chanlocs EEG.chaninfo } );
figure; pop_erpimage(EEG,1, [7],[[]],'P4',10,1,{ '1'},[],'type' ,'yerplabel','\muV','erp','on','cbar','on','topo', { [7] EEG.chanlocs EEG.chaninfo } );
figure; pop_erpimage(EEG,1, [8],[[]],'P3',10,1,{ '1'},[],'type' ,'yerplabel','\muV','erp','on','cbar','on','topo', { [7] EEG.chanlocs EEG.chaninfo } );
figure; pop_erpimage(EEG,1, [1],[[]],'Fz',10,1,{ '1'},[],'type' ,'yerplabel','\muV','erp','on','cbar','on','topo', { [7] EEG.chanlocs EEG.chaninfo } );

    
 
EEG1 = pop_selectevent(EEG);
[ALLEEG EEG1, CURRENTSET] = pop_newset(ALLEEG, EEG1, CURRENTSET+1, 'setname', 'stand cond', 'overwrite', 'on');  
EEG2 = pop_selectevent(EEG);
[ALLEEG EEG2 CURRENTSET] = pop_newset(ALLEEG, EEG2, CURRENTSET+1, 'setname', 'odd cond', 'overwrite', 'on');  

[erp1 erp2 erpsub time sig] = pop_comperp(ALLEEG) 
 
 
%% save set
EEG2 =;
pop_saveset(EEG)
[OUTEEG3] = pop_resample(EEG3, 150);
[OUTEEG2] = pop_resample(EEG2, 150);
[OUTEEG1] = pop_resample(EEG1, 150);

pop_saveset(OUTEEG1)
pop_saveset(OUTEEG2)
pop_saveset(OUTEEG3)

pop_study([],[], 'gui', 'on');

% This example Matlab code shows how to compute power spectrum of epoched data, channel 2.
[spectra,freqs] = spectopo(EEG.data, 0, EEG.srate);

% Set the following frequency bands: delta=1-4, theta=4-8, alpha=8-13, beta=13-30, gamma=30-80.
deltaIdx = find(freqs>1 & freqs<4);
thetaIdx = find(freqs>4 & freqs<8);
alphaIdx = find(freqs>8 & freqs<13);
betaIdx  = find(freqs>13 & freqs<30);
gammaIdx = find(freqs>30 & freqs<80);

% Compute absolute power.
deltaPower = mean(10.^(spectra(deltaIdx)/10));
thetaPower = mean(10.^(spectra(thetaIdx)/10));
alphaPower = mean(10.^(spectra(alphaIdx)/10));
betaPower  = mean(10.^(spectra(betaIdx)/10));
gammaPower = mean(10.^(spectra(gammaIdx)/10)); 
 


 