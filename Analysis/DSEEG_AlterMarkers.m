%% DSEEG ALTER MARKERS
% Checks whether enc_start, enc_stop, ret_start and ret_Stop markers are in
% the data. When this is not the case it adds them to it. Also it makes
% another column which contains the original markers.

% add a column for the original EEG markers
tmp=cell(size(data_markers.event));
[data_markers.event(:).original_marker] =deal(tmp{:});
clear tmp
i=1;
while i < length(data_markers.event)+1
   % exclude all non-marker rows
   if isequal(cellstr(data_markers.event(i).type),cellstr(curexperiment.eventtype)) == 0
      % delete non-marker row
       data_markers.event(i) = [];
   else
       % add a column with the original markers
        data_markers.event(i).original_marker = data_markers.event(i).value - curexperiment.marker_offset;
       % go to the next row
        i = i +1;         
   end
end
clear i

% REMOVE PRACTICE TRIALS
% find the index of the first stimulus onset
frst=find(~cellfun('isempty',{data_markers.event.trlnr}),1,'first');
loc_end=1;
% find the index of the end of the localizer
for i=1:frst
    if data_markers.event(i).original_marker==30
        loc_end = i;
    end
end
if frst > 3 % assumes that there are practice trials present then remove their markers
    % check assumption
    if ~ismember(data_markers.event(frst-3).original_marker, cell2mat(table2array(curexperiment.original_markers('Start Encoding','original_marker'))))
        error('ERROR removal of practice trials encoding')
    end
    for i=loc_end+1:frst-4
        data_markers.event(i).original_marker=0;
    end
end
% find the last encoding trial
for i=1:size(data_markers.event,2)
    if data_markers.event(i).trlnr == curexperiment.Ntrials_enc
        lst = i;
        break
    end
end
frst2 = find(~cellfun('isempty',{data_markers.event(lst+1:end).trlnr}),1,'first')+lst-2;
% check assumption
if ~ismember(data_markers.event(frst2).original_marker, cell2mat(table2array(curexperiment.original_markers('Start Retrieval','original_marker'))))
    error('ERROR removal of practice trials retrieval')
end
for i=lst+3:frst2-1
   data_markers.event(i).original_marker=0;
end   
clear i

% count all markers
curexperiment.original_markers.cur_count = [];
curexperiment.original_markers.cur_count(1)=0;
for i=1:length(data_markers.event) %skip the first row    
    % count the values
    curexperiment.original_markers.cur_count(logical(data_markers.event(i).original_marker == cell2mat(curexperiment.original_markers.original_marker))) = ...
        curexperiment.original_markers.cur_count(logical(data_markers.event(i).original_marker == cell2mat(curexperiment.original_markers.original_marker))) +1;
end
clear i

count_error = {};
c=1;
% check if start Encoding/Retrieval markers are present
for i=1:size(curexperiment.original_markers,1)
    % check if there is a predefined count value
    if strcmp(curexperiment.original_markers.Properties.RowNames{i},'Start Encoding')...
            ||strcmp(curexperiment.original_markers.Properties.RowNames{i},'Start Retrieval')
        % check whether the predefined count value matches the actual countin this participant
        if ~logical(curexperiment.original_markers.count_without_practice{i} == curexperiment.original_markers.cur_count(i))
            fprintf(2,[sprintf('ERROR count %s', curexperiment.original_markers.Properties.RowNames{i}) char(10)]);
            count_error{c} = curexperiment.original_markers.Properties.RowNames{i};
            c = c+1;
        end
    end
end

if any(strcmp(count_error,'Start Encoding'))
    % find the index of the first stimulus onset
    if frst > 1
       data_markers.event(frst-1).original_marker = cell2mat(curexperiment.original_markers.original_marker('Start Encoding'));
       display('Error Start Encoding SOLVED')
    else
       error('ERROR Start Encoding could not be solved :(')
    end
end

if any(strcmp(count_error,'Start Retrieval'))
    error('ERROR Start Retrieval could not be solved :(')
end

