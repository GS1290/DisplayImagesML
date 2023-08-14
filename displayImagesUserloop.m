function [C,timingfile,userdefined_trialholder] = displayImagesUserloop(MLConfig,TrialRecord)

% default return value
C = [];
timingfile = 'DisplayImagesTiming.m';
userdefined_trialholder = '';

% Load the image stimuli and return timing file if it the very first call
persistent timing_filename_returned
persistent image_list
persistent image_num
persistent imageL
if isempty(timing_filename_returned)
    imageDir = dir('Images');
    filename = {imageDir.name};
    image_list = filename(contains(filename, '.tif'));
    image_num = cellfun(@(x) sscanf(x, 'Image%d.tif'), image_list);
    [image_num, idxOrder] = sort(image_num);
    image_list = image_list(idxOrder);
    imageL = length(image_list);
    timing_filename_returned = true;
    return
end

% get current block and current condition
block = TrialRecord.CurrentBlock;
condition = TrialRecord.CurrentCondition;

persistent borrow_conditions
persistent condition_sequence
persistent prev_conditions

if isempty(TrialRecord.TrialErrors)     % If its the first trial
    condition = 1;                      % set the condition # to 1
elseif ~isempty(TrialRecord.TrialErrors) && 0==TrialRecord.TrialErrors(end) % If the last trial is a success
    condition_sequence = setdiff(condition_sequence, prev_conditions);      % remove the previously presented conditions from the sequence
    condition = mod(condition+2, imageL)+1;                                 % increment the condition # by 3
end

% Initialize the conditions for a new block
if isempty(condition_sequence)
    condition_sequence = 1:imageL;
    condition_sequence = setdiff(condition_sequence, borrow_conditions);
    borrow_conditions = [];
    block = block + 1;
end

if length(condition_sequence)>=3                                            % If more than 2 conditions left in the sequence
    condition_indices = datasample(condition_sequence, 3, 'Replace',false); % randomly sample 3 condtions from the sequence
    prev_conditions = condition_indices;                                    
    TrialRecord.User.Stimuli = condition_indices;                           % save the conditions in user variable
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

% Set the block number and the condition number of the next trial
TrialRecord.NextBlock = block;
TrialRecord.NextCondition = condition;
