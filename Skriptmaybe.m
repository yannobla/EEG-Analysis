%% segment data into trials with correct trialfunction
cfg                         = [];
cfg.dataset                 = 'YS-VisGAMMA_def.vhdr';
cfg.trialfun                = 'trialfun_visgam'; 
trialdata = ft_definetrial(cfg);
preproc_data = ft_preprocessing(trialdata);
cfg.demean      = 'yes'
cfg.detrend     = 'yes'
rawdata_1 = ft_databrowser(cfg, preproc_data)
rawdata_2 = ft_databrowser(cfg, rawdata_1) % incase you want to continue working on rawdata
%%
% cfg = [];
% cfg.method = 'summary';
% cfg.metric = 'var';
% cfg.keepchannel = 'no';
% cfg.trials = [1, 1]
% data_clean = ft_rejectvisual(cfg, preproc_data);
% 
% 
% cfg = []
% cfg.verticalscale = 1e-6
% cleanchanneldata= ft_databrowser(cfg, preproc_data)
%% baseline correction
cfg.demean          = 'yes';
cfg.baselinewindow  = [-0.2 0];
%% filtering
cfg.dftfilter   = 'yes'
% cfg.dataset   = 'YS-VisGAMMA_def.eeg';
% cfg.hpfreq    = 0.5;
% cfg.hpfilter  = 'yes';
trialdata = ft_preprocessing(cfg);



