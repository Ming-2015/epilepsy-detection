function generateJointScalogramFromRecordId( listRecordId, folderName, varName )
    %% Initialize some variables
    EyeSideNames	=	{'LeftEye','RightEye'};
    VarNames	=	{varName, 'eyeOpen'};
    imageRoot = fullfile( folderName );
    [~,count] = size( listRecordId );
    
    %% Make sure the folders exist; if not, create them
    if (~exist(folderName,'dir'))
        mkdir( fullfile(folderName) );
    end
    if (~exist(fullfile(folderName, 'eyeOpenedAndWillBeMostlyEyeOpened'), 'dir'))
        mkdir( fullfile(folderName, 'eyeOpenedAndWillBeMostlyEyeOpened') );
    end
    if (~exist(fullfile(folderName, 'eyeClosedAndWillBeMostlyEyeOpened'), 'dir'))
        mkdir( fullfile(folderName, 'eyeClosedAndWillBeMostlyEyeOpened') );
    end
    if (~exist(fullfile(folderName, 'eyeOpenedAndWillBeMostlyEyeClosed'), 'dir'))
        mkdir( fullfile(folderName, 'eyeOpenedAndWillBeMostlyEyeClosed') );
    end
    if (~exist(fullfile(folderName, 'eyeClosedAndWillBeMostlyEyeClosed'), 'dir'))
        mkdir( fullfile(folderName, 'eyeClosedAndWillBeMostlyEyeClosed') );
    end
    
    imgCount = 0;
    imgOpenOpen = 0;
    imgCloseOpen = 0;
    imgOpenClose = 0;
    imgCloseClose = 0;
    
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
            currentEyeOpenSegment = eyeOpen( start_index:end_index);
            futureEyeOpenSegment = eyeOpen( future_start_index:future_end_index );
            willBeMostlyEyeOpen = (sum(futureEyeOpenSegment) / length(futureEyeOpenSegment) > 0.5);
            mostlyEyeOpen = (sum(currentEyeOpenSegment) / length(currentEyeOpenSegment) > 0.5);
            
            im = ind2rgb(im2uint8(segment),jet(128));

            % the file will be saved in the format:
            %   recordId_{t}s_{mostlyEyeOpen}.jpg
            imFileName = strcat( FName, '_', num2str(time(start_index)), 's_', num2str(willBeMostlyEyeOpen), '.jpg');
            if (willBeMostlyEyeOpen) 
                if (mostlyEyeOpen)
                    childFolder = 'eyeOpenedAndWillBeMostlyEyeOpened';
                    imgOpenOpen = imgOpenOpen + 1;
                else
                    childFolder = 'eyeClosedAndWillBeMostlyEyeOpened';
                    imgCloseOpen = imgCloseOpen + 1;
                end
            else
                if (mostlyEyeOpen)
                    childFolder = 'eyeOpenedAndWillBeMostlyEyeClosed';
                    imgOpenClose = imgOpenClose + 1;
                else
                    childFolder = 'eyeClosedAndWillBeMostlyEyeClosed';
                    imgCloseClose = imgCloseClose + 1;
                end
            end

            imwrite(imresize(im,[224 224]),convertStringsToChars(fullfile(imageRoot,childFolder,imFileName)));
            imgCount = imgCount + 1;
        end
    end
    
    disp(strcat("total img count: ", num2str(imgCount)));
    disp(strcat("open then open img count: ", num2str(imgOpenOpen)));
    disp(strcat("close then open img count: ", num2str(imgCloseOpen)));
    disp(strcat("open then close img count: ", num2str(imgOpenClose)));
    disp(strcat("close then close img count: ", num2str(imgCloseClose)));
end