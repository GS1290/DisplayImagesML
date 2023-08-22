function [C,timingfile,userdefined_trialholder] = displayImagesUserloop(MLConfig,TrialRecord)
% Userloop returns below three variables each trial to the timing script
C = [];                 % default return value
timingfile = 'displayImagesTiming.m';
userdefined_trialholder = '';

% Load the image stimuli and return timing file if it the very first call
persistent timing_filename_returned
persistent imageList
persistent imageNum
if isempty(timing_filename_returned)
    imageDir = dir('Images');                                       % stimuli are kept in "Images/"
    filename = {imageDir.name};
    imageList = filename(contains(filename, '.tif'));
    imageNum = cellfun(@(x) sscanf(x, 'Image%d.tif'), imageList);
    [imageNum, idxOrder] = sort(imageNum);
    imageList = imageList(idxOrder);
    timing_filename_returned = true;
    return
end

% get current block and current condition
block = TrialRecord.CurrentBlock;
condition = TrialRecord.CurrentCondition;

persistent stimList
persistent stimPrev
persistent stimBorrow

if isempty(TrialRecord.TrialErrors)                                         % If its the first trial
    condition = 1;                                                          % set the condition # to 1
elseif ~isempty(TrialRecord.TrialErrors) && 0==TrialRecord.TrialErrors(end) % If the last trial is a success
    stimList = setdiff(stimList, stimPrev);                                 % remove the previously presented conditions from the sequence
    condition = mod(condition+2, length(imageNum))+1;                       % increment the condition # by 3
end

% Initialize the conditions for a new block
if isempty(stimList)                                            % If there are no stimuli left in the block
    stimList = setdiff(imageNum, stimBorrow);
    stimBorrow = [];
    block=block+1;
end

if length(stimList)>=3                                          % If more than 2 conditions left in the sequence
    stimCurrent = datasample(stimList, 3, 'Replace',false);     % randomly sample 3 condtions from the sequence
    stimPrev = stimCurrent;                                    
else
    stimPrev = stimList;
    stimBorrow = datasample(imageNum, 3-length(stimList), 'Replace', false);
    stimCurrent = [stimList stimBorrow];
    stimCurrent = stimCurrent(randperm(3));
end

% Set the stimuli
stim1 = fullfile('Images', imageList{stimCurrent(1)});
stim2 = fullfile('Images', imageList{stimCurrent(2)});
stim3 = fullfile('Images', imageList{stimCurrent(3)});

C = { 'fix(0,0)', ...
    sprintf('pic(%s,0,0)',stim1), ...
    sprintf('pic(%s,0,0)',stim2), ...
    sprintf('pic(%s,0,0)',stim3)};

TrialRecord.User.Stimuli = stimCurrent;                     % save the stimuli for the next trial in user variable
% Set the block number and the condition number of the next trial
TrialRecord.NextBlock = block;
TrialRecord.NextCondition = condition;