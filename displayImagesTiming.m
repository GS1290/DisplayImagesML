% displayImagesTiming file
hotkey('x', 'escape_screen(); assignin(''caller'',''continue_'',false);');  % stop the task immediately if x is pressed
set_bgcolor([0.5 0.5 0.5]);                                                 % sets subject screen background color to Gray
editable('pulse_duration','fix_radius');                                    % adds the variables on the Control screen to make on-the-fly changes
bhv_variable('Stimuli', TrialRecord.User.Stimuli);                          % Save the current stimuli in data.UserVars variable

% Initializing task variables
if exist('eye_','var'), tracker = eye_;     % detect an available tracker
else, error('This task requires eye input. Please set it up or turn on the simulation mode.');
end

% Mapping to the TaskObjects defined in the userloop
fixation_point = 1;
stim1 = 2;
stim2 = 3;
stim3 = 4;

% time intervals (in ms):
wait_for_fix = 1000;
hold_fix = 1000;
stimulus_duration = 800;
isi_duration = 700;
pulse_duration = 50;

% fixation window (in degrees):
fix_radius = [3 3];
hold_radius = fix_radius ;

% creating Scenes
% Adapter to play audio at the start of the trial
sndTrialStart = AudioSound(null_);
sndTrialStart.List = 'Audio\trialStart.wav';      % wav file
sndTrialStart.PlayPosition = 0;             % play from 0 sec

% Adapter to play audio when the fixation is acquired
sndAquireStart = AudioSound(null_);
sndAquireStart.List = 'Audio\acquireStart.wav';   % wav file
sndAquireStart.PlayPosition = 0;            % play from 0 sec

% sceneFix: wait for fixation
fix1 = SingleTarget(tracker);   % We use eye signals (eye_) for tracking. The SingleTarget adapter
fix1.Target = fixation_point;   % Set fixation point as the target
fix1.Threshold = fix_radius;    % Examines if the gaze is in the Threshold window around the Target.
wth1 = WaitThenHold(fix1);      % 
wth1.WaitTime = wait_for_fix;   % 
wth1.HoldTime = 1;              %
wth1.AllowEarlyFix = false;     % End the scene if the monkey is fixating before the scene starts
con1 = Concurrent(wth1);        %
con1.add(sndTrialStart);        % Start the trial and concurrently play the trialStart audio

sceneFix = create_scene(con1,fixation_point);   % In this scene, we will present the fixation_point (TaskObject #1)
                                                % and wait for fixation.

% sceneHold: hold fixation
fix2 = SingleTarget(tracker);   % We use eye signals (eye_) for tracking. The SingleTarget adapter
fix2.Target = fixation_point;   % Set fixation point as the target
fix2.Threshold = fix_radius;    % Examines if the gaze is in the Threshold window around the Target.
wth2 = WaitThenHold(fix2);      %
wth2.WaitTime = 0;              % 
wth2.HoldTime = hold_fix;
con2 = Concurrent(wth2);
con2.add(sndAquireStart);

sceneHold = create_scene(con2,fixation_point);  % In this scene, we will present the fixation_point (TaskObject #1) and hold fixation for 1000ms.

% sceneStim: present stimulus
fix3 = SingleTarget(tracker);
fix3.Target = fixation_point;
fix3.Threshold = hold_radius;
wth3 = WaitThenHold(fix3);
wth3.WaitTime = 0;                              % We already knows the fixation is acquired, so we don't wait.
wth3.HoldTime = stimulus_duration;

sceneStim1 = create_scene(wth3,[fixation_point stim1]); % present stimulus 1
sceneStim2 = create_scene(wth3,[fixation_point stim2]); % present stimulus 2
sceneStim3 = create_scene(wth3,[fixation_point stim3]); % present stimulus 3

% sceneISI: hold fixation until next stimulus
fix4 = SingleTarget(tracker);
fix4.Target = fixation_point;
fix4.Threshold = hold_radius;
wth4 = WaitThenHold(fix4);
wth4.WaitTime = 0;
wth4.HoldTime = isi_duration;
sceneISI = create_scene(wth4, fixation_point);

% TASK:
error_type = 0;

while true
    run_scene(sceneFix);                            % Run the first scene (eventmaker 10)
    if ~wth1.Success; error_type = 4; break; end    % If the WithThenHold failed (fixation is not acquired), fixation was never made and therefore this is a "no fixation (4)" error.
    
    run_scene(sceneHold,10);
    if ~wth2.Success; error_type = 3; break; end    % If the WithThenHold failed (fixation is broken), this is a "break fixation (3)" error.
    
    run_scene(sceneStim1,20);                       % Run the scene for presenting 1st stimulus (eventmarker 20)
    if ~wth3.Success; error_type = 3; break; end    % The failure of WithThenHold indicates that the subject didn't maintain fixation on the stimulus.
    
    run_scene(sceneISI,10);
    if ~wth4.Success; error_type = 3; break; end
    
    run_scene(sceneStim2,20);                       % Run the scene for presenting 2nd stimulus (eventmarker 20)
    if ~wth3.Success; error_type = 3; break; end    % The failure of WithThenHold indicates that the subject didn't maintain fixation on the stimulus.
    
    run_scene(sceneISI,10);
    if ~wth4.Success; error_type = 3; break; end
    
    run_scene(sceneStim3,20);                       % Run the scene for presenting 3rd stimulus (eventmarker 20)
    if ~wth3.Success; error_type = 3; break; end    % The failure of WithThenHold indicates that the subject didn't maintain fixation on the stimulus.
    
    idle(0);                                        % Clear screens
    goodmonkey(pulse_duration, 'juiceline',1, 'numreward',1, 'pausetime',0, 'eventmarker',50);   % used-defined amount of juice
    break
end

if 0~=error_type; idle(700); end
trialerror(error_type);     % Add the result to the trial history
set_iti(1000);
