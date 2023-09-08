%% Experiment parameters
global save_dir
% save_dir = "H:\My Drive\Live-cellTranscriptomics\RamanHCR\Reprogramming\Timelapse_5K_rev4_220625\D11\";
% save_dir = "C:\Users\Raman\Desktop\Giulia\Marzo 03_glianeu\Las2nd\";
save_dir = "H:\My Drive\Live-cellTranscriptomics\RamanHCR\mESCs\phototoxicity\20220912\";

% exposure time in msec
% exposure = 3; %for 20x20, 4sec is needed in micromanager
% exposure = 1000;
exposure = 20;
% exposure = 10000;

power = "220deg";

% readout mode
readout_setting = 'Pixis'; %100KHz 16msec readout
% readout_setting = 'Pixis_2MHz'; %2MHz 2.8msec readout

% scanning range of galvano mirrors
% max_volt = 0.3; % ~37.5% of entire FOV without clipping
% min_volt = -0.3;

% max_volt = 0.2; % ~25% of entire FOV without clipping
% min_volt = -0.2;

% number of frames per point
global n_frames
n_frames = 1;

max_volt = 0.4;
min_volt = -0.4;

% max_volt = 0.2; % ~50% of entire FOV without clipping
% min_volt = -0.2;

% max_volt = 0.5; % ~80% of entire FOV without clipping
% min_volt = -0.5;

% max_volt = 0.05; % ~20um of entire FOV without clipping
% min_volt = -0.05;


% number of steps for each galvano mirror
global x_steps y_steps
% x_steps = 72;
% y_steps = 72;

% x_steps = 46;
% y_steps = 46;

% x_steps = 60;
% y_steps = 60;

% x_steps = 70;
% y_steps = 70;

x_steps = 100;
y_steps = 100;


% x_steps = 144;
% y_steps = 144;
% x_steps = 20;
% y_steps = 20;


global exp_name
% exp_name = "5W_"+(max_volt-min_volt)+"V_"+x_steps+"steps20_"+exposure+"10msec_z4955";
% exp_name = power+"_"+(max_volt-min_volt)+"V_"+x_steps+"steps_"+exposure+"msec";
exp_name = power+"_"+(max_volt-min_volt)+"V_"+x_steps+"steps_"+exposure+"msec_"+n_frames;
% exp_name = power+"_"+(max_volt-min_volt)+"V_"+x_steps+"steps_"+exposure+"msec_"+n_frames+"ORG11_2_GN";

global raman_peak
raman_peak = 668;

% number of scans conducted
global sample_num
sample_num = 0;

% allocate matrix to store spectra
global data
data = NaN(x_steps*y_steps*n_frames,1340);

% voltage outputs for galvano mirrors
% x_outs = repmat(linspace(min_volt, max_volt, x_steps)',y_steps,1);
saw = [linspace(min_volt, max_volt, x_steps)';flip(linspace(min_volt, max_volt, x_steps)')];
x_outs = repmat(saw,y_steps/2,1);

y_outs = repmat(linspace(min_volt, max_volt, y_steps),x_steps,1);
y_outs = y_outs(:);

% end at 0 volts so that at the end output returns to zero
x_outs = [x_outs;0];
y_outs = [y_outs;0];

% digital outputs for shutter
shutter = ones(x_steps*y_steps,1);
% 
% close shutter at end of acquisition
shutter = [shutter;0];

global i
i=0;

%% Pixis initialization

Setup_LightField_Environment;


instance1=lfm(true);
instance1.load_experiment(readout_setting);

instance1.set_exposure(exposure);
instance1.set_frames(1);

% setup Pixis callback listener
global exp
exp=instance1.application.Experiment;
application = instance1.application;

global evData
if device_loaded(exp)
    exp.Preview();
    exp.Stop(); %start and stop a preview to generate a display
    display = application.DisplayManager;
    view = display.GetDisplay(PrincetonInstruments.LightField.AddIns.DisplayLocation.ExperimentWorkspace, 0);
    source = view.LiveDisplaySource;

    evData = addlistener(exp,'ImageDataSetReceived',@(src,evnt)experimentDataReady(src,evnt,source));
    %%Matlab now has an event listener hooked to the live data acquired
    %%event in the LF automation class. As per the callback function, the
    %%value of the 200th pixel will be printed every time there is an
    %%incoming set.
    %%To see this event listener work, hit Preview in the LightField
    %%window. Will also work with Take one Look.
end


%% nidaq setup
AOchannels = [0,1];
AIchannels = 7;
sampleRate = 10000;
numSamplesPerChannel = length(shutter);%x_steps*y_steps+2;

devName = 'Dev1';
sampleClockSource = 'PFI0';
triggerChannel = 'PFI0';

% Analog trigger input from micromanager to start Pixis camera
global s
s = daq.createSession('ni');
addAnalogInputChannel(s,'Dev1',AIchannels,'Voltage');
sListener = addlistener(s, 'DataAvailable', @umanager_trigger_callback);
s.IsContinuous = true;

% Analog output for galvano mirror
global hTaskAO
hTaskAO = dabs.ni.daqmx.Task('galvoAO');
hTaskAO.createAOVoltageChan(devName, AOchannels, [], -10, 10);
% hTaskAO.cfgDigEdgeStartTrig(triggerChannel,'DAQmx_Val_Rising');
% hTaskAO.set('startTrigRetriggerable',1);
hTaskAO.cfgSampClkTiming(sampleRate,'DAQmx_Val_FiniteSamps',numSamplesPerChannel, ...
    sampleClockSource,'DAQmx_Val_Falling');
hTaskAO.cfgOutputBuffer(numSamplesPerChannel);

% Digital output for shutter
global hTaskDO
hTaskDO = dabs.ni.daqmx.Task('shutterDO');
hTaskDO.createDOChan(devName,'port0/line0');
% hTaskDO.cfgDigEdgeStartTrig(triggerChannel,'DAQmx_Val_Rising');
% hTaskDO.set('startTrigRetriggerable',1);
hTaskDO.cfgSampClkTiming(sampleRate,'DAQmx_Val_FiniteSamps',numSamplesPerChannel, ...
    sampleClockSource,'DAQmx_Val_Falling');
hTaskDO.cfgOutputBuffer(numSamplesPerChannel);

% start and wait for trigger from umanager
startBackground(s);

% autostart false
hTaskAO.writeAnalogData([x_outs, y_outs], Inf, false);
hTaskDO.writeDigitalData(shutter, Inf, false);

hTaskAO.start;
hTaskDO.start;
