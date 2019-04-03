function visualizeEEG (label,freq)

nbCh = length(label)+1;


vis_stream('streamname','OpenBCI_EEG', 'bufferrange', 20 , 'timerange', 5,'DataScale',100, 'ChannelRange',1:nbCh,...
   'SamplingRate',freq, 'RefreshRate',10,'FrequencyFilter',[4 5 50 60],'ZeroMean',true, 'channellabel', label);


end

