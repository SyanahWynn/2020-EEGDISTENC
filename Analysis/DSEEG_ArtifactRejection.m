%% DSEEG_ArtifactRejection

% load in events
load(fullfile(subjectdata.subjectdir, strcat(subjectdata.subjectnr,'_Raw_AlterMarkers_Events.mat')));
load(fullfile(subjectdata.subjectdir, strcat(subjectdata.subjectnr,'_Raw_EncAlterMarkers.mat')));
load(fullfile(subjectdata.subjectdir, strcat(subjectdata.subjectnr,'_Raw_RetAlterMarkers.mat')));
curevents = [40,45,70,80,enc_stim_new',ret_stim_new']; %fixation, cue, stimulus and confidence onset
event_arti = [];
for i=1:length(event)
    if ismember(event(i).value, curevents)
        event_arti = [event_arti event(i)];
    end
end

% needed for the check if there is already artifact data
artidir     = fullfile(subjectdata.subjectdir, '*Artifacts.mat');
artidf      = dir(artidir);
artifiles   = {artidf.name};

% loop over the datasets
for d=1:length(curexperiment.datasets)
    cfg = [];
    % check if there is already artifact data
    if ismember(strcat(subjectdata.subjectnr, curexperiment.dataset_name{d}(1:end-4), '_Artifacts.mat'),artifiles)
        load(fullfile(subjectdata.subjectdir, strcat(subjectdata.subjectnr, curexperiment.dataset_name{d}(1:end-4), '_Artifacts.mat')));
        cfg.artfctdef.visual.artifact = artifacts;
    end
    % ONLY ENCODING FOR NOW !!!
    if d==1
        cfg.viewmode        = 'vertical';
        cfg.continuous      = 'yes';
        cfg.renderer        = 'painters';
        cfg.channelcolormap = colormap(curexperiment.plotcolors); 
        if length(data_enc.label) == 36
            cfg.colorgroups     = curexperiment.plotgroups;
        end
        cfg.blocksize       = 15;
        cfg.event           = event_arti;
        cfg.ploteventlabels = 'colorvalue';
        display(sprintf('\nSUBJECT: %s', subjectdata.subjectnr));
        display(sprintf('DATASET: %s\n', curexperiment.dataset_name{d}(2:end)));
        % show the data to select the artifacts
        cfg                     = ft_databrowser(cfg,curexperiment.datasets(d));
        artifacts               = cfg.artfctdef.visual.artifact;
    else
        artifacts               = [];
    end
    % reject the artifacts
    cfg.artfctdef.reject        = 'complete';
    cleandata                   = ft_rejectartifact(cfg,curexperiment.datasets(d));
    % save the artifact data
    evalc(sprintf('%s = cleandata', curexperiment.datasets_names{d}));
    save([subjectdata.subjectdir filesep subjectdata.subjectnr curexperiment.dataset_name{d} '_ArtiRemoved.mat'], curexperiment.datasets_names{d});
    save([subjectdata.subjectdir filesep subjectdata.subjectnr curexperiment.dataset_name{d}(1:end-4) '_Artifacts.mat'],'artifacts');
    save([curexperiment.datafolder_input filesep subjectdata.subjectnr curexperiment.dataset_name{d}(1:end-4) '_Artifacts_' date '.mat'],'artifacts');
    clear artifacts
    clear cleandata
end
% update the datasets
evalc(curexperiment.define_datasets);