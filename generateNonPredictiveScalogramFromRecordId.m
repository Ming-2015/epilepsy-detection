function generateNonPredictiveScalogramFromRecordId( listRecordId, folderName, varName )
    %% Initialize some variables
    EyeSideNames	=	{'LeftEye','RightEye'};
    VarNames	=	{varName, 'eyeOpen'};
    imageRoot = fullfile( folderName );
    [~,count] = size( listRecordId );
    
    %% Make sure the folders exist; if not, create them
    if (~exist(folderName,'dir'))
        mkdir( fullfile(folderName) );
    end
    if (~exist(fullfile(folderName, 'mostlyEyeClosed'), 'dir'))
        mkdir( fullfile(folderName, 'mostlyEyeClosed') );
    end
    if (~exist(fullfile(folderName, 'mostlyEyeOpened'), 'dir'))
        mkdir( fullfile(folderName, 'mostlyEyeOpened') );
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
        next_t = increment; % start from 10 second
        savedImg = 0; % number of images saved for this patient
        
        % initialize variables for saving index every 2 second
        prev_index = zeros( ceil( (time(length(time) )) / shift ), 1 ); %record indices every shift
        prev_index(1) = 1;
        shift_t = 0;
        shift_index = 2;
        
        for ii = 1:length(time)
            %% For every 'shift' second interval, save the index
            if (time(ii) >= shift_t + shift)
                prev_index(shift_index) = ii;
                shift_index = shift_index + 1;
                shift_t = shift_t + shift;
            end
            
            %% For every ten second segment, save the image into the folder
            if (time(ii) >= next_t)
                start_index = prev_index(savedImg+1);
                segment = cfs( :, start_index:ii );
                eyeOpenSegment = eyeOpen( start_index:ii);
                mostlyEyeOpen = (sum(eyeOpenSegment) / length(eyeOpenSegment) > 0.5);
                
                im = ind2rgb(im2uint8(segment),jet(128));
                
                % the file will be saved in the format:
                %   recordId_{t}s_{mostlyEyeOpen}.jpg
                imFileName = strcat( FName, '_', num2str(next_t), 's_', num2str(mostlyEyeOpen), '.jpg');
                if (mostlyEyeOpen) 
                    childFolder = 'mostlyEyeOpened';
                    imgOpen = imgOpen + 1;
                else
                    childFolder = 'mostlyEyeClosed';
                    imgClose = imgClose + 1;
                end
                
                imwrite(imresize(im,[224 224]),convertStringsToChars(fullfile(imageRoot,childFolder,imFileName)));

                savedImg = savedImg + 1;
                next_t = next_t + shift;
                imgCount = imgCount + 1;
            end
        end
    end
    
    disp(num2str(imgCount));
    disp(num2str(imgOpen));
    disp(num2str(imgClose));
end