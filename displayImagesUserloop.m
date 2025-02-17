function [C,timingfile,userdefined_trialholder] = displayImagesUserloop(MLConfig,TrialRecord)

% default return value
C = [];
timingfile = 'displayImagesTiming.m';
userdefined_trialholder = '';

% Load the image stimuli and return timing file if it the very first call
persistent timing_filename_returned
persistent imageList
persistent imageNum
persistent stimList                 % List of stimuli left to display in a block
persistent stimPrev                 % List of stimuli of the current block displayed in the prev trial
persistent stimBorrow               % List of stimuli of the next block displayed in the prev trial
if isempty(timing_filename_returned)
    imageDir = dir('Images');                                       % get the folder content of "Images/"
    filename = {imageDir.name};                                     % get the filenames in "Images/"
    imageList = filename(contains(filename, '.png'));               % select only tif files (the list is not sorted by the image number order)
    imageNum = cellfun(@(x) sscanf(x, 'Image%d.png'), imageList);   % get the image number
    [imageNum, idxOrder] = sort(imageNum);                          % sort the image number list
    imageList = imageList(idxOrder);                                % sort the image list
    timing_filename_returned = true;
    return
end

stim_per_trial = TrialRecord.Editable.stim_per_trial;
% get current block and current condition
block = TrialRecord.CurrentBlock;
condition = TrialRecord.CurrentCondition;

if isempty(TrialRecord.TrialErrors)                                         % If its the first trial
    condition = 1;                                                          % set the condition # to 1
elseif ~isempty(TrialRecord.TrialErrors) && 0==TrialRecord.TrialErrors(end) % If the last trial is a success
    stimList = setdiff(stimList, stimPrev);                                 % remove previous trial stimuli from the list of stimuli
    condition = mod(condition+stim_per_trial-1, length(imageNum))+1;        % increment the condition # by stim_per_trial
end

% Initialize the conditions for a new block
if isempty(stimList)                                            % If there are no stimuli left in the block
    stimList = setdiff(imageNum, stimBorrow);                   % 
    stimBorrow = [];
    block=block+1;
end

if length(stimList)>=stim_per_trial                                         % If more than 2 stimuli left in the current block
    stimCurrent = datasample(stimList, stim_per_trial, 'Replace',false);    % randomly sample 3 stimuli from the list
    stimPrev = stimCurrent;                                    
else
    stimPrev = stimList;
    stimBorrow = datasample(imageNum, stim_per_trial-length(stimList), 'Replace', false);
    stimCurrent = [stimList stimBorrow];
    stimCurrent = stimCurrent(randperm(stim_per_trial));
end

% Set the stimuli
stim = cell(1,stim_per_trial);
for i=1:stim_per_trial
    stim{i} = fullfile('Images', imageList{stimCurrent(i)});
end

C = cell(1,stim_per_trial);
for i=1:stim_per_trial
    C{i} = sprintf('pic(%s,0,0)',stim{i});
end

TrialRecord.User.Stimuli = stimCurrent;                     % save the stimuli for the next trial in user variable
% Set the block number and the condition number of the next trial
TrialRecord.NextBlock = block;
TrialRecord.NextCondition = condition;