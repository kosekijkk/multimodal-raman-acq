function umanager_trigger_callback(src,event)
global exp

persistent dataBuffer trigActive trigMoment

% Store continuous acquisition data in persistent FIFO buffer dataBuffer
latestData = [event.TimeStamps, event.Data];
% fprintf("%f\n",latestData);
% If dataCapture is running for the first time, initialize persistent vars
if event.TimeStamps(1)==0
    fprintf("monitoring trigger\n");
    dataBuffer = [];          % data buffer
    trigActive = false;       % trigger condition flag
    trigMoment = [];          % data timestamp when trigger condition met
%     prevData = [];            % last data point from previous callback execution
else
%     if (event.TimeStamps(1)/100==floor(event.TimeStamps(1)/100))
%         fprintf("%s\n", event.TimeStamps(1))
%     end
    prevData = dataBuffer(end, :);

    trigConfig.Channel = 0;
    trigConfig.Level = 4; %V
    trigConfig.Slope = 50; %V/s

    [trigActive, trigMoment] = trigDetect(prevData, latestData, trigConfig);
end

dataBuffer = [dataBuffer; latestData];
bufferSize = 1000;
numSamplesToDiscard = size(dataBuffer,1) - bufferSize;
if (numSamplesToDiscard > 0)
    dataBuffer(1:numSamplesToDiscard, :) = [];
end

if trigActive
    disp("trigger detected")
%     disp(trigMoment)
    tic
    exp.Preview();
%     shutter = 1;
end

end