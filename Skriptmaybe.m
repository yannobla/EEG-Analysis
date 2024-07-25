addpath ('C:\Users\melis\Documents\Trento\Verona_Experiment\YS_visGamma_20240716\eeg\')
%% segment data into trials with correct trialfunction
cfg                 = [];
cfg.trialfun        = 'trialfun_visgam'; 
cfg.headerfile      = 'YS-VisGAMMA_def.vhdr';
cfg.datafile        = 'YS-VisGAMMA_def.eeg';
trialdata           = ft_definetrial(cfg);
%% preprocessing and rereferencing
cfg.implicitref     = 'LM';
cfg.reref           = 'yes';
cfg.refchannel      = {'LM' 'RM'};
preproc_data        = ft_preprocessing(trialdata);
%% resampling
cfg                 = [];
cfg.resamplefs      = 300;
resampdata          = ft_resampledata(cfg, preproc_data);
%% data browser to mark artifacts
cfg                 = [];
cfg.demean          = 'yes';
cfg.detrend         = 'yes';
brodata             = ft_databrowser(cfg, resampdata);
%brodata_2          = ft_databrowser(cfg, brodata) % incase you want to continue working on rawdata
% remember the time of the artifacts
cfg_artfctdef       = brodata.artfctdef;
%% artifact rejection
cfg                     = [];
cfg.artifactdef         = cfg_artfctdef;
cfg.artfctdef.reject    = 'partial';
data_clean              = ft_rejectartifact(cfg, resampdata);
%% ICA decomposition
cfg              = [];
cfg.method       = 'fastica';
cfg.numcomponent = 64; %why does it stop after 52 components?
data_comp = ft_componentanalysis(cfg, data_clean); % using the data without atypical artifacts
%% Identifying artifactual components
cfg           = [];
cfg.layout    = 'acticap-64ch-standard2.mat';
cfg.component = 1:10;
cfg.marker    = 'off';
ft_topoplotIC(cfg, data_comp)
% look at the time course of the components
cfg = [];
cfg.viewmode  = 'component';
cfg.layout    = 'CTF151.lay';
cfg.blocksize = 45;
ft_databrowser(cfg, data_comp);


%% FP1 and FP2 need to be removed
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
cfg.dftfilter   = 'yes';
% cfg.dataset   = 'YS-VisGAMMA_def.eeg';
% cfg.hpfreq    = 0.5;
% cfg.hpfilter  = 'yes';
trialdata       = ft_preprocessing(cfg);
