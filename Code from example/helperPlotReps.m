function helperPlotReps(ECGData)
    % This function is only intended to support the ECGAndDeepLearningExample.
    % It may change or be removed in a future release.

    folderLabels = unique(ECGData.Labels);
    figure;
    
    for k=1:3
        ecgType = folderLabels{k};
        ind = find(ismember(ECGData.Labels,ecgType));
        subplot(3,1,k);
        plot(ECGData.Data(ind(5),1:1000));
        grid on;
        title(ecgType);
    end
end