%% MAIN ANALYSES
% DSEEG made with fieldtrip-20160401

%%%%%%%%%%%%
%% SET-UP %%
%%%%%%%%%%%%
fprintf('\nMAIN SET-UP\n\n')
Main_Analyses_setup;

%%%%%%%%%%%%%%%%%%%
%% PREPROCESSING %%
%%%%%%%%%%%%%%%%%%%

%% LOOP OVER SUBJECTS
fprintf('\n###################\n')
fprintf('## PREPROCESSING ##\n')
fprintf('###################\n')
file_n=length(files);
for f=1:file_n
    fprintf('\nPREPROCESSING\n\n')
    Main_Analyses_preprocessing
end

%%%%%%%%%%%%%%
%% ANALYSES %%
%%%%%%%%%%%%%%

%% LOOP OVER SUBJECTS
fprintf('\n##############\n')
fprintf('## ANALYSES ##\n')
fprintf('##############\n')
for f=1:file_n
    %% SUBJECT DATA
    % get the name of the current file and store it in the subjectdata
    [~,filename,~]          = fileparts(char(files(f)));
    subjectdata.subjectnr   = filename;
    fprintf('\n\nSubject: %s\n',subjectdata.subjectnr)
    subjectdata.subjectses  = '1';
    subjectdata.subjectdir  = fullfile(curexperiment.datafolder_output, sprintf('%s',curexperiment.name,'_', subjectdata.subjectnr));
    % run a function that determines subject group and appropriate folder
    eval([curexperiment.name '_CreateAnalysesFolder'])

    % Check if the preprocessing has been done already for this subject
    matdir      = fullfile(subjectdata.subjectdir, '*.mat');
    matdf       = dir(matdir);
    matfiles    = {matdf.name};
    % search for specific matfiles, and see if they are found
    preprodat   = sum(contains(matfiles,'PreProcessed.mat')); 
    clear mat*
    
    %% CHECK IF THERE IS PREPROCESSED DATA
    preproc_check = length(curexperiment.datasets_names);
    if preprodat >= preproc_check
        % Check if the analyses have been done already for this subject
        matdir                  = fullfile(curexperiment.analysis_loc, sprintf('%s',filename,'*.mat'));
        matdf                   = dir(matdir);
        matfiles                = {matdf.name};
        plotdir                 = fullfile(subjectdata.subjectdir, 'Plots');
        plotdf                  = dir(plotdir);
        plotfiles               = {plotdf.name};
        % search for specific matfiles, and see if they are found
        erp                     = sum(contains(matfiles,'ERP'));
        ep                      = sum(contains(matfiles,'Evoked'));
        ip                      = sum(contains(matfiles,'Induced'));
        tp                      = sum(contains(matfiles,'Total'));
        plt                     = sum(contains(plotfiles,'.jpg'));
        % set variable to check wheter all analyses have been done before
        if erp+ep+ip+tp == sum(struct2array(curexperiment.Nanalyses))
            ana = false;
        else
            ana = true;
        end       
        clear mat* filename plot*
        
        % if not all analyses have been done, do so
        if ana
            %% LOAD THE DATA
            fprintf('\nLOADING FULLY PREPROCESSED DATA\n');
            for d=1:length(curexperiment.dataset_name)
                fprintf('\nLOADING %d of %d\n',d,length(curexperiment.dataset_name));
                load(fullfile(subjectdata.subjectdir, strcat(subjectdata.subjectnr,curexperiment.dataset_name{d},'_PreProcessed.mat')));
            end
            % define datasets
            evalc(curexperiment.define_datasets);        
    
            %% TRIAL COUNT
            fprintf('\nTRIAL COUNT\n');
            eval([curexperiment.name '_TrialCount'])    

            if any(strcmp('pow',curexperiment.analyses))
                %% TIME-FREQUENCY ANALYSES ON SUBJECT LEVEL
                %run a script that does time-frequency analyses on subject level
                if tp ~= curexperiment.Nanalyses.tp 
                    fprintf('\nTIME-FREQUENCY ANALYSES\n');
                    eval([curexperiment.name '_TF_Analyses'])
                end
            end
            clear pow ip ep
        end
        clear ana  
    end
end

%%%%%%%%%%%%%%%%%%%%
%% GRAND AVERAGES %%
%%%%%%%%%%%%%%%%%%%%

if any(strcmp(curexperiment.analyses,'pow'))
    %% TIME-FREQUENCY GRAND AVERAGE
    %run a script that does time-frequency analyses across subjects
    eval([curexperiment.name '_TF_Analyses_GrandAverage'])
end

%run a script that does behavioral analyses
loop=true;eval([curexperiment.name '_Analyses_Behav'])

clear curpc plotgroups