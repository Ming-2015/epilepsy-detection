%% Create the image datastore
allImages = imageDatastore(fullfile(parentDir,dataDir),...
    'IncludeSubfolders',true,...
    'LabelSource','foldernames');

%% divide our data into training data and validation data (to prevent overfitting)
rng default
[imgsTrain,imgsValidation] = splitEachLabel(allImages,0.8,'randomized');
disp(['Number of training images: ',num2str(numel(imgsTrain.Files))]);
disp(['Number of validation images: ',num2str(numel(imgsValidation.Files))]);

%% initialize AlexNet
alex = alexnet;
layers = alex.Layers;

%% Modify AlexNet layers to match our output results
layers(23) = fullyConnectedLayer(3);
layers(25) = classificationLayer;

%% resize the imagesfor AlexNet
inputSize = alex.Layers(1).InputSize;
augimgsTrain = augmentedImageDatastore(inputSize(1:2),imgsTrain);
augimgsValidation = augmentedImageDatastore(inputSize(1:2),imgsValidation);

%% Set Training options
rng default
mbSize = 10;
mxEpochs = 10;
ilr = 1e-4;
plt = 'training-progress';

opts = trainingOptions('sgdm',...
    'InitialLearnRate',ilr, ...
    'MaxEpochs',mxEpochs ,...
    'MiniBatchSize',mbSize, ...
    'ValidationData',augimgsValidation,...
    'ExecutionEnvironment','cpu',...
    'Plots',plt);

%% Begin training
trainedAN = trainNetwork(augimgsTrain,layers,opts);