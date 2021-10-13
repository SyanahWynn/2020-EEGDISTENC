%% DSEEG_DefineTrials

% load the altered events:
load(fullfile(subjectdata.subjectdir, strcat(subjectdata.subjectnr,'_Raw_AlterMarkers_Events.mat')));
load(fullfile(subjectdata.subjectdir, strcat(subjectdata.subjectnr,'_Raw_EncAlterMarkers.mat')));
load(fullfile(subjectdata.subjectdir, strcat(subjectdata.subjectnr,'_Raw_RetAlterMarkers.mat')));

cfg                         = [];
%% ENCODING
cfg.dataset                 = subjectdata.dataset;
cfg.trialdef.eventtype      = curexperiment.eventtype;
cfg.trialdef.eventvalue     = enc_stim_new;
cfg.trialdef.prestim        = curexperiment.prestim1; % in seconds
cfg.trialdef.poststim       = curexperiment.poststim1; % in seconds
cfg.event                   = event;
cfg.trialfun                = 'ft_trialfun_multitrl';
% define the trials
trials_enc                  = ft_definetrial(cfg); 
% process the trials
data_enc                    = ft_preprocessing(trials_enc);
save([subjectdata.subjectdir filesep subjectdata.subjectnr curexperiment.dataset_name{1} '_Trials.mat'], curexperiment.datasets_names{1}); % first dataset

%% RETRIEVAL
cfg.dataset                 = subjectdata.dataset;
cfg.trialdef.eventtype      = curexperiment.eventtype;
cfg.trialdef.eventvalue     = ret_stim_new;
cfg.trialdef.prestim        = curexperiment.prestim2; % in seconds
cfg.trialdef.poststim       = curexperiment.poststim2; % in seconds
cfg.event                   = event;
cfg.trialfun                = 'ft_trialfun_multitrl';
% define the trials
trials_ret                  = ft_definetrial(cfg);
% process the trials
data_ret = ft_preprocessing(trials_ret);
save([subjectdata.subjectdir filesep subjectdata.subjectnr curexperiment.dataset_name{2} '_Trials.mat'], curexperiment.datasets_names{2}); % second dataset
% trialdefined datasets
evalc(curexperiment.define_datasets);
clear trials_enc
clear trials_ret
clear enc_stim_new
clear ret_stim_new

