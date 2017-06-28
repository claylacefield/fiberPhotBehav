function [eventCa] = calcEventTrigFPsig(fpStruc, behavStruc, eventName, toPlot)

%% USAGE: [eventCa] = calcEventTrigFPsig(fpStruc, behavStruc, eventName, toPlot);

% window for event triggered calcium signal extraction
preEvSec = 10;
postEvSec = 30;

% load necessary data
ca = fpStruc.normCa; % extract fiber photometry data
tScaleFact = fpStruc.tScaleFact;
tOffset = fpStruc.tOffset;  % sec MedAssoc start time after FP data starts
tFP = fpStruc.tFP;  % array of times (in sec) for FP data
sfFP = fpStruc.sfFP;

eventTimes = behavStruc.(eventName);
%behavTime = behavStruc.time;  % time array for all behav, in sec.

%% now adjust the event times
eventTimes = eventTimes*tScaleFact+tOffset; % so now eventTimes and tFP should be on the same timescale
%eventTimes = eventTimes(eventTimes<(max(tFP)-30));
eventTimes(eventTimes>(max(tFP)-30))= NaN;

preEvSamp = preEvSec*round(sfFP); % samples before event to include in ca epoch
postEvSamp = postEvSec*round(sfFP);

%% extract calcium window around events
for evNum = 1:length(eventTimes)
    %try
        if ~isnan(eventTimes(evNum))
            evTime = eventTimes(evNum);
            [minVal, zeroInd] = min(abs(tFP-evTime));
            eventCa(:, evNum) = ca(zeroInd-preEvSamp:zeroInd+postEvSamp);
            zeroInds(evNum) = zeroInd;
        else
            eventCa(:, evNum) = NaN([length(-preEvSamp:postEvSamp) 1], 'single');
            zeroInds(evNum) = NaN;
        end
%     catch
%         disp(['Problem with event # ' num2str(evNum) ' of type ' eventName]);
%     end
end

%% plotting
try
    if toPlot
        figure;
        if size(eventCa,2)>1
            %plotMeanSEM(eventCa, 'b');
            plotFPeventShade(eventCa, [-preEvSec postEvSec]);
        elseif size(eventCa,2)==1
            plot(eventCa);
        end
        title([fpStruc.tsqName ' ' eventName ' on ' date]);
    end
catch
    %eventCa = [];
    disp(['No events of type "' eventName '" within FP recording period']);
end
