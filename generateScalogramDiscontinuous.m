%% Helper function to generate one scalogram.
% recordId: the number attached to the record, used for accessing the file
% sampleLength: number of samples to be used in the scalogram; use 0 if you
%   want to use all the samples available
% useLeftEye: input 1 if you want to use left eye data, or 0 if you want to
%   use right eye data
function generateScalogramDiscontinuous(recordId, sampleLength, useLeftEye)
%%	Load subject specific measurement file
% FName		=	'060713';
FName       =   recordId;
FileName	=	['AIML/Eye_epilepsy/Data/sorted/' FName '/' FName '_reduced.mat'];
LS			=	load(FileName);
EyeSideNames	=	{'LeftEye','RightEye'};
VarNames	=	{'eccentricity', 'eyeOpen'};

if useLeftEye == 1
    eyeSide = 1;
else
    eyeSide = 2;
end
% Movie_folder=	'Data/Movies';
% Figure_folder=	'figures';

%%	Data list to process
varStr_eccentricity = [EyeSideNames{eyeSide} '_' VarNames{1}];
varStr_open = [EyeSideNames{eyeSide} '_' VarNames{2}];
eccentricity = LS.(varStr_eccentricity);
eyeOpen = LS.(varStr_open);
time = LS.deviceClock/1e6;
time = time - min(time);

% find average sample rate
dt = mean(diff(time));
Fs = round(1.0/dt);

% trim off unusable data
eccentricity = eccentricity( eyeOpen==1 );
time = time( eyeOpen==1 );

%% CWT Filter Bank
sampleInPlot = sampleLength;
if sampleInPlot == 0
    sampleInPlot = length(time);    
end
[minfreq, maxfreq] = cwtfreqbounds( sampleInPlot, Fs );

% Creating filter bank for the sample data 
fb = cwtfilterbank('SignalLength', sampleInPlot,...
    'SamplingFrequency',Fs,...
    'FrequencyLimits', [minfreq, maxfreq] );

% Extracting one set of data to use for the example
sig =  eccentricity(1:sampleInPlot);
t = time(1:sampleInPlot);
[cfs,frq] = wt(fb,sig);

%% Plot the scalogram
figure;
pcolor(t,frq,abs(cfs));

set(gca,'yscale','log');
shading interp;
axis tight;

title(['Scalogram for ' EyeSideNames{eyeSide} ' of record ' FName]);
xlabel('Time (s)');
ylabel('Frequency (Hz)')

end