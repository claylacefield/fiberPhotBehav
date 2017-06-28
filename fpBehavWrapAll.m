function [eventFpStruc, fpStruc, behavStruc] = fpBehavWrapAll(toPlot)

% Clay April 20, 2017
% This is a wrapper script that processes data for TDT fiber photometry
% data along with operant behavior for the Ansorge lab.

% process fiber photometry data
[fpStruc] = procFPdata();

% process behavior
[behavStruc] = procFPbehavMedAssoc();

% extract corr/incorr trial times
[behavStruc] = findIncorrTrials(behavStruc);

% and calc all other event types/times
[behavStruc] = findPressLat(behavStruc);

% compute event triggered average for desired event
behavFields = fieldnames(behavStruc);
%figure; hold on;
for i = 1:length(behavFields)
    eventName = behavFields{i};
    if isempty(strfind(eventName, 'txt')) && isempty(strfind(eventName, 'Lat'))
        try
            eventCa = calcEventTrigFPsig(fpStruc, behavStruc, eventName, 0);
            eventFpStruc.([eventName 'Ca']) = eventCa;
        catch
            disp(['No events of type: ' eventName]);
        end
    end
    
end

if toPlot
    %fields = fieldnames(eventFpStruc);
    trialType = {'corrGo' 'incorrGo' 'corrNogo' 'incorrNogo'};
    evEnding = {'Trial' 'Press' 'Dip' 'Poke'};
    figure;
    for j = 1:length(trialType)
        for k = 1:length(evEnding)
            subplot(4,4,4*(j-1)+k);
            try
                %plotMeanSEM(eventFpStruc.(fields{j}), 'b');
                plotFPeventShade(eventFpStruc.([trialType{j} evEnding{k} 'Ca']), [-10 30]);
                title([trialType{j} evEnding{k} 'Ca']);
                xlabel('sec');
            catch
            end
        end
        
    end
end
