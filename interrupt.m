% interrupt and stop acquisition
global exp
exp.Stop();

% stop nidaq
global hTaskAO hTaskDO

hTaskDO.writeDigitalData(0);

hTaskAO.stop;hTaskDO.stop;
delete(hTaskAO);delete(hTaskDO);
