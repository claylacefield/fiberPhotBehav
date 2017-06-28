function [behavStruc] = findPressLat(behavStruc)

%% USAGE: [behavStruc] = findPressLat(behavStruc);
% Clay Lacefield 2017
% For each corrGoTrial and incorrNogoTrial, calculate latency to press and
% NOTE: may have to alter "poke" calculations if the mouse sometimes gets
% the reward, but doesn't consume it

% load necessary variables
corrGoTrial = behavStruc.corrGoTrial;
incorrNogoTrial = behavStruc.incorrNogoTrial;
corrNogoTrial = behavStruc.corrNogoTrial;
incorrGoTrial = behavStruc.incorrGoTrial;

press = behavStruc.press;   % lever press response
poke = behavStruc.poke; % reward consumed
dip = behavStruc.dipIn; % reward administered
lev = behavStruc.levIn; % leverIn (start of trial)

%% corrGoTrials
try
    for i = 1:length(corrGoTrial)
        
        pressInd = find(press > corrGoTrial(i), 1);
        corrGoLat(i) = press(pressInd)-corrGoTrial(i);
        corrGoDip(i) = dip(find(dip > corrGoTrial(i), 1));
        
        nextTrialTime = lev(find(lev>corrGoTrial(i), 1));
        if ~isempty(find(poke > corrGoTrial(i) & poke<nextTrialTime))
            corrGoPoke(i) = poke(find(poke > corrGoTrial(i), 1));
        else
            corrGoPoke(i) = NaN;
        end
        
    end
    
    behavStruc.corrGoLat = corrGoLat';
    behavStruc.corrGoPress = corrGoTrial+corrGoLat';
    behavStruc.corrGoDip = corrGoDip';
    behavStruc.corrGoPoke = corrGoPoke';
catch
    disp('No correct Go trials');
    behavStruc.corrGoLat = [];
    behavStruc.corrGoPress = [];
    behavStruc.corrGoDip = [];
    behavStruc.corrGoPoke = [];
end

%% incorrNogoTrials
try
    for i = 1:length(incorrNogoTrial)
        
        pressInd = find(press > incorrNogoTrial(i), 1);
        incorrNogoLat(i) = press(pressInd)-incorrNogoTrial(i);
        
    end
    
    behavStruc.incorrNogoLat = incorrNogoLat';
    behavStruc.incorrNogoPress = incorrNogoTrial+incorrNogoLat';
    
catch
    disp('No incorrect Nogo trials');
    behavStruc.incorrNogoLat = [];
    behavStruc.incorrNogoPress = [];
end


%% corrNogoTrials
try
    for i = 1:length(corrNogoTrial)
        
        corrNogoDip(i) = dip(find(dip > corrNogoTrial(i), 1));
        
        nextTrialTime = lev(find(lev>corrNogoTrial(i), 1));
        if ~isempty(find(poke > corrNogoTrial(i) & poke<nextTrialTime))
            corrNogoPoke(i) = poke(find(poke > corrNogoTrial(i), 1));
        else
            corrNogoPoke(i) = NaN;
        end
        
    end
    
    behavStruc.corrNogoDip = corrNogoDip';
    behavStruc.corrNogoPoke = corrNogoPoke';
    
catch
    disp('No correct Nogo trials');
    behavStruc.corrNogoDip = [];
    behavStruc.corrNogoPoke = [];
end

%% incorrGoTrials
% NOTE: these often don't happen, so have to concat somewhat differently

%incorrGoPoke = [];
try
    for i = 1:length(incorrGoTrial)
        nextTrialTime = lev(find(lev>incorrGoTrial(i), 1));
        if ~isempty(find(poke > incorrGoTrial(i) & poke < nextTrialTime, 1))
            incorrGoPoke(i) = poke(find(poke > incorrGoTrial(i) & poke < nextTrialTime, 1));
        else
            incorrGoPoke(i) = NaN;
        end
        
    end
    
    behavStruc.incorrGoPoke = incorrGoPoke';
    
catch
    disp('No incorrect Go trials');
    behavStruc.incorrGoPoke = [];
end