 function S = TDT_Import_mod(filepath, tank, blk, name, filename, chans, timewin,...
    return_timestamps)
%% TDT_Import.m %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Import data from TDT system recording into Matlab structure
%
% S = TDT_Import(filepath, tank, blk, name, chans, timewin, return_timestamps)
%
% INPUTS
%   filepath: folder where tank is stored
%    tank: tank name
%     blk: block name
%    name: 4-character store/event name in TDT (ie 'WLFP')
%
% OPTIONAL INPUTS
%   chans: for 'Wave' events, array of channel #s to import 
%          (Optional. []/default = import all chans)
% timewin: 1x2 array of start/end time to import (NOT CURRENTLY SUPPORTED)
% return_timestamps: 
%          flag whether to populate the 'timestamps' field with the time of
%          each sample. Redundant with tstart/tend/samplerate, so defaults
%          to false.
%
% OUTPUT
% data structure with fields
%         storename: 4-character Store name
%              data: data in rows, 1 column per channel
%             chans: TDT channel numbers, 1 per data column
%            tstart: start time of extracted data, relative to when recording started (s) 
%              tend: end time of extracted data, relative to when recording started (s) 
%     sampling_rate: (Hz)
%       format_code:
%
% derived from: 
%  http://jaewon.mine.nu/jaewon/2010/10/04/how-to-import-tdt-tank-into-matlab/
%
% Example usage:
%{



% THIS IS THE PART THAT NEEDS TO BE EDITED AND THEN RUN IN MATLB WINDOW FOR EACH FILE, make sure this TDT_Import_mod.m function is in the matlab directory so it can call it.

% Baila Step 1: specify the filename below: 
% Baila Step 2: replace the variables (filepath, tank, blk, save name) immediately following this:
% Baila Step 3: copy and paste, and then press enter  

___________________________________________

filepath = '/Users/Rob/Documents/ListonLab/ForBaila';
tank = 'NoldusTest011916';
blk = '2AF';
name = 'LMag';
filename = '2AF';

S = TDT_Import_mod(filepath, tank, blk, name, filename)

______________________________________________________

% Baila: rename the output structure to whatever you want:
currentData = S;


% THE ABOVE IS WHAT NEEDS TO BE ENTERED INTO MATLAB WINDOW.




%}
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% TDT Import notes
% -'Tick' is not every second. Seems to be issued every n samples, where n
%  is  round(sampling_rate)-1. Could be floor instead of round. For 12k
%  (12207.03125 Hz) system clock, 'Tick' is issued every 12206 samples =
%  0.99991552 s.) Take-home: don't rely on 'Tick's for timing.
% -Sampling clock is same as timestamp clock, so don't have to worry about
%  skew, drift, nonlinearities. Woohoo! 
%
% TODO:
% -How to deal with outputting different data types? TDT uses substructures 
%  for each data type (Wave, Strobe, etc)?
%  WRITE SEPARATE FUNCTIONS FOR EACH TYPE OF OUTPUT DATA: 
%   -TDT_ImportWave (deal with .sev files as well?)
%   -TDT_ImportEvent (EpocStore, SlowStore)
%   -TDT_ImportSnippet
%  Possibly make TDT_Import be a dispatcher for these.
%
% -Check out TDT-provided SEV2mat.m (which reads .sev files, and doesn't use ActiveX!)
%
% MAYBE:
% -Handle intermittently recorded Waves? (using timestamps field)
% -Handle epoc_store secondary stores (what format code? where is the
% non-strobe data stored???)
% -convert formats to string. (OpenDeveloper manual EvTypeToString)
% -Load in chunks to avoid out-of-memory errors? (like TDT2mat)
% -Call separate function to get list of store names?
%
% DONE:
% -Select channels/timewins *during loading* (to speed things up and avoid 
%  out-of-memory conditions)
% -save a lot of memory by having fread use correct Matlab types (single,
%  uint32, etc.) instead of double for everything. Both .tsq and .tev
% -un-bufferize wave data
% -test for timestamp errors in buffers (no need to interpolate timestamps
%  on each buffer first
% -rename to avoid confusion with TDT2mat: TDT_LoadStore, TDT_ParseHeader?


% handle missing/optional inputs
if ~exist('name', 'var'), name= []; end; % will result in list of available store names being displayed
if ~exist('chans', 'var'), chans = []; end;
if ~exist('timewin', 'var'), timewin= []; end;
if ~exist('return_timestamps', 'var'), return_timestamps = false; end;

% Haven't implemented 'timewin' yet
if ~isempty(timewin),
    error('''timewin'' argument not currently supported; omit or leave empty to import all data.');
end



tev_path = [filepath filesep tank filesep blk filesep filename '.tev'];
tsq_path = [filepath filesep tank filesep blk filesep filename '.tsq'];

S = struct(...
    'storename', [],...
    'data', [],...
    'chans', [],...
    'tstart', [],...
    'tend', [],...
    'timestamps', [],...
    'sampling_rate', [],...
    'buff_timestamps', [],...
    'buff_channel', [],...
    'buff_data', [],...
    'buff_npoints', [],...
    'max_ts_err', [],...
    'info', []);

% open the files
tev = fopen(tev_path);
tsq = fopen(tsq_path); 

recsize_bytes = 40;
% count number of tsq records (40 bytes/record)
fseek(tsq, 0, 'eof'); ntsq = ftell(tsq)/recsize_bytes; 

% read from tsq
fseek(tsq, 0, 'bof');
data.size      = fread(tsq, [ntsq 1], '*int32',  recsize_bytes-4); 

fseek(tsq, 4, 'bof');
data.type      = fread(tsq, [ntsq 1], '*int32',  recsize_bytes-4); 

fseek(tsq, 8, 'bof');
data.name      = fread(tsq, [4 ntsq], '4*uchar=>char', recsize_bytes-4)'; %reads column-wise

fseek(tsq, 12, 'bof');
data.chan      = fread(tsq, [ntsq 1], '*ushort', recsize_bytes-2);

% % 'sortcode' not currently used for import
% fseek(tsq, 14, 'bof'); 
% data.sortcode  = fread(tsq, [ntsq 1], '*ushort', recsize_bytes-2); 

fseek(tsq, 16, 'bof'); 
data.timestamp = fread(tsq, [ntsq 1], '*double', recsize_bytes-8); 

% this position (24) is either a pointer into .tev, or a double float as data 

fseek(tsq, 24, 'bof');
data.fp_loc    = fread(tsq, [ntsq 1], '*int64',  recsize_bytes-8);

% read 'strobe' below only if requested
fseek(tsq, 24, 'bof');
data.strobe    = fread(tsq, [ntsq 1], '*double', recsize_bytes-8); 

fseek(tsq, 32, 'bof');
data.format    = fread(tsq, [ntsq 1], '*int32',  recsize_bytes-4); 

fseek(tsq, 36, 'bof');
data.frequency = fread(tsq, [ntsq 1], '*float',  recsize_bytes-4);

% Second entry in the .tsq file always contains the timestamp of the start 
% of the block. TDT timestamps are in Unix time (seconds elapsed since 
% January 1, 1970 -- http://en.wikipedia.org/wiki/Unix_time )
ts_block_start = data.timestamp(2);

allnames = unique(data.name,'rows');
% exclude 'names' that contain ASCII Null character (==0), these are 
% special TDT codes, not real stores.
allnames = allnames(all(double(allnames)~=0,2),:);

% Get rows matching requested store name
if isempty(name), 
    row = [];
else
    row = ismember(data.name, name, 'rows');
end

if sum(row) == 0
  disp(['Requested store name ''' name ''' not found (case-sensitive).'])
  disp('File contains the following TDT store names:');
  disp(allnames);
  error('TDT store name not found.');
end


% See OpenDeveloper manual 'GetNPer' and 'DFromToString' (a typo for Data FORMat To String)
% Format codes are 0-5 in 6 rows below
%       { TDT type,  bytes, fread code,       Matlab type }
table = { 'float',   4,     'float=>single',  'single'; % 0 
          'long',    4,     'int32=>int32',   'int32';  % 1
          'short',   2,     'short=>int16',   'int16';  % 2
          'byte',    1,     'schar=>int8',    'int8';   % 3
          'double',  8,     'double=>double', 'double'; % 4 
          'qword'    8,     'int64=>int64',   'int64'}; % 5 not seen in the wild

first_row = find(row,1);
format_code = data.format(first_row); 
format_idx = format_code+1; % from 0-based to 1-based for table lookup

S.storename = name;
S.sampling_rate = double(data.frequency(first_row));


% Select data to load (i.e. 'rows') based on channel #

% Which channels are present in the file? 
buff_channels      = data.chan(row);
allchans = sort(unique(buff_channels))';

% validate requested channels
if isempty(chans) % default to all channels, sorted
    chans = allchans;
elseif ~all(ismember(chans, allchans)),
    % error: display bad values
    fprintf('Chans available: %s\n', num2str(allchans));
    fprintf('Chans requested: %s\n', num2str(chans));
    error('Requested ''chans'' channels not present for store named ''%s''', name);
end
nchans = numel(chans);

% Select only the rows containing the requested channels (logical &)
row = row & ismember(data.chan, chans);


% Report which channels are included in the output
S.chans = chans;

% Get pointers into .tev data file for start of each row's (buffer's) data
fp_loc  = data.fp_loc(row);

% Get timestamp of each buffer
S.buff_timestamps = data.timestamp(row);
S.buff_channel = data.chan(row);

if format_code ~=4
  nsample = ((4 .* data.size(first_row)) - 40) ./ table{format_idx,2};
  if rem(nsample,1), error('Non-integer number of samples--problem with size calculation'); end
  S.buff_data = zeros(length(fp_loc),nsample, table{format_idx,4});
  for n=1:length(fp_loc)
    fseek(tev,fp_loc(n),'bof');
    S.buff_data(n,1:nsample) = fread(tev,[1 nsample],table{format_idx,3}); %#ok
  end
  S.buff_npoints = double(nsample);

else % (format_code ==4) epoc_stores and slow_stores have their data as a float in the 'strobe' field.
  S.buff_data = data.strobe(row);
  S.buff_npoints = 1;
  % epoc_store events list all strobe data as channel 0; let's call it 1
  % slow_store events use normal channel numbering
  if all(S.buff_channel == 0),
      S.buff_channel = ones(size(S.buff_channel));
      chans(chans==0)=1;
  end
end

% how many buffers per channel? (calculate for first channel)
chanione = S.buff_channel==chans(1);
nbuffs = sum(chanione);

% initialize 3-D data array for buffered data (nbuffers, bufferlen, nchans)
dat = zeros(nbuffs, S.buff_npoints, nchans, class(S.buff_data)); %#ok

% iterate over requested channels, preserving requested channel order
for k = 1:nchans,
    chan = chans(k);
    chani = S.buff_channel==chan;
    if sum(chani) ~= nbuffs,
        error('Mismatch in number of buffers for channel %d', chan)
    end
    
    % get (still buffered) data for each channel
    dat(:,:,k) = S.buff_data(chani,:);
end

% reshape buffered data into single columns, one per channel
% The one-liner below is equivalent to:
%     datp = permute(dat,[2 1 3]);
%     datpr = reshape(datp,[],nchans);
%     S.data = datpr;
%     clear datp datpr;
S.data = reshape(permute(dat,[2 1 3]), [], nchans);

% Process timestamps
ts = S.buff_timestamps(chanione);
% convert from TDT timestamps to 'seconds from block start'
ts = ts-ts_block_start;

if format_code == 0,    % Check for missing timestamps (one per buffer)
    ts_syn = linspace(ts(1),ts(end), numel(ts))'; % 'synthetic' timestamps
    S.max_ts_err = max(abs(ts_syn-ts));
    
    if S.max_ts_err > 1/S.sampling_rate;
        error('Timestamp error: at least one sample gap or repeat');
    end
    
    S.tstart = ts(1);
    S.tend = ts(end)+(S.buff_npoints-1)/S.sampling_rate;
    
    % Interpolate timestamps over entire file (more accurate than doing it
    % buffer-wise, since sample clock is exact).
    if return_timestamps,
        S.timestamps = ...
            linspace(ts(1),...
            ts(end)+(S.buff_npoints-1)/S.sampling_rate,...
            numel(S.data));
    end
    
elseif format_code == 4,
    S.timestamps = ts;
    % n/a, not sampled data
    S.tstart = NaN;
    S.tend = NaN;
    S.sampling_rate = NaN;
    S.max_ts_err = NaN;
else
    error('Unhandled TDT data format');
end

% Save out some TDT-specific info
info = struct(...
    'path_to_block', [],...
    'format_code', [],...
    't_block_start', [],...
    't_block_end', [],...
    't_block_start_UnixTime', [],...
    't_block_end_UnixTime', [],...
    't_block_start_UTC', [],...
    't_block_end_UTC', [],...
    'args',[]);
    
info.path_to_block = [filepath filesep tank filesep blk filesep];
info.args.timewin = timewin;
info.args.chans = chans;

info.format_code = format_code;
info.t_block_start = 0;
info.t_block_start_UnixTime = ts_block_start;
info.t_block_start_UTC = [datestr(info.t_block_start_UnixTime/86400 + datenum(1970,1,1)) 'Z'];

% last row is a special stop code, with timestamp of end of recording
info.t_block_end_UnixTime = data.timestamp(end);
info.t_block_end_UTC = [datestr(info.t_block_end_UnixTime/86400 + datenum(1970,1,1)) 'Z'];
info.t_block_end = info.t_block_end_UnixTime - info.t_block_start_UnixTime;

S.info = info;

% discard buffered data before returning
S = rmfield(S, {'buff_npoints', 'buff_channel', 'buff_data', 'buff_timestamps'});



