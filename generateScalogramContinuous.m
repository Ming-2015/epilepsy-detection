%% Helper function to generate scalograms
% recordId: the number attached to the record, used for accessing the file
% sampleLength: number of samples to be used in the scalogram; use 0 if you
%   want to use all the samples available
% useLeftEye: input 1 if you want to use left eye data, or 0 if you want to
%   use right eye data
function generateScalogramContinuous(recordId, sampleStart, sampleLength, useLeftEye, varName)
%%	Load subject specific measurement file
% FName		=	'060713';
FName       =   recordId;
FileName	=	['AIML/Eye_epilepsy/Data/sorted/' FName '/' FName '_reduced.mat'];
LS			=	load(FileName);
EyeSideNames	=	{'LeftEye','RightEye'};
VarNames	=	{varName, 'eyeOpen'};

if useLeftEye == 1
    eyeSide = 1;
else
    eyeSide = 2;
end
% Movie_folder=	'Data/Movies';
% Figure_folder=	'figures';

%%	Data list to process
varStr_varName = [EyeSideNames{eyeSide} '_' VarNames{1}];
varStr_open = [EyeSideNames{eyeSide} '_' VarNames{2}];
varName = LS.(varStr_varName);
eyeOpen = LS.(varStr_open);
time = LS.deviceClock/1e6;
time = time - min(time);

% find average sample rate
dt = mean(diff(time));
Fs = round(1.0/dt);

% use blank for the duration when the eyes cannot be observed
varName( eyeOpen==0 ) = 0;

%% CWT Filter Bank
sampleInPlot = sampleStart + sampleLength - 1;
if sampleInPlot == 0
    sampleInPlot = length(time);    
end   
[minfreq, maxfreq] = cwtfreqbounds( sampleLength, Fs );

% Creating filter bank for the sample data 
fb = cwtfilterbank('SignalLength', sampleLength,...
    'SamplingFrequency',Fs,...
    'FrequencyLimits', [minfreq, maxfreq] );

disp( ['minfreq: ' num2str(minfreq)] );
disp( ['maxfreq: ' num2str(maxfreq)] );
disp( ['FS: ' num2str(Fs) ] );

% Extracting one set of data to use for the example
sig =  varName(sampleStart:sampleInPlot);
t = time(sampleStart:sampleInPlot);
eyeOpenPartial = eyeOpen(sampleStart:sampleInPlot);
[cfs,frq] = wt(fb,sig);

%% Plot the scalogram
figure;
p1 = subplot(3,1,1);
pcolor(t,frq,abs(cfs));

set(gca,'yscale','log');
shading interp;
axis tight;

title(['Scalogram for ' EyeSideNames{eyeSide} ' of record ' FName]);
xlabel('Time (s)');
ylabel('Frequency (Hz)')

p2 = subplot(3,1,2);
% plot(t(eyeOpenPartial~=0), sig(eyeOpenPartial~=0)); 
plot(t, sig);

p3 = subplot(3,1,3);
plot(t, eyeOpenPartial);

linkaxes([p1, p2, p3], 'x');
end