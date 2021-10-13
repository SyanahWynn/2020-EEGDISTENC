%% DSEEG_SaccadeRejection
% automatically remove saccade related artifacts. Only needed for the
% encoding trials due to the paradigm.

% load the events:
load(fullfile(subjectdata.subjectdir, strcat(subjectdata.subjectnr,'_Raw_AlterMarkers_Events.mat')));
curevents = [40,45]; %fixation, cue and confidence onset
event_arti = [];
for i=1:length(event)
    if ismember(event(i).value, curevents)
        event_arti = [event_arti event(i)];
    elseif ~isempty(event(i).trlnr) % stimulus onset
        event_arti = [event_arti event(i)];
    end
end

%% THIS CHECK NEEDS TO BE ALTERED because of the cue/stim distinction %%
% needed for the check if there is already saccade artifact data
sacartidir     = fullfile(subjectdata.subjectdir, '*Saccade_Artifacts.mat');
sacartidf      = dir(sacartidir);
sacartifiles   = {sacartidf.name};

% make an array with the event values in the current dataset
for i=1:size(event,2)
    events(i)=event(i).value;
end

% loop over the datasets
for d=1:length(curexperiment.datasets)-1 % skip retrieval
    %% Trial count before saccade rejection
    % get the markers for the conditions
    cond_markers = struct2array(curexperiment.data1.l2);
    cond_names = cellfun(@(v) v(2:end), curexperiment.data1l2_name, 'UniformOutput', false);
    % count the conditions
    for i=1:length(cond_markers)
        cur_cnt(i)=sum(ismember(events,cond_markers(i)));
    end  
    % add this count to a table
    Trlcnt_pre = array2table(cur_cnt);
    Trlcnt_pre.Properties.VariableNames = cond_names;   
    
    %% Continue the saccade detection
    cfg = [];
    % check if there is already artifact data
    if ismember(strcat(subjectdata.subjectnr, curexperiment.dataset_name{d}(1:end-4),'_Saccade_Artifacts.mat'),sacartifiles)
        load(fullfile(subjectdata.subjectdir, strcat(subjectdata.subjectnr, curexperiment.dataset_name{d}(1:end-4),'_Saccade_Artifacts.mat')));
        cfg.artfctdef.eog.artifact = artifact_HEOG;
    end
    % if there is no artifact data yet select the artifacts
    if isfield(cfg,'artfctdef') == 0 
        %% SET MARKERS
        loc_markers = zeros(1,length(fieldnames(curexperiment.data3.l1)));
        % get the localizer marker values
        for m=1:length(fieldnames(curexperiment.data3.l1))
            evalc(sprintf('loc_markers(m) = curexperiment.data3.l1.condition%d', m));
        end
        % add the marker offset to the marker values
        loc_markers_org = loc_markers + curexperiment.marker_offset;
        %% CHECK LOCALIZER
        % check if there is localizer data available
        if any(loc_markers(7)==events) && any(loc_markers(8)==events)
            %% DEFINE TRIALS
            cfg                         = [];
            cfg.dataset                 = subjectdata.dataset;
            cfg.trialdef.eventtype      = curexperiment.eventtype;
            cfg.trialdef.eventvalue     = loc_markers_org;
            cfg.trialdef.prestim        = curexperiment.prestim3; % in seconds
            cfg.trialdef.poststim       = curexperiment.poststim3; % in seconds
            cfg.trialfun                = 'ft_trialfun_general';
            % define the trials
            trials_loc                  = ft_definetrial(cfg); 
            % process the trials
            data_loc                    = ft_preprocessing(trials_loc);
            %% COMPUTE HEOG
            cfg                 = [];
            cfg.channel         = {curexperiment.extelec.heog_l, curexperiment.extelec.heog_r};
            cfg.reref           = 'yes';
            cfg.refchannel      = curexperiment.extelec.heog_l;
            data_heog           = ft_preprocessing(cfg,data_loc);
            % rename the heog_r channel into HEOG and discard the other channel
            data_heog.label{2}  = 'HEOG';
            cfg                 = [];
            cfg.channel         = 'HEOG';
            data_heog           = ft_preprocessing(cfg, data_heog);
            %% DEFINE TRESHOLD
            % alter markers
            data_heog.trialinfo = data_heog.trialinfo - curexperiment.marker_offset;
            % loop over the trials
            loc_difvalue = zeros(2,length(data_heog.trialinfo));
            for t=1:length(data_heog.trialinfo)
                % .. store the difference between the minimal and maximal value in the trial
                loc_difvalue(1,t) = peak2peak(data_heog.trial{t});
                loc_difvalue(2,t) = data_heog.trialinfo(t);
            end
            % loop over the unique marker values (conditions)
            loc_meandifvalue = zeros(1,length(loc_markers));
            loc_meandif78 = [];
            for m=loc_markers
                % store the mean difference between the minimal and maximal value
                % in the trial per condition
                loc_meandifvalue(m) = mean(loc_difvalue(1,find(loc_difvalue(2,:)==m)));
            end
            % get the saccades to the target and from the target
            for n=1:length(loc_difvalue)
                if loc_difvalue(2,n)==7 | loc_difvalue(2,n)== 8
                loc_meandif78 = [loc_meandif78 loc_difvalue(1,n) loc_difvalue(1,n+1)];
                end
            end
            % take half of the mean of the 2/3 left and 2/3 right conditions as a threshold
            loc_threshold = mean(loc_meandif78)/2;
        else
            % if there is no localizer data available, make the threshold
            % the average of the thresholds determined by localizer
            loc_threshold = 88.28; % final mean is 88.28
        end
        %% DEFINE SACCADE ARTIFACTS
        % find the index of the HEOG channel
        HEOG_index = find(strcmp(curexperiment.datasets(d).label,'HEOG'));
        % loop over the trials
        t_cue  = logical(data_enc.time{1}>-1 & data_enc.time{1}<0);
        t_stim = logical(data_enc.time{1}>0 & data_enc.time{1}<1);
        enc_difvalue_cue  = zeros(1,length(curexperiment.datasets(d).trial));
        enc_difvalue_stim = zeros(1,length(curexperiment.datasets(d).trial));
        for t=1:length(curexperiment.datasets(d).trial)
            % store the mean difference between the minimal and maximal value
            % in the trial per condition for the HEOG channel 
            enc_difvalue_cue(t) = peak2peak(curexperiment.datasets(d).trial{1,t}(HEOG_index,t_cue)); 
            enc_difvalue_stim(t) = peak2peak(curexperiment.datasets(d).trial{1,t}(HEOG_index,t_stim)); 
        end
        % loop over the difference values
        hc=1;
        hs=1;
        artifact_HEOG_cue = zeros(1,5);
        artifact_HEOG_stim = zeros(1,5);
        for t=1:length(enc_difvalue_cue)
            if enc_difvalue_cue(t) >= loc_threshold
                % if the trial exceeds the threshold, save the sample info in
                % an artifact array
                artifact_HEOG_cue(hc,1:2) = curexperiment.datasets(d).sampleinfo(t,1:2); % sample onset, sample offset
                artifact_HEOG_cue(hc,3:4) = curexperiment.datasets(d).trialinfo(t,1:2); % Marker, trialnr
                artifact_HEOG_cue(hc,5) = t; % trials
                hc=hc+1;
            end
            if enc_difvalue_stim(t) >= loc_threshold
                % if the trial exceeds the threshold, save the sample info in
                % an artifact array
                artifact_HEOG_stim(hs,1:2) = curexperiment.datasets(d).sampleinfo(t,1:2); % sample onset, sample offset
                artifact_HEOG_stim(hs,3:4) = curexperiment.datasets(d).trialinfo(t,1:2); % Marker, original trialnr
                artifact_HEOG_stim(hs,5) = t; % post-preprocessing trialnumber
                hs=hs+1;
            end
        end
        display (sprintf ('\n\nAmount of saccades during cue: %.2f',size(artifact_HEOG_cue,1)))
        display (sprintf ('Amount of saccades during stimulus: %.2f\n\n',size(artifact_HEOG_stim,1)))
        
        %% CHECK SACCADE ARTIFACTS IN CUE WINDOW
        if any(any(artifact_HEOG_cue,2))
            cfg                     = [];
            cfg.trials              = artifact_HEOG_cue(:,5)';
            data_saccade            = ft_redefinetrial(cfg,curexperiment.datasets(d));
            cfg                     = [];
            cfg.artfctdef.visual.artifact = artifact_HEOG_cue(:,1:2);
            if ~isempty(cfg.artfctdef.visual.artifact) 
                cfg.viewmode        = 'vertical';
                cfg.continuous      = 'no';
                cfg.channel         = 'HEOG';
                cfg.ylim            = [-loc_threshold*2 loc_threshold*2];
                %cfg.blocksize       = 15;
                cfg.event           = event_arti;
                cfg.ploteventlabels = 'colorvalue';
                display(sprintf('\nSUBJECT: %s\n\nKEEP ONLY SACCADES IN CUE WINDOW\n', subjectdata.subjectnr));
                % show the data to select the artifacts
                cfg                     = ft_databrowser(cfg,data_saccade);
                artifacts               = cfg.artfctdef.visual.artifact;
            else
                artifacts = artifact_HEOG;
            end
            %% UPDATE SACCADE LIST
            artifact_HEOG2 = artifacts;
            for i=1:size(artifacts,1)
                r = max(find(artifacts(i,1)>=artifact_HEOG_cue(:,1)));
                artifact_HEOG2(i,3:5) = artifact_HEOG_cue(r,3:5);
            end
            artifact_HEOG_cue =  artifact_HEOG2;
            clear r
            clear h
            clear i
            clear HEOG_index
            clear artifact_HEOG2
        end
        %% CHECK SACCADE ARTIFACTS IN STIM WINDOW
        if any(any(artifact_HEOG_stim,2))
            cfg                     = [];
            cfg.trials              = artifact_HEOG_stim(:,5)';
            data_saccade            = ft_redefinetrial(cfg,curexperiment.datasets(d));
            cfg                     = [];
            cfg.artfctdef.visual.artifact = artifact_HEOG_stim(:,1:2);
            if ~isempty(cfg.artfctdef.visual.artifact) 
                cfg.viewmode        = 'vertical';
                cfg.continuous      = 'no';
                cfg.channel         = 'HEOG';
                cfg.ylim            = [-loc_threshold*2 loc_threshold*2];
                %cfg.blocksize       = 15;
                cfg.event           = event_arti;
                cfg.ploteventlabels = 'colorvalue';
                display(sprintf('\nSUBJECT: %s\n\nKEEP ONLY SACCADES IN STIM WINDOW\n', subjectdata.subjectnr));
                % show the data to select the artifacts
                cfg                     = ft_databrowser(cfg,data_saccade);
                artifacts               = cfg.artfctdef.visual.artifact;
            else
                artifacts = artifact_HEOG;
            end
            %% UPDATE SACCADE LIST
            artifact_HEOG2 = artifacts;
            for i=1:size(artifacts,1)
                r = max(find(artifacts(i,1)>=artifact_HEOG_stim(:,1)));
                artifact_HEOG2(i,3:5) = artifact_HEOG_stim(r,3:5);
            end
            artifact_HEOG_stim =  artifact_HEOG2;
            clear r
            clear h
            clear i
            clear HEOG_index
            clear artifact_HEOG2
        end
    end

    clear h*
    clear t
    clear m
    %% ARTIFACT REJECTION
    % cue window
    cfg=[]; 
    cfg.artfctdef.reject = 'complete'; % this rejects complete trials, use 'partial' if you want to do partial artifact rejection
    if sum(artifact_HEOG_cue)==0
        artifact_HEOG_cue = [];
    end
    cfg.artfctdef.eog.artifact = artifact_HEOG_cue;
    data_no_artifacts_cue = ft_rejectartifact(cfg,curexperiment.datasets(d));
    display(sprintf('\n%d TRIALS REMOVED DUE TO SACCADES\n',size(artifact_HEOG_cue,1)))
    % stim window
    cfg=[]; 
    cfg.artfctdef.reject = 'complete'; % this rejects complete trials, use 'partial' if you want to do partial artifact rejection
    if sum(artifact_HEOG_stim)==0
        artifact_HEOG_stim = [];
    end
    cfg.artfctdef.eog.artifact = artifact_HEOG_stim;
    data_no_artifacts_stim = ft_rejectartifact(cfg,curexperiment.datasets(d));
    display(sprintf('\n%d TRIALS REMOVED DUE TO SACCADES\n',size(artifact_HEOG_stim,1)))

    %% Trial count after saccade rejection
    % CUE
    % count the conditions
    clear cur_cnt
    if ~isempty(artifact_HEOG_cue)
        for i=1:length(cond_markers)
            cur_cnt(i)=sum(ismember(artifact_HEOG_cue(:,3),cond_markers(i)));
        end  
    else
        cur_cnt = zeros(1,length(cond_markers));
    end
    % add this count to a table
    Trlcnt_cue_post = array2table(table2array(Trlcnt_pre)-cur_cnt);
    Trlcnt_cue_post.Properties.VariableNames = cond_names; 
    clear cur_cnt
    % STIM
    % count the conditions
    clear cur_cnt
    if ~isempty(artifact_HEOG_stim)
        for i=1:length(cond_markers)
            cur_cnt(i)=sum(ismember(artifact_HEOG_stim(:,3),cond_markers(i)));
        end  
    else
        cur_cnt = zeros(1,length(cond_markers));
    end    
    % add this count to a table
    Trlcnt_stim_post = array2table(table2array(Trlcnt_pre)-cur_cnt);
    Trlcnt_stim_post.Properties.VariableNames = cond_names; 
     
    clear cond_markers cond_names cur_cnt

    %% SAVE THE DATA
    evalc(sprintf('%s_cue = data_no_artifacts_cue', curexperiment.datasets_names{d}));
    evalc(sprintf('%s_stim = data_no_artifacts_stim', curexperiment.datasets_names{d}));
    save([subjectdata.subjectdir filesep subjectdata.subjectnr curexperiment.dataset_name{d}(1:end-4) '_Saccade_Artifacts_CueWindow.mat'],'artifact_HEOG_cue');
    save([curexperiment.datafolder_input filesep subjectdata.subjectnr curexperiment.dataset_name{d}(1:end-4) '_Saccade_Artifacts_CueWindow' date '.mat'],'artifact_HEOG_cue');
    save([subjectdata.subjectdir filesep subjectdata.subjectnr curexperiment.dataset_name{d}(1:end-4) '_Saccade_Artifacts_StimulusWindow.mat'],'artifact_HEOG_stim');
    save([curexperiment.datafolder_input filesep subjectdata.subjectnr curexperiment.dataset_name{d}(1:end-4) '_Saccade_Artifacts_StimulusWindow' date '.mat'],'artifact_HEOG_stim');
    save([subjectdata.subjectdir filesep subjectdata.subjectnr curexperiment.dataset_name{d} '_cue_SaccadesRejected.mat'], (strcat(curexperiment.datasets_names{d},'_cue')));
    save([subjectdata.subjectdir filesep subjectdata.subjectnr curexperiment.dataset_name{d} '_stim_SaccadesRejected.mat'], (strcat(curexperiment.datasets_names{d},'_stim')));
    
    if exist('loc_threshold','var')
        if d==1
            load(outputfile_stats) % load the info if it is the first loop
        end
        evalc(sprintf('Data.saccades.%s.CueWindow(f,:) = size(artifact_HEOG_cue,1);',curexperiment.dataset_name{d}(2:end)));
        evalc(sprintf('Data.saccades.%s.StimulusWindow(f,:) = size(artifact_HEOG_stim,1);',curexperiment.dataset_name{d}(2:end)));
        Data.sac_threshold(f,:) = loc_threshold;
        if f==1
            Data.TrlCnt.preSaccade = Trlcnt_pre;
            Data.TrlCnt.postSaccade.CueWindow = Trlcnt_cue_post;
            Data.TrlCnt.postSaccade.StimulusWindow = Trlcnt_stim_post;
        else
            Data.TrlCnt.preSaccade = [Data.TrlCnt.preSaccade;Trlcnt_pre];
            Data.TrlCnt.postSaccade.CueWindow = [Data.TrlCnt.postSaccade.CueWindow;Trlcnt_cue_post];
            Data.TrlCnt.postSaccade.StimulusWindow = [Data.TrlCnt.postSaccade.StimulusWindow;Trlcnt_stim_post];
        end
        save(outputfile_stats,'Data')
    end
end

clear artifact_HEOG
clear enc_difvalue
clear loc_difvalue
clear loc_markers
clear loc_meandifvalue
clear loc_threshold
clear data_loc
clear data_no_artifacts
clear Data
clear sacartidir
clear sacartidf
clear sacartifiles
clear trials_loc
clear data_heog
% update the datasets
evalc(curexperiment.define_datasets);