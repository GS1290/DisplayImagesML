% DisplayImagesTiming file

% Note:
% Using the scene based framework to display the stimuli. If this
% does not work on your PC, please update the Monkeylogic.
% Tested on MonkeyLogic Version 2.2.32 (Jan7, 2023)

% Dependency alert: Make sure the alert function and the relevant audio
% files are present in the same folder as the conditions file.

hotkey('x', 'escape_screen(); assignin(''caller'',''continue_'',false);'); % stop the task immediately if x is pressed
set_bgcolor([0.5 0.5 0.5]);                                         % sets subject screen background color to Gray
editable('pulseDuration','fix_radius');         % adds the variables on the Control screen to make on the fly changes
bhv_variable('Stimuli', TrialRecord.User.Stimuli);

% Task Mode
% detect an available tracker
if exist('eye_','var'), tracker = eye_;
else, error('This task requires eye input. Please set it up or turn on the simulation mode.');
end

% Mapping to the TaskObjects defined in the conditions file
fixation_point = 1;
stimulus1 = 2;
stimulus2 = 3;
stimulus3 = 4;

% time intervals (in ms):
wait_for_fix = 1000;
initial_fix = 1000;
stimulus_duration = 800;
isi_duration = 700;
pulseDuration = 50;

% fixation window (in degrees):
fix_radius = [3 3];
hold_radius = fix_radius ;

% creating Scenes
% Adapter to play audio at the start of the trial
sndTrialStart = AudioSound(null_);
sndTrialStart.List = 'trialStart.wav';      % wav file
sndTrialStart.PlayPosition = 0;             % play from 0 sec

% Adapter to play audio when the fixation is acquired
sndAquireStart = AudioSound(null_);
sndAquireStart.List = 'acquireStart.wav';   % wav file
sndAquireStart.PlayPosition = 0;            % play from 0 sec

% scene 1: wait for fixation
fix1 = SingleTarget(tracker);   % We use eye signals (eye_) for tracking. The SingleTarget adapter
fix1.Target = fixation_point;   % Set fixation point as the target
fix1.Threshold = fix_radius;    % Examines if the gaze is in the Threshold window around the Target.
wth1 = WaitThenHold(fix1);      % 
wth1.WaitTime = wait_for_fix;   % 
wth1.HoldTime = 1;              %
wth1.AllowEarlyFix = false;     % End the scene if the monkey is fixating before the scene starts
con1 = Concurrent(wth1);        %
con1.add(sndTrialStart);        % Start the trial and concurrently play the trialStart audio

scene1 = create_scene(con1,fixation_point);     % In this scene, we will present the fixation_point (TaskObject #1)
                                                % and wait for fixation.

% scene 2: hold fixation
fix2 = SingleTarget(tracker);   % We use eye signals (eye_) for tracking. The SingleTarget adapter
fix2.Target = fixation_point;   % Set fixation point as the target
fix2.Threshold = fix_radius;    % Examines if the gaze is in the Threshold window around the Target.
wth2 = WaitThenHold(fix2);      %
wth2.WaitTime = 0;              % 
wth2.HoldTime = initial_fix;    %
con2 = Concurrent(wth2);
con2.add(sndAquireStart);

scene2 = create_scene(con2,fixation_point);     % In this scene, we will present the fixation_point (TaskObject #1)
                                                % and hold fixation for 1000ms.

% scene 3: present stimulus 1
fix3 = SingleTarget(tracker);
fix3.Target = fixation_point;
fix3.Threshold = hold_radius;
wth3 = WaitThenHold(fix3);
wth3.WaitTime = 0;              % We already knows the fixation is acquired, so we don't wait.
wth3.HoldTime = stimulus_duration;

sceneStimulus1 = create_scene(wth3,[fixation_point stimulus1]);

% scene 4: present stimulus 2
fix4 = SingleTarget(tracker);
fix4.Target = fixation_point;
fix4.Threshold = hold_radius;
wth4 = WaitThenHold(fix4);
wth4.WaitTime = 0;              % We already knows the fixation is acquired, so we don't wait.
wth4.HoldTime = stimulus_duration;
sceneStimulus2 = create_scene(wth4,[fixation_point stimulus2]);

% scene 5: present stimulus 3
fix5 = SingleTarget(tracker);
fix5.Target = fixation_point;
fix5.Threshold = hold_radius;
wth5 = WaitThenHold(fix5);
wth5.WaitTime = 0;             % We already knows the fixation is acquired, so we don't wait.
wth5.HoldTime = stimulus_duration;
sceneStimulus3 = create_scene(wth5,[fixation_point stimulus3]);

% scene 6: ISI
fix6 = SingleTarget(tracker);
fix6.Target = fixation_point;
fix6.Threshold = hold_radius;
wth6 = WaitThenHold(fix6);
wth6.WaitTime = 0;
wth6.HoldTime = isi_duration;
sceneISI = create_scene(wth6, fixation_point);

% TASK:
error_type = 0;

run_scene(scene1);          % Run the first scene (eventmaker 10)
if ~wth1.Success            % If the WithThenHold failed (fixation is not acquired)
    error_type = 4;         % If so, fixation was never made and therefore this is a "no fixation (4)" error.
end

if 0==error_type
    run_scene(scene2,10);
    if ~wth2.Success        % If the WithThenHold failed (fixation is broken)
        error_type = 3;     % If so this is a "break fixation (3)" error.
    end                      
end

if 0==error_type
    run_scene(sceneStimulus1,20);   % Run the scene for presenting 1st stimulus (eventmarker 20)
    if ~wth3.Success                % The failure of WithThenHold indicates that the subject didn't maintain fixation on the stimulus.
        error_type = 3;             % So it is a "break fixation (3)" error.
    end
end

if 0==error_type
    run_scene(sceneISI,10);
    if ~wth6.Success
        error_type = 3;
    end
end

if 0==error_type
    run_scene(sceneStimulus2,20);   % Run the scene for presenting 2nd stimulus (eventmarker 20)
    if ~wth4.Success                % The failure of WithThenHold indicates that the subject didn't maintain fixation on the stimulus.
        error_type = 3;             % So it is a "break fixation (3)" error.
    end
end

if 0==error_type
    run_scene(sceneISI,10);
    if ~wth6.Success
        error_type = 3;
    end
end

if 0==error_type
    run_scene(sceneStimulus3,20);   % % Run the scene for presenting 3rd stimulus (eventmarker 20)
    if ~wth5.Success                % The failure of WithThenHold indicates that the subject didn't maintain fixation on the stimulus.
        error_type = 3;             % So it is a "break fixation (3)" error.
    end
end

% reward
if 0==error_type
    idle(0);                % Clear screens
    goodmonkey(pulseDuration, 'juiceline',1, 'numreward',1, 'pausetime',0, 'eventmarker',50);   % used-defined amount of juice
else
    idle(700);              % Clear screens
end

trialerror(error_type);     % Add the result to the trial history
set_iti(1000);
