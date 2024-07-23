%Step 1: Load and Inspect Events
% Add FieldTrip to MATLAB path
addpath('C:\Users\melis\Documents\Trento\Verona_Experiment\YS_visGamma_20240716\eeg\');
ft_defaults;
% Load EEG data
hdr = ft_read_header('YS-VisGAMMA_def.eeg');
dat = ft_read_data('YS-VisGAMMA_def.eeg', 'header', hdr);
% Load your dataset and inspect events
cfg = [];
cfg.dataset = 'YS-VisGAMMA_def.eeg';  % Adjust if needed
hdr = ft_read_header(cfg.dataset);
events = ft_read_event(cfg.dataset);


% Display the events to identify the correct event type and value
disp(events);
%%
%Step 2: Define Trials Based on Specific Conditions

% Extract event values and convert them to character vectors
event_values = cellfun(@num2str, {events.value}, 'UniformOutput', false);
event_samples = [events.sample];

% Display the unique event values to ensure correct reading
unique_event_values = unique(event_values);
disp('Unique event values:');
disp(unique_event_values);

% Define trials based on identified events
stimulus_code = 'S  4';  % Onset of grating stimulus
correct_response_code = ['S 16', 'S 48'];  % Correct response, speed change detected
prestim_time = 1.0;  % Pre-stimulus time in seconds
total_trial_duration = 3.8;  % Total trial duration in seconds

% Initialize an empty trl matrix
trl = [];

% Iterate through the events to define trials
for i = 1:length(events)
    if strcmp(event_values{i}, stimulus_code)
        % Check if there is a correct response 'S 16' after the stimulus
        for j = i+1:length(events)
            if strcmp(event_values{j}, correct_response_code)
                % Define the trial
                begsample = event_samples(i) - round(prestim_time * hdr.Fs);
                endsample = event_samples(i) + round((total_trial_duration - prestim_time) * hdr.Fs);
                offset = -round(prestim_time * hdr.Fs);
                trl = [trl; begsample, endsample, offset, str2double(correct_response_code(end-1:end))];
                break;
            end
        end
    end
end

% Display the trl matrix for debugging
disp('Trial matrix (trl):');
disp(trl);

cfg = [];
cfg.dataset = 'YS-VisGAMMA_def.eeg';  % Adjust if needed
cfg.trl = trl;
%%
%Step 3: Preprocess the Data
% Preprocess the data
cfg.continuous = 'yes';
cfg.channel = 'all';

% Apply a band-pass filter to avoid instability
cfg.bpfilter = 'yes';
cfg.bpfreq = [1 45];  % Band-pass filter from 1 to 45 Hz
cfg.bpfilttype = 'fir';  % Use FIR filter instead of IIR
cfg.bpfiltord = fix(3 * hdr.Fs / min(cfg.bpfreq));  % Set the order of the filter

% Line noise attenuation
cfg.dftfilter = 'yes';
cfg.dftfreq = [50];  % Attenuate 50 Hz line noise

% Additional preprocessing settings
cfg.demean = 'yes';
cfg.baselinewindow = [-0.2 0];

% Process the data
data_preprocessed1 = ft_preprocessing(cfg);
disp('Preprocessing complete.');
%%
%Step 4: Artifact Rejection
% Automated artifact rejection with ICA
cfg = [];
cfg.method = 'fastica';
comp = ft_componentanalysis(cfg, data_preprocessed);

% Visualize components and manually reject artifacts
cfg = [];
cfg.component = [1:20];  % Adjust based on inspection of components
cfg.layout = 'easycapM1.lay';  % Adjust according to your layout file
ft_databrowser(cfg, comp);

% Remove artifacts based on the previous visualization step
cfg = [];
cfg.component = [1 2 5];  % Example components to reject, adjust based on your inspection
data_clean = ft_rejectcomponent(cfg, comp, data_preprocessed);

disp('Artifact rejection complete.');
%%
%Step 5: Downsample the Data
% Downsample the data to 300 Hz
cfg = [];
cfg.resamplefs = 300;
data_downsampled = ft_resampledata(cfg, data_clean);
disp('Downsampling complete.');
%%
%Step 6: Time-Frequency Analysis
% Time-frequency analysis
cfg = [];
cfg.method = 'mtmconvol';
cfg.taper = 'hanning';
cfg.output = 'pow';
cfg.foi = 1:1:90;  % Frequencies from 1 to 90 Hz
cfg.toi = -1.0:0.05:2.8;  % Time of interest from -1.0 to 2.8 s (relative to grating onset)
cfg.t_ftimwin = 0.45 * ones(size(cfg.foi));  % Sliding window of 450 ms
TFR = ft_freqanalysis(cfg, data_downsampled);
disp('Time-frequency analysis complete.');
%%
%Step 7: Source Analysis Using Beamforming
% Source analysis using beamforming
cfg = [];
cfg.method = 'dics';
cfg.frequency = 60;  % Example frequency
cfg.grid = ft_prepare_sourcemodel(cfg, headmodel);
cfg.headmodel = headmodel;
source = ft_sourceanalysis(cfg, TFR);
disp('Source analysis complete.');
%%
%Step 8: Connectivity Analysis
% Connectivity analysis
cfg = [];
cfg.method = 'coh';
cfg.complex = 'absimag';
conn = ft_connectivityanalysis(cfg, source);
disp('Connectivity analysis complete.');

%%
%Step 9: Plot Results
% Plot time-frequency representation
cfg = [];
cfg.baseline = [-0.5 0];
cfg.baselinetype = 'relchange';
cfg.zlim = 'maxabs';
ft_singleplotTFR(cfg, TFR);
disp('Time-frequency plot complete.');

% Plot source analysis
cfg = [];
cfg.method = 'surface';
cfg.funparameter = 'pow';
cfg.maskparameter = cfg.funparameter;
cfg.funcolormap = 'jet';
cfg.projmethod = 'nearest';
cfg.surfinflated = 'surface_inflated_both.mat';
ft_sourceplot(cfg, source);
disp('Source plot complete.');

% Plot connectivity
cfg = [];
cfg.parameter = 'cohspctrm';
cfg.xlim = [1 90];
cfg.ylim = [1 90];
ft_connectivityplot(cfg, conn);
disp('Connectivity plot complete.');
