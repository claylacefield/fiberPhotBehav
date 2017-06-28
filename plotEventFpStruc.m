function plotEventFpStruc(eventFpStruc)


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