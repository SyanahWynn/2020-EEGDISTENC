%% Main_Analyses_preprocessing

%% SUBJECT DATA
% get the name of the current file and store it in the subjectdata
[~,filename,~]          = fileparts(char(files(f)));
subjectdata.subjectnr   = filename;
subjectdata.subjectdir  = fullfile(curexperiment.datafolder_output, sprintf('%s',curexperiment.name,'_', subjectdata.subjectnr));

subjectdata.dataset     = char(fullfile(curexperiment.datafolder_input, files(f)));
if ~exist(subjectdata.subjectdir, 'dir')
  mkdir(subjectdata.subjectdir);
end

fprintf('SUBJECT: %s\n',subjectdata.subjectnr)

% Check if the analyses have been done already for this subject
matdir      = fullfile(subjectdata.subjectdir, '*.mat');
matdf       = dir(matdir);
matfiles    = {matdf.name};
% search for specific matfiles, and see if they are found
impdat      = sum(contains(matfiles,'RawDataMarkers.mat'));
altmardat   = sum(contains(matfiles,'AlterMarkers.mat'));
deftrdat    = sum(contains(matfiles,'_Trials.mat'));
rerefdat    = sum(contains(matfiles,'Rereferenced.mat'));
vheogdat    = sum(contains(matfiles,'VEOGHEOG.mat'));
filtdat     = sum(contains(matfiles,'Filtered.mat'));
artdat      = sum(contains(matfiles,'ArtiRemoved.mat'));
artfindat   = sum(contains(matfiles,'ArtiRemovedFin.mat'));
icadat      = sum(contains(matfiles,'PostICA.mat'));
sacdat      = sum(contains(matfiles,'SaccadesRejected'));
redefdat    = sum(contains(matfiles,'ReDefTrials.mat'));
preprodat   = sum(contains(matfiles,'PreProcessed.mat'));
interpdat   = sum(contains(matfiles,'InterpData.mat'));

