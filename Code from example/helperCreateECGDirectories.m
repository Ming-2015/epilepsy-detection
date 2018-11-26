function helperCreateECGDirectories(ECGData,parentFolder,dataFolder)
    % This function is only intended to support the ECGAndDeepLearningExample.
    % It may change or be removed in a future release.

    rootFolder = parentFolder;
    localFolder = dataFolder;
    mkdir(fullfile(rootFolder,localFolder))

    folderLabels = unique(ECGData.Labels);
    for i = 1:numel(folderLabels)
        mkdir(fullfile(rootFolder,localFolder,char(folderLabels(i))));
    end
end