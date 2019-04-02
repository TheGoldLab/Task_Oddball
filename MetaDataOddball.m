% This script will allow you to add information in the EEG outlet (name of
% channelsm frequency etc.)


%% instantiate the library
    lib = lsl_loadlib();

    % create a new StreamInfo and declare some meta-data (in accordance with XDF format)
    nbCh = length(label);
    info = lsl_streaminfo(lib,'MetaTester','EEG',nbCh,freq,'cf_float32','myuid56872');
    chns = info.desc().append_child('channels');

    for l = 1: nbCh
        ch = chns.append_child('channel');
        ch.append_child_value('label',label{l});
        ch.append_child_value('unit','microvolts');
        ch.append_child_value('type','EEG');
    end

    info.desc().append_child_value('manufacturer','OpenBCI');
    cap = info.desc().append_child('cap');
    cap.append_child_value('labelscheme','10-20');

    % create outlet for the stream
    outlet = lsl_outlet(info);
    

