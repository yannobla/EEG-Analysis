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
ft_databrowser(cfg, brodata)
% remember the time of the artifacts
cfg_artfctdef       = brodata.artfctdef;
artif.badchannel  = {'Fp1'; 'Fp2'; 'TP9'; 'T7'; 'T8'};
%% artifact rejection
cfg                     = [];
cfg.artifactdef         = cfg_artfctdef;
cfg.artfctdef.reject    = 'partial';
data_clean              = ft_rejectartifact(cfg, resampdata);
%% badchan repair
cfg = [];
cfg.channel     = 'all' 
cfg.method         = 'triangulation';
cfg.template    = 'easycap64ch-avg_neighb.mat'
cfg.layout      = 'easycapM11.mat'
ft_neighbourplot(cfg)
neighbours     = ft_prepare_neighbours(cfg, data_clean);
cfg = [];
cfg.badchannel     = artif.badchannel;
cfg.method         = 'average';
cfg.neighbours     = neighbours;
data_fixed = ft_channelrepair(cfg,data_clean);
cfg             ;
cfg.demean          = 'yes';
cfg.detrend         = 'yes';   
ft_databrowser(cfg, data_fixed)
%% ICA decomposition
cfg              = [];
cfg.method       = 'fastica';
cfg.numcomponent = 64; %why does it stop after 52 components?
data_comp = ft_componentanalysis(cfg, data_fixed); % using the data without atypical artifacts
%% Identifying artifactual components
cfg           = [];
cfg.layout    = 'acticap-64ch-standard2.mat';
cfg.component = 30:60;
cfg.marker    = 'off';
ft_topoplotIC(cfg, data_comp)

% look at the time course of the components
% cfg = [];
% cfg.viewmode  = 'component';
% cfg.layout    = 'easycapM11.mat';
% cfg.continous = 'yes'
% ft_databrowser(cfg, data_comp);


% remove the bad components and backproject the data
cfg = [];
cfg.component = [4 5 12 20]; % to be removed component(s)
data_postica = ft_rejectcomponent(cfg, data_comp, data_fixed)

%Filtering
cfg = [];
cfg.channel    = 'all';
cfg.detrend    = 'yes'
cfg.demean     = 'yes';
cfg.dftfilter  = 'yes';
cfg.dftfreq    = [50, 100];
% cfg.bsfilter  = 'no'; % band-stop method
% cfg.bsfreq    = [48 52];
data_preproc2 = ft_preprocessing(cfg,data_postica);
%% Freqanalysis
%Redefinetrials

cfg                 = [];
cfg.toilim          = [-1.0 0];
cfg.minlength       = 1; % this ensures all resulting trials are equal length
data_baseline          = ft_redefinetrial(cfg, data_preproc2);


cfg                 = [];
cfg.toilim          = [0.5 1.5];
cfg.minlength       = 'maxperlen'; % this ensures all resulting trials are equal length
data_stim          = ft_redefinetrial(cfg, data_preproc2);




%freqanalysis
cfg                 = [];
cfg.output          = 'pow';
cfg.method          = 'mtmconvol';
cfg.taper           = 'hanning';
cfg.tapsmofrq       =  5
cfg.channel         = 'all';

% set the frequencies of interest
cfg.foi             = 1:1:100;

% set the timepoints of interest: from -0.8 to 1.1 in steps of 100ms
cfg.toi             = -1:0.05:0;

% set the time window for TFR analysis: constant length of 200ms
cfg.t_ftimwin       = 0.45 * ones(length(cfg.foi), 1);

% average over trials
cfg.keeptrials      = 'yes';

% pad trials to integer number of seconds, this speeds up the analysis
% and results in a neatly spaced frequency axis
cfg.pad             = 4;
freq_baseline                = ft_freqanalysis(cfg, data_baseline);



cfg                 = [];
cfg.output          = 'pow';
cfg.method          = 'mtmconvol';
cfg.taper           = 'hanning';
cfg.tapsmofrq       =   5
cfg.channel         = 'all';
% set the frequencies of interest
cfg.foi             = 1:1:100;

% set the timepoints of interest
cfg.toi             = 0.5:0.05:1.5;

% set the time window for TFR analysis: constant length of 200ms
cfg.t_ftimwin       = 0.45 * ones(length(cfg.foi), 1);

% average over trials
cfg.keeptrials      = 'yes';

% pad trials to integer number of seconds, this speeds up the analysis
% and results in a neatly spaced frequency axis
cfg.pad             = 4;
freq_stim                = ft_freqanalysis(cfg, data_stim);
%% Plot Frequencies

cfg                 = [];
cfg.interactive     = 'yes';
cfg.baseline        = [-1 -0.5];
cfg.baselinetype    = 'db';
cfg.zlim            = [-1.5e-27 1.5e-27];
cfg.xlim            = 'maxmin'
cfg.ylim            = 'maxmin'
cfg.showscale       = 'yes'
cfg.showlabels      = 'yes'
cfg.showoutline     = 'yes';
cfg.layout          = 'easycapM11.mat';
cfg.zlim            = 'maxabs';
cfg.colorbar        = 'yes'
ft_multiplotTFR(cfg, freq_baseline);

cfg                 = [];
cfg.interactive     = 'yes';
cfg.baseline        = [0.5 1];
cfg.baselinetype    = 'db';
cfg.zlim            = [-3e-27 3e-27];
cfg.xlim            = 'maxmin'
cfg.ylim            = 'maxmin'
cfg.showscale       = 'yes'
cfg.showlabels      = 'yes'
cfg.showoutline     = 'yes';
cfg.layout          = 'easycapM11.mat';
cfg.zlim            = 'maxabs';
cfg.colorbar        = 'yes'
ft_multiplotTFR(cfg, freq_stim);

cfg = [];
cfg.baseline     = [0.5 1]; 
cfg.baselinetype = 'relchange';
cfg.zlim            = [-3e-27 3e-27];
cfg.xlim            = 'maxmin'
cfg.ylim            = 'maxmin'   
cfg.showlabels   = 'no';	
cfg.layout       = 'easycapM11.mat';
ft_topoplotTFR(cfg, freq_stim);

%% Frequency statistics at the sensor level

%Align time axes
freq_baseline.time = freq_stim.time

%Cluster based permutation test
cfg = [];
%cfg.channel          = []
%cfg.latency          = [0.8 1.4];
cfg.method           = 'montecarlo';
cfg.frequency        = [47 67];
cfg.statistic        = 'ft_statfun_actvsblT';
cfg.correctm         = 'cluster';
cfg.clusteralpha     = 0.05;
cfg.clusterstatistic = 'maxsum';
cfg.minnbchan        = 2;
cfg.tail             = 0;
cfg.clustertail      = 0;
cfg.alpha            = 0.025;
cfg.numrandomization = 500;

% prepare_neighbours determines what sensors may form clusters
cfg.neighbours       = neighbours

ntrials = size(freq_stim.powspctrm,1);
design  = zeros(2,2*ntrials);
design(1,1:ntrials) = 1;
design(1,ntrials+1:2*ntrials) = 2;
design(2,1:ntrials) = [1:ntrials];
design(2,ntrials+1:2*ntrials) = [1:ntrials];

cfg.design   = design;
cfg.ivar     = 1;
cfg.uvar     = 2;

cluster_statistics = ft_freqstatistics(cfg, freq_baseline, freq_stim);
