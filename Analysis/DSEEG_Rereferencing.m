%% DSEEG_Rereferencing
% rereference the EEG data

% loop through the datasets
for d=1:length(curexperiment.datasets)
    cfg             = [];
    cfg.reref       = 'yes';  
    cfg.channel     = 'all';
    cfg.refchannel  = 'all'; % the average of these channels is used as the new reference
    % exclude or change channels if needed
    if strcmp(subjectdata.subjectnr,'105')
        cfg.channel     = {'all', '-F3'}; % remove channel F3
    end
    cfg.implicitref = curexperiment.extelec.impref;            % the implicit (non-recorded) reference channel is added to the data representation
    % rereference the data
    data_reref      = ft_preprocessing(cfg,curexperiment.datasets(d));
    % save the rereferenced data
    display(sprintf('\nSaving rereferenced data'))
    evalc(sprintf('%s = data_reref', curexperiment.datasets_names{d}));
    save([subjectdata.subjectdir filesep subjectdata.subjectnr curexperiment.dataset_name{d} '_Rereferenced.mat'], curexperiment.datasets_names{d});
    clear data_reref
end
% update the datasets
evalc(curexperiment.define_datasets);