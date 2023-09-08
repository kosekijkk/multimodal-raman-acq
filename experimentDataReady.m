function experimentDataReady(src,evnt,varargin)
global data exp save_dir exp_name sample_num i hTaskAO hTaskDO x_steps y_steps raman_peak n_frames

if i==0
    tic
%     skip first data frame as the shutter is not open yet
    i=1;
    for k=1:n_frames
        tmp = uint16(varargin{1}.ImageDataSet.GetFrame(0,0).GetData());
        fprintf("%d\n", tmp(1))
    end
    fprintf("0 out of %d\n", y_steps);
elseif (i<size(data,1)/n_frames)
%     deep copy spectrum into data matrix

    for k=1:n_frames
        data(n_frames*(i-1)+k,:) = uint16(varargin{1}.ImageDataSet.GetFrame(0,0).GetData());
    end

    if (mod(i, x_steps)==0)
        fprintf("%d out of %d\n",i/x_steps, y_steps);
    end
    i=i+1;
else
    for k=1:n_frames
        data(n_frames*(i-1)+k,:) = uint16(varargin{1}.ImageDataSet.GetFrame(0,0).GetData());
    end
%     data(i,:) = uint16(varargin{1}.ImageDataSet.GetFrame(0,0).GetData());
    fprintf("%d out of %d\n",i/x_steps, y_steps);
    fprintf("closing %d\n",sample_num);
%     exp.Stop is not immediate and the logic output of next frame from
%     camera can cause false triggering. stopping here and immediately
%     starting afterwards can prevent that
    hTaskAO.stop;
    hTaskDO.stop;
    
    exp.Stop();
    
    writematrix(data,fullfile(save_dir,exp_name+"_"+sample_num+".dat"), 'Delimiter', '\t');
    sample_num=sample_num+1;
    i=0;

%     data_2D = flip(transpose(flip(reshape(data(:,669), x_steps, y_steps))));
%     figure;imshow(mat2gray(data_2D), 'InitialMagnification', 'fit')
%     
%     pause here just in case exp.Stop hasn't completed
    pause(0.5);
    
%     data_2D = reshape(data(:,raman_peak), x_steps, y_steps);
    data_2D = reshape(data(1:n_frames:end,raman_peak), x_steps, y_steps);
    data_2D(:,2:2:end) = flipud(data_2D(:,2:2:end));
    data_2D = flip(transpose(flip(data_2D)));
    
%     data_2D = flip(transpose(flip(reshape(data(:,raman_peak), x_steps, y_steps))));
    figure;imshow(mat2gray(data_2D), 'InitialMagnification', 'fit')
    
    toc
    hTaskAO.start;
    hTaskDO.start;
    
end

end
