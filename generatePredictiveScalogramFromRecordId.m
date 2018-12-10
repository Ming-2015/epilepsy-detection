function generatePredictiveScalogramFromRecordId( listRecordId, folderName, varName )
    %% Initialize some variables
    EyeSideNames	=	{'LeftEye','RightEye'};
    VarNames	=	{varName, 'eyeOpen'};
    imageRoot = fullfile( folderName );
    [~,count] = size( listRecordId );
    
    %% Make sure the folders exist; if not, create them
    if (~exist(folderName,'dir'))
        mkdir( fullfile(folderName) );
    end
    if (~exist(fullfile(folderName, 'willBeMostlyEyeClosed'), 'dir'))
        mkdir( fullfile(folderName, 'willBeMostlyEyeClosed') );
    end
    if (~exist(fullfile(folderName, 'willBeMostlyEyeOpened'), 'dir'))
        mkdir( fullfile(folderName, 'willBeMostlyEyeOpened') );
    end
    
    imgCount = 0;
    imgOpen = 0;
    imgClose = 0;
    
    %% Iterate over all the records provided
    for idx = 1:count
        %% Load the pre-saved files
        FName       =   listRecordId(idx);
        FileName	=	strcat('AIML/Eye_epilepsy/Data/sorted/', FName,'/', FName, '_reduced.mat');
        LS			=	load(FileName);
        
        %% Extract some variables from the file
        varStr_varName = [EyeSideNames{1} '_' VarNames{1}];
        varStr_open = [EyeSideNames{1} '_' VarNames{2}];
        variable = LS.(varStr_varName);
        eyeOpen = LS.(varStr_open);
        
        % normalized time, in seconds
        time = LS.deviceClock/1e6;
        time = time - min(time);
        
        % find average sample rate
        dt = mean(diff(time));
        Fs = round(1.0/dt);

        % use blank for the duration when the eyes cannot be observed
        variable( eyeOpen==0 ) = 0;
        
        %% Create the filter bank for CWT
        sampleLength = length(variable);
        [minfreq, maxfreq] = cwtfreqbounds( sampleLength, Fs );
        fb = cwtfilterbank('SignalLength', sampleLength,...
            'SamplingFrequency',Fs,...
            'FrequencyLimits', [minfreq, maxfreq] );

        %% Generate the wavelet data
        cfs = abs(fb.wt(variable));
        cfs = rescale(cfs);
        
        %% Initialize loop variables
        increment = 10; % use 10 second segments
        shift = 2; % shift it by 2 second each time
        advanceFrame = round(increment/shift); % use this to skip frames (only works when increment is divisible by shift)
        
        % initialize variables for saving end index every 2 second after 10
        end_indices = zeros( ceil( (time(length(time) )) / shift ), 1 ); % record end indices every shift
        end_count = 0;
        end_t = increment; % start from 10 second
        
        % initialize variables for saving start index every 2 second
        start_indices = zeros( ceil( (time(length(time) )) / shift ), 1 ); % record start indices every shift
        start_indices(1) = 1;
        start_t = 0;
        start_count = 1;
        
        for ii = 1:length(time)
            %% For every 'shift' second interval, save the start index
            if (time(ii) >= start_t + shift)
                start_count = start_count + 1;
                start_indices(start_count) = ii;
                start_t = start_t + shift;
            end
            
            %% For every 'shift' second interval after increment, save the end index
            if (time(ii) >= end_t)  
                end_count = end_count + 1;
                end_indices(end_count) = ii;
                end_t = end_t + shift;
            end
        end
        
        %% Save images based on the indices found previously
        for imgIdx = 1:end_count-(advanceFrame)

            start_index = start_indices(imgIdx);
            end_index = end_indices(imgIdx);
            future_start_index = start_indices(imgIdx + advanceFrame);
            future_end_index = end_indices(imgIdx + advanceFrame);
            
            segment = cfs( :, start_index:end_index );
            futureEyeOpenSegment = eyeOpen( future_start_index:future_end_index );
            willBeMostlyEyeOpen = (sum(futureEyeOpenSegment) / length(futureEyeOpenSegment) > 0.5);

            im = ind2rgb(im2uint8(segment),jet(128));

            % the file will be saved in the format:
            %   recordId_{t}s_{mostlyEyeOpen}.jpg
            imFileName = strcat( FName, '_', num2str(time(start_index)), 's_', num2str(willBeMostlyEyeOpen), '.jpg');
            if (willBeMostlyEyeOpen) 
                childFolder = 'willBeMostlyEyeOpened';
                imgOpen = imgOpen + 1;
            else
                childFolder = 'willBeMostlyEyeClosed';
                imgClose = imgClose + 1;
            end

            imwrite(imresize(im,[224 224]),convertStringsToChars(fullfile(imageRoot,childFolder,imFileName)));
            imgCount = imgCount + 1;
        end
    end
    
    disp(num2str(imgCount));
    disp(num2str(imgOpen));
    disp(num2str(imgClose));
end