% count all markers again
curexperiment.original_markers.cur_count = [];
curexperiment.original_markers.cur_count(1)=0;
for i=1:length(data_markers.event)    
    % count the values
    curexperiment.original_markers.cur_count(logical(data_markers.event(i).original_marker == cell2mat(curexperiment.original_markers.original_marker))) = ...
        curexperiment.original_markers.cur_count(logical(data_markers.event(i).original_marker == cell2mat(curexperiment.original_markers.original_marker))) +1;
end
clear i

count_error = {};
c=1;
% check if all markers are there
for i=2:size(curexperiment.original_markers,1) % skip practice count
    % check if there is a predefined count value
    if ~isempty(curexperiment.original_markers.count_without_practice{i})
        % check whether the predefined count value matches the actual countin this participant
        if ~logical(curexperiment.original_markers.count_without_practice{i} == curexperiment.original_markers.cur_count(i))
            fprintf(2,[sprintf('ERROR count %s', curexperiment.original_markers.Properties.RowNames{i}) char(10)]);
            count_error{c} = curexperiment.original_markers.Properties.RowNames{i};
            c = c+1;
        end
    end
end
clear c
if isempty(count_error)
    display('No (remaining) trialcount inconsistencies')
else
    close all
    figure(1);
    t = annotation('textbox');
    t.String = sprintf('Check the errors\nClick on me when you are done\nor abort the script');
    t.FontSize = 20;
    t.Position = [0.25 0.35 0.5 0.35];
    waitforbuttonpress
    display('ok')
    close figure 1
end

clear count_error t

%% BEHAVIORAL DATA
loop = false; % for the behavioral analyses
eval([curexperiment.name '_Analyses_Behav;'])
clear loop

%% ENCODING & RETRIEVAL
evalc(sprintf('ppn = all_ppns.ppn%s;',subjectdata.subjectnr));
e=curexperiment.Ntrials_enc;
r=curexperiment.Ntrials_ret;
% make the memory markers
for i=length(data_markers.event):-1:1
    % retrieval
    if ismember(data_markers.event(i).original_marker, cell2mat(table2array(curexperiment.original_markers('Retrieval Stimulus Onset Baseline Left','original_marker')))) || ...
          ismember(data_markers.event(i).original_marker, cell2mat(table2array(curexperiment.original_markers('Retrieval Stimulus Onset Baseline Right','original_marker')))) || ...
          ismember(data_markers.event(i).original_marker, cell2mat(table2array(curexperiment.original_markers('Retrieval Stimulus Onset Distraction Left Target','original_marker')))) || ...
          ismember(data_markers.event(i).original_marker, cell2mat(table2array(curexperiment.original_markers('Retrieval Stimulus Onset Distraction Right Target','original_marker')))) || ...
          ismember(data_markers.event(i).original_marker, cell2mat(table2array(curexperiment.original_markers('Retrieval Stimulus Onset Distraction Right Distractor','original_marker')))) || ...
          ismember(data_markers.event(i).original_marker, cell2mat(table2array(curexperiment.original_markers('Retrieval Stimulus Onset Distraction Left Distractor','original_marker')))) || ...
          ismember(data_markers.event(i).original_marker, cell2mat(table2array(curexperiment.original_markers('Retrieval Stimulus Onset New','original_marker')))) 
        if ppn.acc_conf(r)== 1113 % HitHCb
            data_markers.event(i).original_marker = 5311;
        elseif ppn.acc_conf(r)==1123 % HitHCt
            data_markers.event(i).original_marker = 5312;
        elseif ppn.acc_conf(r)==1133 % HitHCd
            data_markers.event(i).original_marker = 5313;
        elseif ppn.acc_conf(r)== 1111 % HitLCb
            data_markers.event(i).original_marker = 5111;
        elseif ppn.acc_conf(r)==1121 % HitLCt
            data_markers.event(i).original_marker = 5112;
        elseif ppn.acc_conf(r)==1131 % HitLCd
            data_markers.event(i).original_marker = 5113;
        elseif ppn.acc_conf(r)== 211 % Missb
            data_markers.event(i).original_marker = 5231;
        elseif ppn.acc_conf(r)==212 % Misst
            data_markers.event(i).original_marker = 5232;
        elseif ppn.acc_conf(r)==213 % Missd
            data_markers.event(i).original_marker = 5233;
        elseif ppn.acc_conf(r)== 223 % CRHC
            data_markers.event(i).original_marker = 5325;
        elseif ppn.acc_conf(r)==221 % CRLH
            data_markers.event(i).original_marker = 5125;
        elseif ppn.acc_conf(r)==12 % FA
            data_markers.event(i).original_marker = 527;
        end
        r=r-1;
    end
    % encoding
    if ismember(data_markers.event(i).original_marker, cell2mat(table2array(curexperiment.original_markers('Encoding Stimulus Onset Baseline Left','original_marker'))))
        if ppn.encDm(e)==111 % hit
            data_markers.event(i).original_marker = 311;
        elseif ppn.encDm(e)==211 %miss
            data_markers.event(i).original_marker = 313;
        end
        e=e-1;
    elseif ismember(data_markers.event(i).original_marker, cell2mat(table2array(curexperiment.original_markers('Encoding Stimulus Onset Baseline Right','original_marker'))))
        if ppn.encDm(e)==111 % hit
            data_markers.event(i).original_marker = 321;
        elseif ppn.encDm(e)==211 % miss
            data_markers.event(i).original_marker = 323;
        end
        e=e-1;
    elseif ismember(data_markers.event(i).original_marker, cell2mat(table2array(curexperiment.original_markers('Encoding Stimulus Onset Distraction Left Target','original_marker'))))
        if ppn.encDm(e)== 112113 % THDH
            data_markers.event(i).original_marker = 3111;
        elseif ppn.encDm(e)==112213 % THDM
            data_markers.event(i).original_marker = 3113;
        elseif ppn.encDm(e)==212113 % TMDH
            data_markers.event(i).original_marker = 3131;
        elseif ppn.encDm(e)==212213 % TMDM
            data_markers.event(i).original_marker = 3133;
        end
        e=e-1;
    elseif ismember(data_markers.event(i).original_marker, cell2mat(table2array(curexperiment.original_markers('Encoding Stimulus Onset Distraction Right Target','original_marker'))))
        if ppn.encDm(e)== 112113 % THDH
            data_markers.event(i).original_marker = 3211;
        elseif ppn.encDm(e)==112213 % THDM
            data_markers.event(i).original_marker = 3213;
        elseif ppn.encDm(e)==212113 % TMDH
            data_markers.event(i).original_marker = 3231;
        elseif ppn.encDm(e)==212213 % TMDM
            data_markers.event(i).original_marker = 3233;
        end
        e=e-1;
    end
