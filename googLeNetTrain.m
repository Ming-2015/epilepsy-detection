%% Create the image datastore
allImages = imageDatastore(fullfile('nonPredictiveScalograms'),...
    'IncludeSubfolders',true,...
    'LabelSource','foldernames');

%% divide our data into training data and validation data (to prevent overfitting)
rng default
[imgsTrain,imgsValidation] = splitEachLabel(allImages,0.8,'randomized');
disp(['Number of training images: ',num2str(numel(imgsTrain.Files))]);
disp(['Number of validation images: ',num2str(numel(imgsValidation.Files))]);

%% Create a new googLeNet pre-trained neural network
net = googlenet;
lgraph = layerGraph(net);

%% Modify the last 4 layers to fit our output needs
lgraph = removeLayers(lgraph,{'pool5-drop_7x7_s1','loss3-classifier','prob','output'});

numClasses = numel(categories(imgsTrain.Labels));
newLayers = [
    dropoutLayer(0.6,'Name','newDropout')
    fullyConnectedLayer(numClasses,'Name','fc','WeightLearnRateFactor',5,'BiasLearnRateFactor',5)
    softmaxLayer('Name','softmax')
    classificationLayer('Name','classoutput')];
lgraph = addLayers(lgraph,newLayers);

lgraph = connectLayers(lgraph,'pool5-7x7_s1','newDropout');
inputSize = net.Layers(1).InputSize;

%% Plot the current Neural network graph
numberOfLayers = numel(lgraph.Layers);
figure('Units','normalized','Position',[0.1 0.1 0.8 0.8]);
plot(lgraph)
title(['GoogLeNet Layer Graph: ',num2str(numberOfLayers),' Layers']);

%% determine the options used for the training process... 
% Note that choosing the MaxEpochs is not trivial as too much ->
% overfitting and too little -> underfitting
options = trainingOptions('sgdm',...
    'MiniBatchSize',15,...
    'MaxEpochs',20,...
    'InitialLearnRate',1e-4,...
    'ValidationData',imgsValidation,...
    'ValidationFrequency',10,...
    'ValidationPatience',Inf,...
    'Verbose',1,...
    'ExecutionEnvironment','gpu',...
    'Plots','training-progress');

%% train the googLeNet based on our data
rng default
trainedNonPredictiveGn = trainNetwork(imgsTrain,lgraph,options);

%% Evaluate GoogLeNet Accuray based on the validation data
[YPred,probs] = classify(trainedGN,imgsValidation);
nonPredictiveGnAccuracy = mean(YPred==imgsValidation.Labels);
display(['GoogLeNet Accuracy: ',num2str(accuracy)]);

