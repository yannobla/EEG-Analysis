restoredefaultpath
addpath 'C:\Users\melis\Documents\MATLAB\fieldtrip-20240731'
addpath ('C:\Users\melis\Documents\MATLAB\Scripts')
ft_defaults


% Define the directory containing the BrainVision files
data_dir                = 'C:\Users\melis\Documents\Trento\Verona_Experiment\YS.visGamma.20241029'; 
preproc_dir              = fullfile(data_dir, 'Preprocessed');  % Directory to save processed files
    if ~exist(preproc_dir, 'dir')
        mkdir(preproc_dir);  % Create output directory if it doesn't exist
    end

file_list               = dir(fullfile(data_dir, '*.vhdr'));  % Get a list of all .vhdr files

%% First Loop: Load, preprocess, and save filtered data
for file_idx = 1:length(file_list)
    % Get the current .vhdr file and construct associated file paths
    vhdr_file           = fullfile(data_dir, file_list(file_idx).name);  % Full path to .vhdr file
    [~, base_name, ~]   = fileparts(vhdr_file);
    eeg_file            = fullfile(data_dir, [base_name, '.eeg']);  % Full path to corresponding .eeg file

    % Extract the base name and replace underscores with spaces
    name                = strrep(base_name, '_', ' ');  % Replace '_' with ' ' in the base file name
    fprintf('Processing file (loading and preprocessing): %s (Name: %s)\n', vhdr_file, name);  % Debugging output
        %% segment data into trials with correct trialfunction
        cfg                 = [];
        cfg.trialfun        = 'trialfun_visgam'; 
        cfg.headerfile      = vhdr_file;  % Use dynamically assigned vhdr_file
        cfg.datafile        = eeg_file;  % Use dynamically assigned eeg_file
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
    % Save the filtered data
    save(fullfile(preproc_dir, [base_name, '_preproc.mat']), 'resampdata');
end
%% Second Loop: Load processed data and Clean
for file_idx = 1:length(file_list)
     % Get the current file's base name
    [~, base_name, ~]   = fileparts(file_list(file_idx).name);

    % Load the filtered data
    filtered_file       = fullfile(preproc_dir, [base_name, '_preproc.mat']);
        if ~isfile(filtered_file)
            fprintf('Filtered file not found for %s. Skipping.\n', base_name);
            continue;
        end
    load(filtered_file, 'preproc_data');  % Load saved filtered_data

    fprintf('Processing file (Cleaning): %s\n', base_name);  % Debugging output
               
        %% artifact rejection
        cfg                 = [];
        cfg.demean          = 'yes';
        cfg.detrend         = 'yes';
        brodata             = ft_databrowser(cfg, resampdata);
        cfg.artifactdef     = brodata.artfctdef;
        cfg.artfctdef.reject= 'partial';
        data_clean          = ft_rejectartifact(cfg, resampdata);
        %% badchan repair
        cfg                 = [];
        cfg.demean          = 'yes';
        cfg.detrend         = 'yes';
        ft_databrowser(cfg, data_clean)
        badchannel          = input('badchannel');
        
        cfg = [];
        cfg.channel         = 'all' ;
        cfg.method          = 'triangulation';
        cfg.template        = 'easycap64ch-avg_neighb.mat';
        cfg.layout          = 'easycapM11.mat';
        neighbours          = ft_prepare_neighbours(cfg, data_clean);
        
        cfg = [];
        cfg.badchannel      = badchannel;
        cfg.method          = 'average';
        cfg.neighbours      = neighbours;
        data_fixed          = ft_channelrepair(cfg,data_clean);

    % Save the filtered data
    cleaned_dir              = fullfile(data_dir, 'Cleaned');  % Directory to save processed files
    if ~exist(cleaned_dir, 'dir')
        mkdir(cleaned_dir);  % Create output directory if it doesn't exist
    end
    save(fullfile(cleaned_dir, [base_name, '_cleaned.mat']), 'data_fixed');
end
        %% ICA decomposition
        cfg                 = [];
        cfg.method          = 'fastica';
        cfg.numcomponent    = 64; %why does it stop after 52 components?
        data_comp           = ft_componentanalysis(cfg, data_fixed); % using the data without atypical artifacts
        %% Identifying artifactual components
        cfg                 = [];
        cfg.layout          = 'acticap-64ch-standard2.mat';
        cfg.component       = 1:30;
        cfg.marker          = 'off';
        ft_topoplotIC(cfg, data_comp)
            
        % remove the bad components and backproject the data
        cfg                 = [];
        cfg.component       = [1 2 3 4 5 6 7 8 9 12 13]; % to be removed component(s)
        data_postica        = ft_rejectcomponent(cfg, data_comp, data_fixed );
        
        save ('workspace_YS_VISGAM_2_EXP')
                  
        %% Freqanalysis
        %Filtering
        cfg = [];
        cfg.channel         = (1:64);
        cfg.detrend         = 'yes';
        cfg.demean          = 'yes';
        cfg.dftfilter       = 'yes';
        cfg.dftfreq         = [50, 100];
        cfg.baseline        = [-0.5 -0.05];
        data_preproc2       = ft_preprocessing(cfg,data_postica);
        %Redefinetrials
        cfg                 = [];
        cfg.toilim          = [-1.0 2.8];
        cfg.minlength       = 'maxperlen'; % this ensures all resulting trials are equal length
        data_stim           = ft_redefinetrial(cfg, data_preproc2);
        
        cfg                 = [];
        cfg.keeptrials      = 'yes';
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
        freq_stim           = ft_freqanalysis(cfg, data_stim);
        %% Plot Frequencies
        
        % Questionable Layout Creation 
        hdr                 = ft_read_header('YS_VISGAM_2_EXP.eeg');
        cfg                 = [];
        cfg.layout          = 'easycapM1.mat';
        layout.label        = hdr.label';
        layout.pos          = 'standard_1020.elc';
        layout              = ft_prepare_layout(cfg);
        
        % Plot
        cfg = [];
        cfg.baseline        = [-0.5 0]; 
        cfg.baselinetype    = 'relchange';
        %cfg.zlim           = [-3e-27 3e-27];
        cfg.xlim            = [0 2];
        cfg.ylim            = 'maxmin'; 
        cfg.showlabels      = 'yes';	
        cfg.layout          = layout;
        %ft_topoplotTFR(cfg, freq_stim);
        ft_multiplotTFR(cfg, freq_stim);
        ft_singleplotTFR(cfg, freq_stim)
    
