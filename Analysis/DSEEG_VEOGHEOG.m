%% DSEEG_VEOGHEOG
% define the VEOG and HEOG electrodes

for d=1:length(curexperiment.datasets)
    % this is a lenghty version of just substracton HEOG_L from HEOG_R,
    % this can just be done in future analyses, instead of this rereference
    % workaround (when bipolar recordings are done directly, like in
    % Biosemi).
    %% COMPUTE HEOG
    cfg                 = [];
    cfg.channel         = {curexperiment.extelec.heog_l, curexperiment.extelec.heog_r};
    cfg.reref           = 'yes';
    cfg.refchannel      = curexperiment.extelec.heog_l;
    data_heog           = ft_preprocessing(cfg,curexperiment.datasets(d));
    % rename the heog_r channel into HEOG and discard the other channel
    data_heog.label{2}  = 'HEOG';
    cfg                 = [];
    cfg.channel         = 'HEOG';
    data_heog           = ft_preprocessing(cfg, data_heog);
    %% COMPUTE VEOG
    cfg                 = [];
    cfg.channel         = {curexperiment.extelec.veog_t, curexperiment.extelec.veog_b};
    cfg.refchannel      = curexperiment.extelec.veog_t;
    if strcmp(subjectdata.subjectnr,'105') && d==2
        cfg.channel     = {'EXG3'  'EXG5'}; % remove channel F3
    end
    cfg.reref           = 'yes';  
    data_veog           = ft_preprocessing(cfg,curexperiment.datasets(d));
    % rename the veog_b channel into VEOG and discard the other channel
    data_veog.label{2}  = 'VEOG';
    cfg                 = [];
    cfg.channel         = 'VEOG';
    data_veog           = ft_preprocessing(cfg, data_veog); 
    %% COMBINE
    % combine the three raw data structures into a single representation
    % (rereferenced data, HEOG & VEOG)
    cfg                 = [];
    new_data            = ft_appenddata(cfg, data_heog, data_veog, curexperiment.datasets(d));
    % discard channels we do not need anymore
    cfg                 = [];
    cfg.channel         = [1:curexperiment.Nelectrodes+2 curexperiment.Nelectrodes+curexperiment.Nextelectrodes+3:length(new_data.label)]; 
    new_data            = ft_preprocessing(cfg, new_data);
    % save the VEOG&HEOG-ed data
    evalc(sprintf('%s = new_data', curexperiment.datasets_names{d}));
    save([subjectdata.subjectdir filesep subjectdata.subjectnr curexperiment.dataset_name{d} '_VEOGHEOG.mat'], curexperiment.datasets_names{d});
    clear data_heog
    clear data_veog
    clear new_data
end
% update the datasets
evalc(curexperiment.define_datasets);
