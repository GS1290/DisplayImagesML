function [C,timingfile,userdefined_trialholder] = displayImagesUserloop(MLConfig,TrialRecord)

% default return value
C = [];
timingfile = 'DisplayImagesTiming.m';
userdefined_trialholder = '';

% The very first call to this function is just to retrieve the timing
% filename before the task begins and we don't want to waste our preset
% values for this, so we just return if it is the first call.
persistent timing_filename_returned
if isempty(timing_filename_returned)
    timing_filename_returned = true;
    return
end

% load tif files from the Images folder (only once)
persistent image_list
persistent numImg
if 0==TrialRecord.CurrentTrialNumber
    imageDir = dir('Images');
    filename = {imageDir.name};
    image_list = filename(contains(filename, '.tif'));
    numImg = length(image_list);
end

block = TrialRecord.CurrentBlock;
condition = TrialRecord.CurrentCondition;

% Initialize the number of conditions for a block
persistent borrow_conditions
persistent condition_sequence
persistent prev_conditions
if isempty(condition_sequence)
    condition_sequence = 1:numImg;
    condition_sequence = setdiff(condition_sequence, borrow_conditions);
    block = block + 1;
end

if isempty(TrialRecord.TrialErrors)
    condition = condition+1;
% If the last trial is a success, remove those conditions from the sequence
elseif ~isempty(TrialRecord.TrialErrors) && 0==TrialRecord.TrialErrors(end)
    condition_sequence = setdiff(condition_sequence, prev_conditions);
    condition = condition+3;
end

% If there are more than 2 conditions left to show in the current block,
% sample 3 conditions
if length(condition_sequence)>=3
    condition_indices = datasample(condition_sequence, 3, 'Replace',false);
    prev_conditions = condition_indices;
else
    prev_conditions = condition_sequence;
    borrow_conditions = datasample(1:numImg, 3-length(condition_sequence), 'Replace', false);
    condition_indices = [condition_sequence borrow_conditions];
    condition_indices = condition_indices(randperm(3));
end

% Set the stimuli
stimuli1 = fullfile('Images', image_list{condition_indices(1)});
stimuli2 = fullfile('Images', image_list{condition_indices(2)});
stimuli3 = fullfile('Images', image_list{condition_indices(3)});

C = { 'fix(0,0)', ...
    sprintf('pic(%s,0,0)',stimuli1), ...
    sprintf('pic(%s,0,0)',stimuli2), ...
    sprintf('pic(%s,0,0)',stimuli3)};

% Set the block number and the condition number of the next trial. Since
% this userloop function provides the list of TaskObjects and timingfile
% names, ML does not need the block/condition number. They are just for
% your reference.
% However, if TrialRecord.NextBlock is -1, the task ends immediately
% without running the next trial.
TrialRecord.NextBlock = block;
TrialRecord.NextCondition = condition;
