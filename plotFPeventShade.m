function plotFPeventShade(ca, firstLastTime)

%% USAGE: plotFPeventShade(ca, firstLastTime);

x = linspace(firstLastTime(1), firstLastTime(2), size(ca,1)); 

avgCa = nanmean(ca,2);
sem = nanstd(ca,0,2)/sqrt(size(ca,2));

maxVal = max(avgCa+sem)+0.5;
minVal = min(avgCa-sem)-0.5;

shadedErrorBar(x, avgCa, sem, 'b', 1);

line([0 0], [minVal maxVal]);

ylim([minVal maxVal]);

xlabel('sec');