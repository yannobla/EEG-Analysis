addpath ('C:\Users\melis\Documents\Trento\Verona_Experiment\YS_visGamma_20240716\eeg\')
cfg = [];
cfg.dataset = 'YS-VisGAMMA_def.eeg';

cfg.trialdef.prestim        = 1;
cfg.trialdef.poststim       = 2.8;
cfg.trialdef.std_triggers   = 1;
cfg.trialdef.stim_triggers  = ['S 4'];
cfg.trialdef.odd_triggers   = 2;
cfg.trialdef.rsp_triggers   = [256 4096];
cfg.trialfun                = 'trialfun_oddball_stimlocked';
cfg                         = ft_definetrial(cfg);

cfg.continuous              = 'yes';
cfg.hpfilter                = 'no';
cfg.detrend                 = 'no';
cfg.continuous              = 'yes';
cfg.demean                  = 'yes';
cfg.dftfilter               = 'yes';
cfg.dftfreq                 = [50 100];
cfg.channel                 = 'EEG';

cfg.reref                   = 'yes'; % recorded with left mastoid
cfg.refchannel              = 'all';

data_EEG                    = ft_preprocessing(cfg);
save data_EEG data_EEG -v7.3