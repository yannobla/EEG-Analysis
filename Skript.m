restoredefaultpath
addpath 'C:\Users\melis\Documents\MATLAB\fieldtrip-20240731'
ft_defaults
addpath ('C:\Users\melis\Documents\Trento\Verona_Experiment\Prova01_10')
%% segment data into trials with correct trialfunction
cfg                 = [];
cfg.trialfun        = 'trialfun_visgam'; 
cfg.headerfile      = 'Prova01_10_exp.vhdr';
cfg.datafile        = 'Prova01_10_exp.eeg';
trialdata           = ft_definetrial(cfg);
%% preprocessing and rereferencing
cfg.implicitref     = 'Fp1';
cfg.reref           = 'yes';
cfg.refchannel      = 'average';
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
%ft_databrowser(cfg, brodata)
% remember the time of the artifacts
cfg_artfctdef       = brodata.artfctdef;
artif.badchannel  = {'T7'; 'TP9'; 'P8'; 'TP10'; 'T8'};
%% artifact rejection
cfg                     = [];
cfg.artifactdef         = cfg_artfctdef;
cfg.artfctdef.reject    = 'partial';
data_clean              = ft_rejectartifact(cfg, resampdata);
%% badchan repair
cfg = [];
cfg.channel     = 'all' ;
cfg.method         = 'triangulation';
cfg.template    = 'easycap64ch-avg_neighb.mat';
cfg.layout      = 'easycapM11.mat';
ft_neighbourplot(cfg);
neighbours     = ft_prepare_neighbours(cfg, data_clean);
cfg = [];
cfg.badchannel     = artif.badchannel;
cfg.method         = 'average';
cfg.neighbours     = neighbours;
data_fixed = ft_channelrepair(cfg,data_clean);
% cfg                 = [];
% cfg.demean          = 'yes';
% cfg.detrend         = 'yes';
% ft_databrowser(cfg, data_fixed)
%% ICA decomposition
cfg              = [];
cfg.method       = 'fastica';
cfg.numcomponent = 32; %why does it stop after 52 components?
data_comp = ft_componentanalysis(cfg, data_fixed); % using the data without atypical artifacts
%% Identifying artifactual components
cfg           = [];
cfg.layout    = 'acticap-64ch-standard2.mat';
cfg.component = 1:26;
cfg.marker    = 'off';
ft_topoplotIC(cfg, data_comp)

%look at the time course of the components
% cfg = [];
% cfg.viewmode  = 'component';
% cfg.layout    = 'acticap-64ch-standard2.mat';
% cfg.continous = 'yes'
% ft_databrowser(cfg, data_comp);


% remove the bad components and backproject the data
cfg = [];
cfg.component = [1 2 4 5 7 14]; % to be removed component(s)
data_postica = ft_rejectcomponent(cfg, data_comp, data_fixed );

%Filtering
cfg = [];
cfg.channel    = (1:32);
cfg.detrend    = 'yes';
cfg.demean     = 'yes';
cfg.dftfilter  = 'yes';
cfg.dftfreq    = [50, 100];
% cfg.bsfilter  = 'no'; % band-stop method
% cfg.bsfreq    = [48 52];
data_preproc2 = ft_preprocessing(cfg,data_postica);
%% Freqanalysis
%Redefinetrials
cfg                 = [];
cfg.toilim          = [-1.0 2.8];
cfg.minlength       = 'maxperlen'; % this ensures all resulting trials are equal length
data_stim          = ft_redefinetrial(cfg, data_preproc2);

cfg                 = [];
cfg.output          = 'pow';
cfg.method          = 'mtmconvol';
cfg.taper           = 'hanning';
cfg.tapsmofrq       =   5;
cfg.channel         = 'all';
% set the frequencies of interest
cfg.foi             = 30:1:100;

% set the timepoints of interest
cfg.toi             = -1:0.05:2.8;

% set the time window for TFR analysis: constant length of 200ms
cfg.t_ftimwin       = 0.45 * ones(length(cfg.foi), 1);

% average over trials
cfg.keeptrials      = 'yes';

% pad trials to integer number of seconds, this speeds up the analysis
% and results in a neatly spaced frequency axis
cfg.pad             = 4;
freq_stim                = ft_freqanalysis(cfg, data_stim);
%% Plot Frequencies
cfg = [];
cfg.baseline     = [-0.5 0]; 
cfg.baselinetype = 'relchange';
%cfg.zlim            = [-3e-27 3e-27];
cfg.xlim            = [0 2.5];
cfg.ylim            = 'maxmin'; 
cfg.showlabels   = 'yes';	
cfg.layout       = layout64;
%ft_topoplotTFR(cfg, freq_stim);
ft_multiplotTFR(cfg, freq_stim);
