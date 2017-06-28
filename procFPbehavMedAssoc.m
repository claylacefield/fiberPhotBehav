function [behavStruc] = procFPbehavMedAssoc()

% Clay Apr.11, 2017
% for Deepika/Ansorge
% (originally from Final_FP_MedPC_analysis_20170108.m, but changed greatly 041817)
% This script reads in a TXT file of MedAssociates data for GoNogo Operant
% tasks in conjunction with fiber photometry recording of calcium signals
% in mouse brain.
% Outputs a structure of times of desired events (in sec).


% select file to process
[filename path] = uigetfile('.txt', 'Select TXT file of MedAssoc data to process');

behavStruc.txtFilename = filename;
behavStruc.txtPath = path;

disp(['Processing MedAssoc behavior data for operant data file: ' filename]);
tic;

% Define names and codes for events (comment lines for ones you don't want)
codeArr = {...
    'levIn', '0028';... % RLevOnCode
    'levOut', '0030';... % RLevOffCode
    'press', '1016';... % RPressOnCode
    % 'pressOff', '1018';... % RPressOff
    'dipIn', '0025';... % DipOn
    'dipOut', '0026';... % DipOff
    'poke', '1011';...
    'corrGo', '1111';...
    'corrNogo', '1110'}; % Nosepoke
      
% Import MedPCIV data
dataTable = readtable([path filename]); % (strcat(medpciv_folder,'/',medpciv_filename));
codes = dataTable{13:end,2}; % only keep codes column, and cut off header lines
s = size(codes);
numEvents = s(1);
code = cell(numEvents,1);

% Get time of events; MedPC-IV time resolution is 5ms
old_time = zeros(numEvents,1);
for evNum = 1:numEvents
    currCode = codes{evNum}; % extract current full code
    old_time(evNum) = str2double(currCode(1:end-4));    % and get time (in ms)
    code{evNum} = currCode(end-3:end);
end

%Subtract out initial time such that first events occur at time=0
times = old_time - old_time(1); 
times = times/1000;  % convert to sec
%behavStruc.times = times; % don't need to output all event times

%% % % % Create arrays containing events and their corresponding times

for numCode = 1:size(codeArr,1)
    evName = codeArr{numCode,1};
    evRows = find(ismember(code, codeArr(numCode,2)));
    evTimes = times(evRows);
    behavStruc.(evName) = evTimes;
end
    
toc;