end

if e~=0 
    fprintf(2,[sprintf('Encoding marker mismatch trialcount') char(10)]);
    pause(5)
elseif r~=0
    fprintf(2,[sprintf('Retrieval marker mismatch trialcount') char(10)]);
    pause(5)
end
clear e
clear r

%% WRAPPING UP
% replace the marker values with the original markers
[data_markers.event(1:numel(data_markers.event)).value] = deal(data_markers.event.original_marker);
% remove the 'original_marker field'
data_markers.event = rmfield(data_markers.event,'original_marker');
% create an event file
event = data_markers.event;
% create a list of new marker values
ret_markers = struct2cell(curexperiment.data2.l2);
ret_stim_new=cell2mat(ret_markers(ismember(cell2mat(struct2cell(curexperiment.data2.l2)),[data_markers.event.value])));
enc_markers = struct2cell(curexperiment.data1.l2);
enc_stim_new=cell2mat(enc_markers(ismember(cell2mat(struct2cell(curexperiment.data1.l2)),[data_markers.event.value])));

% save the data with altered markers
save([subjectdata.subjectdir filesep subjectdata.subjectnr '_RawData_AlterMarkers.mat'],'data_markers'); 
save([subjectdata.subjectdir filesep subjectdata.subjectnr '_Raw_AlterMarkers_Events.mat'],'event'); 
save([subjectdata.subjectdir filesep subjectdata.subjectnr '_Raw_EncAlterMarkers.mat'],'enc_stim_new'); 
save([subjectdata.subjectdir filesep subjectdata.subjectnr '_Raw_RetAlterMarkers.mat'],'ret_stim_new'); 

clear ret_markers
clear enc_markers
clear ret_stim_new
clear enc_stim_new
clear event ppn frst* last