% do (remaining) analyses if needed
if preprodat < length(curexperiment.datasets_names)
    %% IMPORT DATA
    if impdat ~= 1 
        %load in the data
        fprintf('\nREADING DATA\n\n');
        cfg             = [];
        cfg.dataset     = subjectdata.dataset;
        cfg.channel = {'all', '-EXG1-1','-EXG2-1','-EXG3-1','-EXG4-1','-EXG5-1','-EXG6-1','-EXG6-1','-EXG7-1','-EXG8-1',...
                            '-66','-67','-68','-69','-70','-71','-72'};
        data_org        = ft_preprocessing(cfg);
        fs              = data_org.fsample;
        % save the data
        save([subjectdata.subjectdir filesep subjectdata.subjectnr '_RawData.mat'],'data_org');
        save([subjectdata.subjectdir filesep subjectdata.subjectnr '_RawFS.mat'],'fs');

        % "define" the trials to adjust the markers
        % trl = NxM, m1 = sample indices of start of the trial, m2 =
        % sample indices of the end of the trial, m3 = offet of the
        % trigger with respect to the trial.
        cfg.trialdef.eventtype  = curexperiment.eventtype;
        cfg.trialfun            = 'ft_trialfun_general';
        data_markers            = ft_definetrial(cfg);
        save([subjectdata.subjectdir filesep subjectdata.subjectnr '_RawDataMarkers.mat'],'data_markers');
    else
        fprintf('\nLOADING DATA\n\n');
        load(fullfile(subjectdata.subjectdir, strcat(subjectdata.subjectnr,'_RawDataMarkers.mat')));
        load(fullfile(subjectdata.subjectdir, strcat(subjectdata.subjectnr,'_RawData.mat')));
        load(fullfile(subjectdata.subjectdir, strcat(subjectdata.subjectnr,'_RawFS.mat')));
    end
    clear impdat

    %% ADD TRIALNUMBERS
    if altmardat ~= length(curexperiment.datasets_names)+1
        sprintf('\nADDING TRIALNUMBERS\n');
        cfg                = [];
        cfg.markers        = curexperiment.markers;
        cfg.data           = data_markers;
        cfg.curexperiment  = curexperiment;
        cfg.offset         = curexperiment.marker_offset;
        if exist(outputfile,'file')
           load(outputfile)
        end
        % call trial count function
        evalc(sprintf('[data_markers,Data.trls.ppn%s]= trlnr(cfg);',subjectdata.subjectnr));
        save(outputfile,'Data')
    end

    %% ALTER MARKERS
    if altmardat ~= length(curexperiment.datasets_names)+1
        % run a script which corrects marker 'errors'
        fprintf('\nALTERING MARKERS\n\n');
        eval([curexperiment.name '_AlterMarkers'])
        curexperiment.marker_offset         = org_offset;
    end
    clear altmardat

    %% DEFINE TRIALS
    if deftrdat ~= length(curexperiment.datasets_names)
        % run a script that defines the trials
        fprintf('\nDEFINING TRIALS\n\n');
        eval([curexperiment.name '_DefineTrials'])
    else
        fprintf('\nLOADING TRIAL DATA\n\n');
        for d=1:length(curexperiment.datasets_names)
            if exist(fullfile(subjectdata.subjectdir, strcat(subjectdata.subjectnr,curexperiment.dataset_name{d},'_Trials.mat')), 'file') == 2
                load(fullfile(subjectdata.subjectdir, strcat(subjectdata.subjectnr,curexperiment.dataset_name{d},'_Trials.mat')));
            end
        end
        evalc(curexperiment.define_datasets);
    end
    clear deftrdat
    clear data_markers

    %% RE-REFERENCING
    if rerefdat <1
        % run a script that rereferences the data
        fprintf('\nREREFERENCING\n\n');
        eval([curexperiment.name '_Rereferencing'])
    elseif vheogdat ~= length(curexperiment.datasets)
        fprintf('\nLOADING REREFERENCED DATA\n\n');
        for d=1:length(curexperiment.datasets)
            load(fullfile(subjectdata.subjectdir, strcat(subjectdata.subjectnr,curexperiment.dataset_name{d},'_Rereferenced.mat')));
        end
        evalc(curexperiment.define_datasets);
    end
    clear rerefdat

    %% VEOG & HEOG
    if vheogdat <1
        % run a script that defines VEOG HEOG channels
        fprintf('\nDETERMINING VEOG HEOG\n\n');
        eval([curexperiment.name '_VEOGHEOG'])
    elseif filtdat ~= length(curexperiment.datasets)
        fprintf('\nLOADING VEOG&HEOG DATA\n\n');
        for d=1:length(curexperiment.datasets)
            load(fullfile(subjectdata.subjectdir, strcat(subjectdata.subjectnr,curexperiment.dataset_name{d},'_VEOGHEOG.mat')));
        end
        if eval(sprintf('isempty(%s)',curexperiment.datasets_names{3}))
            evalc(sprintf('%s=rmfield(%s,''hdr'');',curexperiment.datasets_names{3},curexperiment.datasets_names{3}));
        end
        evalc(curexperiment.define_datasets);
    end
    clear vheogdat

    %% FILTERING
    if filtdat <1 
        % run a script that filters the data
        fprintf('\nFILTERING\n\n');
        eval([curexperiment.name '_Filtering'])
    else
        fprintf('\nLOADING FILTERED DATA\n\n');
        for d=1:length(curexperiment.datasets)
            load(fullfile(subjectdata.subjectdir, strcat(subjectdata.subjectnr,curexperiment.dataset_name{d},'_Filtered.mat')));
        end
        if eval(sprintf('isempty(%s)',curexperiment.datasets_names{3}))
            evalc(sprintf('%s=rmfield(%s,''hdr'')',curexperiment.datasets_names{3},curexperiment.datasets_names{3}))
        end
        % add hdr to empty struct
        if eval(sprintf('isempty(%s)',curexperiment.datasets_names{3}))
            evalc(sprintf('%s = struct(''hdr'',{},''label'',{},''time'',{},''trial'',{},''fsample'',{},''sampleinfo'',{},''trialinfo'',{},''cfg'',{});',curexperiment.datasets_names{3}));
        end
        evalc(curexperiment.define_datasets);
    end
    clear filtdat  
    clear data_filter data_org  

     %% ARTIFACT REJECTION
     if artdat ~= length(curexperiment.datasets)
        % run a script that rejects the non-ocular artifacts
        fprintf('\nARTIFACT REJECTION\n');
        eval([curexperiment.name '_ArtifactRejection'])
     else
        fprintf('\nLOADING ARTIFACT REJECTED DATA\n');
        for d=1:length(curexperiment.datasets)
            load(fullfile(subjectdata.subjectdir, strcat(subjectdata.subjectnr,curexperiment.dataset_name{d},'_ArtiRemoved.mat')));
        end
        evalc(curexperiment.define_datasets);
    end
    clear artdat

    %% OCULAR CORRECTION
    if icadat ~= length(curexperiment.datasets)
        % run a script that identifies ocular components
        fprintf('\nOCULAR CORRECTION\n');
        eval([curexperiment.name '_ICA'])
    else
        fprintf('\nLOADING OCULAR CORRECTED DATA\n');
        for d=1:length(curexperiment.datasets)
            load(fullfile(subjectdata.subjectdir, strcat(subjectdata.subjectnr,curexperiment.dataset_name{d},'_PostICA.mat')));
        end
        evalc(curexperiment.define_datasets);
    end
    clear icadat

    %% SACCADE DETECTION
    if sacdat ~= 99 % change later
        % run a script that automatically removes trials containing saccades
        fprintf('\nSACCADE DETECTION\n');
        eval([curexperiment.name '_SaccadeRejection'])
    else
        fprintf('\nLOADING SACCADE DETECTED DATA\n');
        for d=length(curexperiment.datasets)-1 % skip retrieval
            load(fullfile(subjectdata.subjectdir, strcat(subjectdata.subjectnr,curexperiment.dataset_name{d},'_SaccadesDetected.mat')));
        end
        evalc(curexperiment.define_datasets);
    end
    clear sacdat

    %% END OF PREPROCESSING
    % delete all files previously needed for preprocessing
    PreProcdir      = fullfile(subjectdata.subjectdir, sprintf('*.mat'));
    PreProcdf       = dir(PreProcdir);
    PreProcfiles    = {PreProcdf.name};
    for PreProc=1:length(PreProcfiles)
        if ~all(ismember('Artifact',PreProcfiles{PreProc}))
            if ~all(ismember('ArtiRemoved',PreProcfiles{PreProc}))
                if ~all(ismember('ArtiRemoved_EOG',PreProcfiles{PreProc}))
                    if ~all(ismember('Events',PreProcfiles{PreProc}))
                        %if ~all(ismember('Filtered',PreProcfiles{PreProc}))
                            if ~all(ismember('Components',PreProcfiles{PreProc}))
                                if ~all(ismember('dataICA',PreProcfiles{PreProc}))
                                    eval(sprintf('delete %s', (fullfile(subjectdata.subjectdir,PreProcfiles{PreProc}))))
                                end
                            end
                        %end
                    end
                end
            end
        end
    end            
    fprintf('\nEND OF PREPROCESSING\n');
    % save the preprocessed data
    for d=1:length(curexperiment.datasets)+1 %enc is devided in cue and stim window now
        if d==1
            fprintf('\nSAVING PREPROCESSED %s\n',curexperiment.datasets_names{1});
            eval(sprintf('%s.cfg.previous=[];',strcat(curexperiment.datasets_names{1},'_cue')));
            save([subjectdata.subjectdir filesep subjectdata.subjectnr curexperiment.dataset_name{1} '_cue_PreProcessed.mat'], strcat(curexperiment.datasets_names{1},'_cue'));
        elseif d==2
            fprintf('\nSAVING PREPROCESSED %s\n',curexperiment.datasets_names{1});
            eval(sprintf('%s.cfg.previous=[];',strcat(curexperiment.datasets_names{1},'_stim')));
            save([subjectdata.subjectdir filesep subjectdata.subjectnr curexperiment.dataset_name{1} '_stim_PreProcessed.mat'], strcat(curexperiment.datasets_names{1},'_stim'));
        elseif d==3
            fprintf('\nSAVING PREPROCESSED %s\n',curexperiment.datasets_names{d-1});
            eval(sprintf('%s.cfg.previous=[];',curexperiment.datasets_names{d-1}));
            save([subjectdata.subjectdir filesep subjectdata.subjectnr curexperiment.dataset_name{d-1} '_PreProcessed.mat'], curexperiment.datasets_names{d-1});
        end
    end
    clear *dat data_*
end     