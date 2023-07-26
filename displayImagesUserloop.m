function [C,timingfile,userdefined_trialholder] = displayImagesUserloop(MLConfig,TrialRecord)

% A userloop file is a MATLAB function that provides information of the
% next trial (stimuli, timing file name, condition number, block number,
% etc.), instead of the conditions file, the condition selection file,
% the block selection file and the error handling logic. It helps users
% compose a task in a more flexible way, without being restricted by the
% conditions file structure.
%
% Users can load a userloop file (*.m) from the conditions file selection
% dialog in the main menu, as when loading a normal conditions file. The
% conditions file dialog looks for text files (*.txt), by default, so,
% to make things easier, you can make a text file, write the name of the
% userloop file in it and choose that text file instead.
%
% When a userloop file is loaded, the main menu displays nothing but
% 'user-defined' in the stimulus list box and the timing files box, but the
% run button becomes enabled so that you can start the task. Then, it is
% the userloop's job to supply stimuli and timing files.

% A userloop function has two input arguments, MLConfig and TrialRecord.
% MLConfig has the current settings of ML and TrialRecord keeps the numbers
% related to the current trial and the performance history.
% Note that the numbers in TrialRecord are not updated for the next trial
% until the userloop is finished. For example, while in the userloop,
% TrialRecord.CurrentTrialNumber is 0 although the trial that we are about
% to execute is Trial 1.
%
% Another important thing to know is that the userloop is called twice
% before Trial 1 starts: once before the pause menu shows up (MonkeyLogic
% does that, to retrieve the timingfile name(s)) and once immediately before
% Trial 1. So be careful, when writing the code, not to waste your preset
% conditions in the very first call. See the code below for a trick to
% avoid this issue.

% Set the block number and the condition number of the trial, like the
% following. These numbers are just for users' information and ML does not
% use them, since this userloop determined the stimulus list and the timing
% script.
% If you assign -1 to TrialRecord.NextBlock, the task will be aborted
% without running the next trial.
%
%   TrialRecord.NextBlock = no;
%   TrialRecord.NextCondition = no;
%
% It is no longer allowed to add new fields to TrialRecord directly. Use
% the 'User' field instead. This is because TrialRecord is now a MATLAB
% class object, not a struct.
%
%   TrialRecord.NewField = 1;       % error
%   TrialRecord.User.NewField = 1;  % good

% In the conditions file, some extra information of the condition can be
% delievered with the Info field.
%
%   Condition   Block   Frequency   Timing File     Info
%   1           1       1           grating         'deg',45
%
% To deliver the same information using the userloop, create a struct
% yourself and call the TrialRecord.setCurrentConditionInfo(struct)
% function.
%
%   a.deg = 45;
%   TrialRecord.setCurrentConditionInfo(a);

% Three output arguments of the userloop function are the taskobjects ("C"),
% the timing file name and the user-defined trialholder name.
%
% The taskobjects can be specified in two ways. One is to use a cell char
% array and the other is to use a struct array. Refer to the following
% examples.
%
% ----- a cell char array example -----
% C = { 'fix(0,0)', 'pic(A.jpg,0,0,320,240,[0 0 0])', 'mov(B.avi,0,0)', ...
%       'crc(0.5,[1 0 0],1,-7,0)', 'sqr([0.6 0.3],[0 0 1],1,7,0)', ...
%       'snd(C.wav)', 'stm(2,D.mat,1)', 'ttl(3)', 'gen(E.m,0,0)' };
%

% The user-defined trialholder is not necessary for most of users, so just
% leave it empty.

% This example task runs two blocks of a delayed match-to-sample task.
% Block 1 uses A.BMP and B.BMP as stimuli and Block 2, C.BMP and D.BMP.
% Each block has 4 possible conditions, depending on which image becomes
% the sample and where the sample is presented (left or right).
% The order of the conditions is randomized (with replacement) and an error
% trials is repeated immediately. The blocks are alternated every 20
% correct responses.

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

% constants
imageDir = dir('Images');
filename = {imageDir.name};
image_list = filename(contains(filename, '.tif'));
numImg = length(image_list);

block = TrialRecord.CurrentBlock;
chosen_configuration = TrialRecord.CurrentCondition;

% Set a new condition if this is the first trial or the last trial was
% answered correctly. If the last trial failed, then the inside of the IF
% statement is skipped so the same condition is repeated.
persistent condition_sequence
if isempty(TrialRecord.TrialErrors) || 0==TrialRecord.TrialErrors(end)
    correct_trial_count = sum(0==TrialRecord.TrialErrors);
    
    % Increase the block number after 20 correct trials
    block = mod(floor(correct_trial_count/(numImg)),2) + 1;
    
    % Select the next condition randomly
    condition_index = mod(correct_trial_count,numImg) + 1;
    if 1==condition_index, condition_sequence = randperm(numImg); end
    chosen_configuration = condition_sequence(condition_index);
end

% configuration_index = (block-1)*4 + condition;
% chosen_configuration = configuration(configuration_index,:);

% Set the stimuli
stimuli1 = fullfile('Images', image_list{chosen_configuration});
stimuli2 = fullfile('Images', image_list{chosen_configuration});
stimuli3 = fullfile('Images', image_list{chosen_configuration});

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
TrialRecord.NextCondition = chosen_configuration;
