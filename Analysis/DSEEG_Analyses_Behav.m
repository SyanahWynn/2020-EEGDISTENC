%% DSEEGpic_BehavAnalysis

%% GENERAL SET-UP
xlsxdir      = fullfile(curexperiment.datafolder_inputbehav, 'BehavData');
xlsxdf       = dir(xlsxdir);
xlsxfiles    = {xlsxdf.name};

fprintf('\nBEHAVIORAL ANALYSES\n')

phases = {'Enc', 'Ret'};
% get the participant numbers
p=1;
for i=1:length(xlsxfiles)
    if length(xlsxfiles{i})>2
        if strcmp(xlsxfiles{i}(1:3),'Enc')
            ppns{p} = xlsxfiles{i}(5:8);
            p=p+1;
        end
    end
end
clear i
clear p

%% LOOP OVER PARTICIPANTS OR NOT
curl = '';
% start loop or determine current ppn
loop = true
if loop
    fprintf('Loop true')
    strt = 1:length(ppns);
else
    fprintf('Loop false')
    strt = f;
end
for p=strt
    cur_ppn = ppns{p};
    fprintf(curl);
    curtxt = sprintf('\nPARTICIPANT %d of %d: %s',p,length(ppns),cur_ppn);
    fprintf(curtxt)
    curl = repmat('\b',1,length(curtxt));
    % select files of this participant
    ppnfiles = xlsxfiles(logical(~cellfun('isempty',strfind(xlsxfiles,cur_ppn))));    
    for cur_phase=1:length(phases)
        % select the files for this memory phase
        phafile = ppnfiles(logical(~cellfun('isempty',strfind(ppnfiles,phases{cur_phase}))));
        
        %% LOAD FILE
        inputdir = cell2mat(fullfile(xlsxdir,phafile));
        [~,~,cur_data]=xlsread(inputdir);
        
        %% GET THE VARIABLES
        for i=1:size(cur_data,2)
            evalc(sprintf('ppn.%s = cur_data(curexperiment.Ntrials_prac+1:end,i);',curexperiment.behav.vars{cur_phase,i}));
        end
        clear cur_data
        clear i
        clear inputdir
        
        %% RECODE VARIABLES
        evalc(sprintf('ppn.%s_resp = cell2mat(ppn.%s_resp)',lower(phases{cur_phase}),lower(phases{cur_phase})));
        evalc(sprintf('ppn.%s_RT = cell2mat(ppn.%s_RT)',lower(phases{cur_phase}),lower(phases{cur_phase})));
        evalc(sprintf('ppn.%s_trialtype = cell2mat(ppn.%s_trialtype)',lower(phases{cur_phase}),lower(phases{cur_phase})));
        evalc(sprintf('ppn.%s_pic_left = ppn.pic_left',lower(phases{cur_phase})));
        evalc(sprintf('ppn.%s_pic_right = ppn.pic_right',lower(phases{cur_phase})));
        
        if cur_phase==2
            ppn.conf_resp=cell2mat(ppn.conf_resp);
            ppn.conf_RT=cell2mat(ppn.conf_RT);
        end
        
        % gender
        ppn.gender = ppn.gender{1};
        % ppn
        ppn.ppn = ppn.ppn{1};
        % age
        ppn.age = ppn.age{1};
        % Verhage
        ppn.edu = ppn.edu{1};
        % agegroup
        if ppn.age >40
            ppn.group = 'OA';
        elseif ppn.age <40
            ppn.group = 'YA';
        end
        
        %% ANALYSES            
        % Encoding/Retrieval No Responses
        if cur_phase==1
            evalc(sprintf('ppn.%s_noresp = sum(ppn.%s_RT==0)',lower(phases{cur_phase}),lower(phases{cur_phase})));
        elseif cur_phase==2
            evalc(sprintf('ppn.%s_noresp = numel(find(ppn.conf_resp==99))',lower(phases{cur_phase})));
            evalc(sprintf('ppn.%s_noresp = numel(find(ppn.%s_resp==99))',lower(phases{cur_phase-1}),lower(phases{cur_phase-1})));
        end

        % Encoding/Retrieval RTs
        evalc(sprintf('ppn.%s_meanRT = mean(nonzeros(ppn.%s_RT))',lower(phases{cur_phase}),lower(phases{cur_phase})));
        
        % Encoding responses
        if cur_phase==1
            % check whether the first letter of the picture is uppercase.
            % If uppercase, then picture was manmade.
            mm_l = cell2mat(isstrprop(cellfun(@(x) x(1),ppn.enc_pic_left,'un',0),'upper'));
            mm_r = cell2mat(isstrprop(cellfun(@(x) x(1),ppn.enc_pic_right,'un',0),'upper'));
            % uncover type of target picture
            % 1=LDl, 2=LDr, 3=HDl, 4=HDr
            for i=1:length(ppn.enc_pic_left)
                if (ppn.enc_trialtype(i)==1 | ppn.enc_trialtype(i)==3)... %target left
                        & ~mm_l(i) %nature
                    enc_corr(i,:) = 37;
                elseif (ppn.enc_trialtype(i)==1 | ppn.enc_trialtype(i)==3)... %target left
                        & mm_l(i) %manmade
                    enc_corr(i,:) = 39;
                elseif (ppn.enc_trialtype(i)==2 | ppn.enc_trialtype(i)==4)... %target right
                        & ~mm_r(i) %nature
                    enc_corr(i,:) = 37;
                elseif (ppn.enc_trialtype(i)==2 | ppn.enc_trialtype(i)==4)... %target right
                        & mm_r(i) %manmade
                    enc_corr(i,:) = 39;
                end
            end
            % encoding accuracy
            enc_acc = zeros(size(ppn.enc_resp)); %incorrect
            enc_acc(enc_corr==ppn.enc_resp) = 1; %correct
            enc_acc(ppn.enc_resp==99) = NaN; %noresp
            ppn.enc_hr = sum(enc_acc==1)/(sum(enc_acc==0)+sum(enc_acc==1));
            clear enc_* mm_*
        end
        
        if cur_phase==2
            % Create conf rating
            for i=1:length(ppn.conf_resp)
                if ppn.ret_resp(i) == 37 && ppn.conf_resp(i) == 37
                    ppn.conf_rating(i) = 11; % not confident old
                elseif ppn.ret_resp(i) == 37 && ppn.conf_resp(i) == 40
                    ppn.conf_rating(i) = 12; % bit confident old
                elseif ppn.ret_resp(i) == 37 && ppn.conf_resp(i) == 39
                    ppn.conf_rating(i) = 13; % very confident old
                elseif ppn.ret_resp(i) == 39 && ppn.conf_resp(i) == 37
                    ppn.conf_rating(i) = 21; % not confident new
                elseif ppn.ret_resp(i) == 39 && ppn.conf_resp(i) == 40
                    ppn.conf_rating(i) = 22; % bit confident new
                elseif ppn.ret_resp(i) == 39 && ppn.conf_resp(i) == 39
                    ppn.conf_rating(i) = 23; % very confident new
                else
                    ppn.conf_rating(i) = 99;
                end
            end
            ppn.conf_rating=ppn.conf_rating';

            % Creat old/new accuracy score
            for i=1:length(ppn.conf_resp)
                if ppn.ret_resp(i) == 37 && (ppn.ret_trialtype(i) == 1 || ppn.ret_trialtype(i) == 2)
                    ppn.on_acc(i) = 111; % hit baseline
                elseif ppn.ret_resp(i) == 37 && (ppn.ret_trialtype(i) == 3 || ppn.ret_trialtype(i) == 4)
                    ppn.on_acc(i) = 112; % hit target
                elseif ppn.ret_resp(i) == 37 && (ppn.ret_trialtype(i) == 30 || ppn.ret_trialtype(i) == 40)
                    ppn.on_acc(i) = 113; % hit distractor
                elseif ppn.ret_resp(i) == 39 && (ppn.ret_trialtype(i) == 1 || ppn.ret_trialtype(i) == 2)
                    ppn.on_acc(i) = 211; % miss baseline
                elseif ppn.ret_resp(i) == 39 && (ppn.ret_trialtype(i) == 3 || ppn.ret_trialtype(i) == 4)
                    ppn.on_acc(i) = 212; % miss target
                elseif ppn.ret_resp(i) == 39 && (ppn.ret_trialtype(i) == 30 || ppn.ret_trialtype(i) == 40)
                    ppn.on_acc(i) = 213; % miss distractor
                elseif ppn.ret_resp(i) == 39 && (ppn.ret_trialtype(i) == 91 || ppn.ret_trialtype(i) == 92)
                    ppn.on_acc(i) = 22; % cj
                elseif ppn.ret_resp(i) == 37 && (ppn.ret_trialtype(i) == 91 || ppn.ret_trialtype(i) == 92)
                    ppn.on_acc(i) = 12; % fa 
                else
                    ppn.on_acc(i) = 99;
                end
            end
            ppn.on_acc=ppn.on_acc';
            
            % Create old/new acc + confidence score
            for i=1:length(ppn.on_acc)
                if ppn.conf_rating(i) == 13 && ppn.on_acc(i) == 111
                    ppn.acc_conf(i) = 1113; % HitHCb
                elseif ppn.conf_rating(i) == 13 && ppn.on_acc(i) == 112
                    ppn.acc_conf(i) = 1123; % HitHCt
                elseif ppn.conf_rating(i) == 13 && ppn.on_acc(i) == 113
                    ppn.acc_conf(i) = 1133; % HitHCd                 
                elseif ppn.conf_rating(i) == 12 && ppn.on_acc(i) == 111
                    ppn.acc_conf(i) = 1112; % HitLCb
                elseif ppn.conf_rating(i) == 12 && ppn.on_acc(i) == 112
                    ppn.acc_conf(i) = 1122; % HitLCt
                elseif ppn.conf_rating(i) == 12 && ppn.on_acc(i) == 113
                    ppn.acc_conf(i) = 1132; % HitLCd                   
                elseif ppn.conf_rating(i) == 11 && ppn.on_acc(i) == 111
                    ppn.acc_conf(i) = 1111; % HitNCb
                elseif ppn.conf_rating(i) == 11 && ppn.on_acc(i) == 112
                    ppn.acc_conf(i) = 1121; % HitNCt
                elseif ppn.conf_rating(i) == 11 && ppn.on_acc(i) == 113
                    ppn.acc_conf(i) = 1131; % HitNCd                   
                elseif ppn.on_acc(i) == 211 && ppn.conf_rating(i) ~= 99
                    ppn.acc_conf(i) = 211; % Missb
                elseif ppn.on_acc(i) == 212 && ppn.conf_rating(i) ~= 99
                    ppn.acc_conf(i) = 212; % Misst
                elseif ppn.on_acc(i) == 213 && ppn.conf_rating(i) ~= 99
                    ppn.acc_conf(i) = 213; % Missd
                elseif ppn.conf_rating(i) == 23 && ppn.on_acc(i) == 22
                    ppn.acc_conf(i) = 223; % CRHC
                elseif ppn.conf_rating(i) == 22 && ppn.on_acc(i) == 22
                    ppn.acc_conf(i) = 222; % CRLC
                elseif ppn.conf_rating(i) == 21 && ppn.on_acc(i) == 22
                    ppn.acc_conf(i) = 221; % CRNC
                elseif ppn.on_acc(i) == 12 && ppn.conf_rating(i) ~= 99
                    ppn.acc_conf(i) = 12; % FA
                else
                    ppn.acc_conf(i) = 99;
                end
            end

            % Retrieval counts
            ppn.count_HitHCb = sum(logical(ppn.acc_conf == 1113));
            ppn.count_HitHCt = sum(logical(ppn.acc_conf == 1123));
            ppn.count_HitHCd = sum(logical(ppn.acc_conf == 1133));
            ppn.count_HitLCb = sum(logical(ppn.acc_conf == 1112));
            ppn.count_HitLCt = sum(logical(ppn.acc_conf == 1122));
            ppn.count_HitLCd = sum(logical(ppn.acc_conf == 1132));
            ppn.count_HitNCb = sum(logical(ppn.acc_conf == 1111));
            ppn.count_HitNCt = sum(logical(ppn.acc_conf == 1121));
            ppn.count_HitNCd = sum(logical(ppn.acc_conf == 1131));
                        
            % new encoding subsequent memory response
            % loop over ret trials
            ppn.encDm = zeros(curexperiment.Ntrials_enc,1);
            Dmt = zeros(curexperiment.Ntrials_enc,1);
            Dmd = zeros(curexperiment.Ntrials_enc,1);
            for i=1:length(ppn.ret_pic_left)
                % loop over enc trials
                for e=1:length(ppn.enc_pic_left)
                    % find match between enc and ret trials
                    if strcmp(ppn.ret_pic_left{i},ppn.enc_pic_left{e}) &&...
                            strcmp(ppn.ret_pic_right{i},ppn.enc_pic_right{e})
                        if (ppn.ret_trialtype(i) == 1 || ppn.ret_trialtype(i) == 2) && ...
                            ppn.ret_trialtype(i)==ppn.enc_trialtype(e)                          
                            if ppn.conf_resp(i)==99 || ppn.enc_resp(e)==99 || ppn.ret_resp(i)==99
                            % adjust to no response
                            ppn.encDm(e)=99;
                            % make Dm responses baseline
                            elseif ppn.on_acc(i) == 111
                                ppn.encDm(e)=111; % subs hit baseline
                            elseif ppn.on_acc(i) == 211
                                ppn.encDm(e)=211; % subs miss baseline
                            end
                        else
                            if ppn.conf_resp(i)==99 || ppn.enc_resp(e)==99 || ppn.ret_resp(i)==99
                                % adjust to no response
                                ppn.encDm(e)=99;
                            % make Dm responses target
                            elseif ppn.on_acc(i) == 112 
                                Dmt(e)=112; % subs hit target
                            elseif ppn.on_acc(i) == 212 
                                Dmt(e)=212; % subs miss target
                            elseif ppn.on_acc(i) == 113 
                                Dmd(e)=113; % subs hit distractor
                            elseif ppn.on_acc(i) == 213 
                                Dmd(e)=213; % subs miss distractor
                            end
                        end
                    end
                end
            end
            % combine subs tar and dis
            for i=1:length(ppn.encDm)
                if ppn.encDm(i) ~= 99 && ppn.encDm(i)~=111 && ppn.encDm(i)~=211
                    ppn.encDm(i) = str2double(strcat(num2str(Dmt(i)),num2str(Dmd(i))));
                end
            end
            clear i
            clear e
            clear Dm*
            
            % Encoding counts
            ppn.count_SubsHitb = sum(logical(ppn.encDm == 111));
            ppn.count_SubsMissb = sum(logical(ppn.encDm == 211));
            ppn.count_SubsTHDH = sum(logical(ppn.encDm == 112113));
            ppn.count_SubsTHDM = sum(logical(ppn.encDm == 112213));
            ppn.count_SubsTMDH = sum(logical(ppn.encDm == 212113));
            ppn.count_SubsTMDM = sum(logical(ppn.encDm == 212213));
            
            % d'
            ppn.hit_rate_b = length(ppn.on_acc(logical(ppn.on_acc==111)))/length(ppn.on_acc(logical(ppn.on_acc==111 | ppn.on_acc==211)));
            ppn.hit_rate_t = length(ppn.on_acc(logical(ppn.on_acc==112)))/length(ppn.on_acc(logical(ppn.on_acc==112 | ppn.on_acc==212)));
            ppn.hit_rate_d = length(ppn.on_acc(logical(ppn.on_acc==113)))/length(ppn.on_acc(logical(ppn.on_acc==113 | ppn.on_acc==213)));
            ppn.hit_rateHC_b = length(ppn.acc_conf(logical(ppn.acc_conf == 1113)))/...
                length(ppn.acc_conf(logical(ppn.acc_conf == 1113 | ppn.acc_conf ==211)));
            ppn.hit_rateHC_t = length(ppn.acc_conf(logical(ppn.acc_conf == 1123)))/...
                length(ppn.acc_conf(logical(ppn.acc_conf == 1123 | ppn.acc_conf ==212)));   
            ppn.fa_rate_all = length(ppn.on_acc(logical(ppn.on_acc==12)))...
                /length(ppn.on_acc(logical(ppn.on_acc==12 | ppn.on_acc==22)));
            
            zhr_b = norminv(ppn.hit_rate_b);
            zhr_t = norminv(ppn.hit_rate_t);
            zhr_d = norminv(ppn.hit_rate_d);
            zfar_all = norminv(ppn.fa_rate_all);
            zhr_bHC = norminv(ppn.hit_rateHC_b);
            zhr_tHC = norminv(ppn.hit_rateHC_t);

            ppn.d_prime_b = zhr_b-zfar_all;
            ppn.d_prime_t = zhr_t-zfar_all;
            ppn.d_prime_d = zhr_d-zfar_all;
            ppn.d_prime_bHC = zhr_bHC-zfar_all;
            ppn.d_prime_tHC = zhr_tHC-zfar_all;

            clear zfar*
            clear zhr*  

        end
    end
    clear cur_phase
    clear phafile
    
    % save data of ppn
    evalc(sprintf('all_ppns.ppn%d = ppn;',ppn.ppn));
    
    ppn=rmfield(ppn,{'trialnr','pic_left','pic_right','enc_trialtype','enc_resp','ret_ROC',...
        'enc_RT','ret_trialtype','ret_resp','ret_RT','conf_resp','conf_RT','conf_rating','on_acc',...
        'enc_pic_left','enc_pic_right','ret_pic_left','ret_pic_right','acc_conf', 'encDm'});
    %display(sprintf('%d',ppn.ppn))
    curtable=struct2table(ppn);
    
    if ~loop
        display(sprintf('\n%d',ppn.ppn))
        curtable
    end
    
    if loop
        if p==1
            table_behav = curtable;
        else
            table_behav = [table_behav;curtable];
        end
    else
        table_behav = curtable;
        subjectdata.behavdata=ppn;
    end
    clear cur_ppn
    clear ppnfiles
    clear curtable
    clear tr_types
    clear roctable
    clear ppn
    
