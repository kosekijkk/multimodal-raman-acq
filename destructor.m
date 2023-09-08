%% stop nidaq
global s hTaskAO hTaskDO exp evData

s.stop();release(s);delete(sListener);
hTaskAO.stop;hTaskDO.stop;
delete(hTaskAO);delete(hTaskDO);

%% stop pixis
delete(evData); %delete the listener when you are done or LF may crash
%when it opens again.
source.Dispose();
instance1.close; %close instance via this command (or you can just x the
delete(exp);

%% close shutter
dq = daq("ni");
addoutput(dq,"Dev1","port0/line0","Digital")

% close shutter
write(dq, 0)

daqreset