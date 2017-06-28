function [behavStruc] = findIncorrTrials(behavStruc)

% script to find incorrect trials in Ansorge operant data (when these are
% not marked in behav file)
% And actually, correct go/nogo are listed as reward times in original
% record, so this also extracts trial start times for all trial types.

levIn = behavStruc.levIn;
dipIn = behavStruc.dipIn;
corrGo = behavStruc.corrGo;
corrNogo = behavStruc.corrNogo;
press = behavStruc.press;

corrGoTrial = [];
corrNogoTrial = [];
incorrNogoTrial = [];
incorrGoTrial = [];
    

for i = 1:length(levIn)-1
    
    % if press in this trial and not correct, then incorrect Nogo
    % if no press this trial and not correct, then incorrect Go
    
    if ~isempty(find(corrGo > levIn(i) & corrGo < levIn(i+1)))
       corrGoTrial = [corrGoTrial; levIn(i)]; 
    elseif ~isempty(find(corrNogo > levIn(i) & corrNogo < levIn(i+1)))
        corrNogoTrial = [corrNogoTrial; levIn(i)];
    elseif ~isempty(find(press > levIn(i) & press < levIn(i+1)))
        incorrNogoTrial = [incorrNogoTrial; levIn(i)];
    else
        incorrGoTrial = [incorrGoTrial; levIn(i)];
    end
    
end

behavStruc.corrGoTrial = corrGoTrial;
behavStruc.corrNogoTrial = corrNogoTrial;
behavStruc.incorrNogoTrial = incorrNogoTrial;
behavStruc.incorrGoTrial = incorrGoTrial;
