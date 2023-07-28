function [C,timingfile,userdefined_trialholder] = displayImagesUserloop(MLConfig,TrialRecord)

% default return value
C = [];
timingfile = 'DisplayImagesTiming.m';
userdefined_trialholder = '';

% Return timing file if it the very first call
persistent timing_filename_returned
if isempty(timing_filename_returned)
    timing_filename_returned = true;
    return
end

% load tif files from the Images folder (only once)
persistent image_list
persistent image_num
persistent imageL
if 0==TrialRecord.CurrentTrialNumber
    imageDir = dir('Images');
    filename = {imageDir.name};
    image_list = filename(contains(filename, '.tif'));
    image_num = cellfun(@(x) sscanf(x, 'Image%d.tif'), image_list);
    [image_num, idxOrder] = sort(image_num);
    image_list = image_list(idxOrder);
    imageL = length(image_list);
end

block = TrialRecord.CurrentBlock;
condition = TrialRecord.CurrentCondition;

% Initialize the number of conditions for a block
persistent borrow_conditions
persistent condition_sequence
persistent prev_conditions

if isempty(TrialRecord.TrialErrors)
    condition = condition+1;
% If the last trial is a success, remove those conditions from the sequence
elseif ~isempty(TrialRecord.TrialErrors) && 0==TrialRecord.TrialErrors(end)
    condition_sequence = setdiff(condition_sequence, prev_conditions);
    condition = mod(condition+2, imageL)+1;
end

if isempty(condition_sequence)
    condition_sequence = 1:imageL;
    condition_sequence = setdiff(condition_sequence, borrow_conditions);
    borrow_conditions = [];
    block = block + 1;
end


% If there are more than 2 conditions left to show in the current block,
% sample 3 conditions
if length(condition_sequence)>=3
    condition_indices = datasample(condition_sequence, 3, 'Replace',false);
    prev_conditions = condition_indices;
    TrialRecord.User.Stimuli = condition_indices;
else
    prev_conditions = condition_sequence;
    borrow_conditions = datasample(1:imageL, 3-length(condition_sequence), 'Replace', false);
    condition_indices = [condition_sequence borrow_conditions];
    condition_indices = condition_indices(randperm(3));
    TrialRecord.User.Stimuli = condition_indices;
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
