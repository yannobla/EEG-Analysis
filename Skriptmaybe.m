cfg = [];
cfg.dataset = 'YS-VisGAMMA_def.eeg';
cfg.trialfun                = 'ft_trialfun_general'; % this is the default
cfg.trialdef.eventtype      = 'Stimulus';
cfg.trialdef.eventvalue     = ['S 4']; % the values of the stimulus trigger for the three conditions

cfg.trialdef.prestim        = 1; % in seconds
cfg.trialdef.poststim       = 2.8; % in seconds

cfg = ft_definetrial(cfg);