end
clear xlsx*
clear phases
clear curl
clear i
clear ppns

% Data.BehavRes= table_behav;
% Data.ROC.baseline = table_roc_baseline;
% Data.ROC.target = table_roc_target;
% Data.ROC.distractor = table_roc_distractor;


if loop
    if exist(outputfile_stats,'file')
        load(outputfile_stats)
    end
    Data.BehavRes= table_behav;
    save(outputfile_stats,'Data')
else
    if exist(outputfile,'file')
       load(outputfile)
    end
    Data.BehavRes(f,:)= table_behav;
    save(outputfile,'Data')
end
clear table_behav

% % Data.BehavRes(p,:)= table_behav;
% Data.ROC.baseline(p,:) = table_roc_baseline;
% Data.ROC.target(p,:) = table_roc_target;
% Data.ROC.distractor(p,:) = table_roc_distractor;
% clear table_behav
clear table_roc*
clear roctable*

clear p loop strt

% % Grand Average ROC plot
% OA_ind = any(ismember(Data.BehavRes.group,'O'),2);
% YA_ind = any(ismember(Data.BehavRes.group,'Y'),2);
% 
% x_b_o = reshape(mean(table2array(Data.ROC.baseline(OA_ind,:)),1),[5,2]);
% x_t_o = reshape(mean(table2array(Data.ROC.target(OA_ind,:)),1),[5,2]);
% x_d_o = reshape(mean(table2array(Data.ROC.distractor(OA_ind,:)),1),[5,2]);
% x_b_y = reshape(mean(table2array(Data.ROC.baseline(YA_ind,:)),1),[5,2]);
% x_t_y = reshape(mean(table2array(Data.ROC.target(YA_ind,:)),1),[5,2]);
% x_d_y = reshape(mean(table2array(Data.ROC.distractor(YA_ind,:)),1),[5,2]);
% 
% figure;
% plot(x_b_o(:,1),x_b_o(:,2),'-ob'); hold on;
% plot(x_t_o(:,1),x_b_o(:,2),'-og'); hold on;
% plot(x_d_o(:,1),x_b_o(:,2),'-ok'); 
% xlim([0 1]);ylim([0 1]);
% title('OAs')
% figure;
% plot(x_b_y(:,1),x_b_y(:,2),'-ob'); hold on;
% plot(x_t_y(:,1),x_b_y(:,2),'-og'); hold on;
% plot(x_d_y(:,1),x_b_y(:,2),'-ok'); 
% xlim([0 1]);ylim([0 1]);
% title('YAs')
% clear x*
% clear OA_ind
% clear YA_ind
