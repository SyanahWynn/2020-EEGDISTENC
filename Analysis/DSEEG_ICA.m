%% FamRecEEG ICA
% perform ICA to remove ocular components

% needed for the check if ICA has already been done before
compdir     = fullfile(subjectdata.subjectdir, '*Components.mat');
compdf      = dir(compdir);
compfiles   = {compdf.name};
icdir     = fullfile(subjectdata.subjectdir, '*dataICA.mat');
icdf      = dir(icdir);
icfiles   = {icdf.name};

% loop through the datasets
for d=1:length(curexperiment.datasets)
    cfg = [];
    % check if ICA has already been done before
    if ismember(strcat(subjectdata.subjectnr,curexperiment.dataset_name{d}(1:end-4), '_Components.mat'),compfiles)
        load(fullfile(subjectdata.subjectdir, strcat(subjectdata.subjectnr, curexperiment.dataset_name{d}(1:end-4), '_Components.mat')));
        cfg.component = components;
    end
    if ismember(strcat(subjectdata.subjectnr,curexperiment.dataset_name{d}, '_dataICA.mat'),icfiles)
        load(fullfile(subjectdata.subjectdir, strcat(subjectdata.subjectnr, curexperiment.dataset_name{d}, '_dataICA.mat')));         
    end
    %% ONLY ENCODING FOR NOW !!!
    if d==1
        % if there is no previous ICA data, create new data
        if exist('ic_data','var')==0
            cfg.channel     = 'EEG';
            ic_data         = ft_componentanalysis(cfg,curexperiment.datasets(d));
        end
        respICA = 0;
        while ~respICA
            if isfield(cfg,'component') == 0 || any(cfg.component == 0)
                cfg             = [];
                cfg.layout      = 'biosemi32.lay';
                cfg.viewmode    = 'component';
                cfg.continuous  = 'yes';
                cfg.blocksize   = 15;
                cfg.channels    = 1:10;
                % watch the ICA components
                display(sprintf('\nSUBJECT: %s', subjectdata.subjectnr));
                display(sprintf('\n%s\n', curexperiment.dataset_name{d}));   
                ft_databrowser(cfg,ic_data);
                display(sprintf('Press a button when done inspecting the components'));
                pause
                % determine the ICA components to remove
                prompt          = '\nWhich components do you wish to remove? (format [1 2 3])\n';
                cfg.component   = input(prompt);
                components      = cfg.component;
                display(sprintf('Ok'));
            end
            % remove the components
            data_iccleaned      = ft_rejectcomponent(cfg, ic_data);
            % add the VEOG and HEOG data
            cfg                 = [];
            cfg.channel         = {'HEOG', 'VEOG'};
            data_vheog          = ft_preprocessing(cfg, curexperiment.datasets(d));
            cfg                 = [];
            data_iccleaned      = ft_appenddata(cfg, data_vheog, data_iccleaned);
            cfg                 = [];
            cfg.viewmode        = 'vertical';
            cfg.continuous      = 'yes';
            cfg.blocksize       = 15;
            cfg.ploteventlabels = 'colorvalue';
            % look at the differences before and after ICA correction
            ft_databrowser(cfg,data_iccleaned);
            ft_databrowser(cfg,curexperiment.datasets(d));
            display(sprintf('\nSUBJECT: %s', subjectdata.subjectnr));
            display(sprintf('Press a button when done inspecting the data'));
            pause
            % determine whether the componet removal was successful
            prompt          = '\nHappy with the result of the ICA? (yes=1, no=0)\n';
            respICA         = input(prompt);
            display(sprintf('Ok'));
            if respICA == 1
                respICA = true; 
            else
                cfg.component   = 0;
                respICA = false;
            end
        end
    else
        components = [];
        ic_data   = [];
        data_iccleaned = curexperiment.datasets(d);
        data_iccleaned = rmfield(data_iccleaned,'hdr');
    end
    % save the artifact data
    evalc(sprintf('%s = data_iccleaned', curexperiment.datasets_names{d}));
    save([subjectdata.subjectdir filesep subjectdata.subjectnr curexperiment.dataset_name{d}(1:end-4) '_Components.mat'],'components');
    save([curexperiment.datafolder_input filesep subjectdata.subjectnr curexperiment.dataset_name{d}(1:end-4) '_Components_' date '.mat'],'components');
    save([subjectdata.subjectdir filesep subjectdata.subjectnr curexperiment.dataset_name{d} '_dataICA.mat'], 'ic_data');
    save([curexperiment.datafolder_input filesep subjectdata.subjectnr curexperiment.dataset_name{d} '_dataICA_' date '.mat'], 'ic_data');
    save([subjectdata.subjectdir filesep subjectdata.subjectnr curexperiment.dataset_name{d} '_PostICA.mat'], curexperiment.datasets_names{d});
            
    clear components
    clear data_iccleaned
    clear ic_data
end
% update the datasets
evalc(curexperiment.define_datasets); 
    