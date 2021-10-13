function [data,samps]=trlnr(cfg)
% function samps=trlnr(markers,data)
% cfg.markers = stimulus onset markers per dataset
% cfg.data = dataset
% cfg.offset = offset to be substracted from data.event.value
% This function adds trialnumbers to the trialinfo based on the 'markers'
% which is a structure wich contains the markers for the stimulus onset
% that looks like: struct.datasetname.stimmarkers. This trialinfo concerns
% the data specified in 'data'. It will correct for missing trials at the
% beginning by starting the count at the end. It can return the samples of
% the start of that trial

%% SET INTERNAL VARIABLES
fldnms = fieldnames(cfg);
for i=1:length(fldnms)
    if isfield(cfg,fldnms{i})
        evalc(sprintf('%1$s = cfg.%1$s;',fldnms{i}));
    end
end
setnms = fieldnames(markers);
% offset = data.event(1).value;
    
%% COUNT THE TRIALS
dattab = struct2table(data.event);
for d=1:length(setnms) % loop over datasets
    curset = markers.(setnms{d});
    if isnumeric(curset) % for numeric markers
        curset = curset + offset; % adjust marker value if needed
        if isnumeric(dattab.value)
            trlcntr(d) = sum(ismember(dattab.value,curset));
        else
            trlcntr(d) = sum(ismember(cell2mat(dattab.value),curset));
        end
    elseif ischar(curset) || iscell(curset) % for non-numeric markers
        % make sure all values are chars
        dattab.value = cellfun(@char,dattab.value,'UniformOutput',false);
        trlcntr(d) = sum(ismember(dattab.value,curset));
    end
end

%% ADD TRIALNUMBERS
% add a column for the trialnumbers
tmp=cell(size(data.event)); [data.event(:).trlnr] =deal(tmp{:});
clear tmp
curvars = fieldnames(curexperiment);
for e=1:size(data.event,2)
    if ~isempty(data.event(e).value)
        trl_strt = e-1; % get the row number of the first real event to use later for trl assignment
        break
    end
end
if trl_strt == 0
    trl_strt = 1;
end
for d=1:length(setnms) % loop over datasets
    if eval(sprintf('any(strcmp(curvars,''Ntrials_%s''))',setnms{d}))
        evalc(sprintf('trlcntr(d) = curexperiment.Ntrials_%s;',setnms{d}));
    end
    curset = markers.(setnms{d});
    if isnumeric(curset) || ischar(curset)
        if isnumeric(curset)
            curset = curset + offset; % adjust marker value if needed
        end
        for e=size(data.event,2):-1:1 % loop over events
            if trlcntr(d) > 0
                if all(ismember(curset, data.event(e).value))
                    data.event(e).trlnr = trlcntr(d);
                    data.trl(e-trl_strt,5) = trlcntr(d);
                    evalc(sprintf('samps.%s(%d,1)=%d;',setnms{d},trlcntr(d),trlcntr(d)));
                    evalc(sprintf('samps.%s(%d,2)=data.event(e).sample;',setnms{d},trlcntr(d)));            
                    trlcntr(d) = trlcntr(d)-1; % count backwards
                end
            end
        end
    elseif iscell(curset)
        for e=size(data.event,2):-1:1 % loop over events
            if trlcntr(d) > 0
                if any(ismember(curset, char(data.event(e).value)))
                    data.event(e).trlnr = trlcntr(d);
                    data.trl(e-trl_strt,5) = trlcntr(d);
                    evalc(sprintf('samps.%s(%d,1)=%d;',setnms{d},trlcntr(d),trlcntr(d)));
                    evalc(sprintf('samps.%s(%d,2)=data.event(e).sample;',setnms{d},trlcntr(d)));            
                    trlcntr(d) = trlcntr(d)-1; % count backwards
                end
            end
        end
    end
end

