function [fpStruc] = procFPdata()

% Clay Apr.11, 2017
% for Deepika/Ansorge
% (excerpted from Final_FP_MedPC_analysis_20170108.m)
% This script reads in a TDT data fiber photometry recording of calcium signals
% in mouse brain in conjunction with GoNogo Operant tasks. 
% Outputs a structure of times of desired events (in sec).


% select file to process
[filename, path] = uigetfile('.tsq', 'Select TSQ file of fiber photometry data to process');
fpStruc.tsqName = filename;
fpStruc.tsqPath = path;

disp(['Processing TDT fiber photometry data for: ' path filename]);
tic;

seps = strfind(path, filesep); % find file separator indices in pathname

synapse_filename = filename(1:strfind(filename, '.tsq')-1); % file basename, like 'GregmultiLEDfinal-161214-183658_testjan-170306-154158';
synapse_folder_of_traces = path(1:seps(end-1)-1); % day folder, like '170306';
synapse_folder_of_single_trace = path(seps(end-1)+1:seps(end)-1); % session folder, like 'testjan-170306-154158';

% Remember to remove '.Tbx,.tev,etc.' from synapse_filename

% % Import MedPC-IV data 
% medpciv_folder = 'MEDPCDATA';
% medpciv_filename = '170306 Mouse 2';

% % Change yshift in order to push up or down 405 trace. Try to align as
% perfectly as possible. Positive number pushes up 405 trace.
yshift =-0.5;
% % % % % % % s of section requiring user input
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %

% Import 470nm trace
blk = '.';
name = '470A';
S1 = TDT_Import_mod(synapse_folder_of_traces, ...
    synapse_folder_of_single_trace, blk, name, synapse_filename);
Dv1 = S1.data;

fpStruc.sfFP = S1.sampling_rate;
fpStruc.startStop = [S1.tstart S1.tend];

% Import 405nm trace
name = '405A';
S2 = TDT_Import_mod(synapse_folder_of_traces, ...
    synapse_folder_of_single_trace, blk, name, synapse_filename);
Dv2 = S2.data;

% Import MedPC Trigger trace
name = 'Wav1';
S2 = TDT_Import_mod(synapse_folder_of_traces, ...
    synapse_folder_of_single_trace, blk, name, synapse_filename);
Dv3 = S2.data;

fpStruc.tdtSync = Dv3;

% Find MedPC Trigger start time (we will align MedPC events
% using this start time)
Dv3offthres = 3.0;
Dv3start = 0;
count = 0;
for i=1:length(Dv3)
    
    if Dv3(i) > Dv3offthres
        count = 1;
    end
    if count == 1
        if Dv3(i) < Dv3offthres
            Dv3start = i;
            break
        end
    end
end
%dv3start_secs is the time that MedPC sent its signal
dv3start_secs = Dv3start/1e3; 

% % % % % % % % % % Plot normalized trace
normalized = (((Dv1-(Dv2+yshift))./(Dv2+yshift))*100);

fpStruc.normCa = normalized;

fpStruc.tScaleFact = 2.0343;
fpStruc.tOffset = dv3start_secs;

% 050917: hack for previous timing fix
%fpStruc.tFP = 0:1/fpStruc.sfFP:fpStruc.startStop(2)-fpStruc.startStop(1);
fpStruc.tFP = 0:0.001:(length(Dv2)-1)*0.001;

toc;

% figure;
% plot(((x/1000)),normalized);
% hold on
% % Plot out the R RLever and Plot MedPC events; timing is mulitplied by 2x, shift up y-axis for
% % viusalizaton.
% plot((RLeverOnarray_final(:,1)*2.0343)+dv3start_secs,(RLeverOnarray_final(:,2)*1)+median(normalized)-3,'k')
