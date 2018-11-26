%% Helper function to generate scalograms
% recordId: the number attached to the record, used for accessing the file
% sampleLength: number of samples to be used in the scalogram; use 0 if you
%   want to use all the samples available
% useLeftEye: input 1 if you want to use left eye data, or 0 if you want to
%   use right eye data
function generateScalogramContinuous(recordId, sampleStart, sampleLength, useLeftEye, varName, seizureTimes)
%%	Load subject specific measurement file

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
t = datenum( time(sampleStart:sampleInPlot) / (60*60*24) );
eyeOpenPartial = eyeOpen(sampleStart:sampleInPlot);
[cfs,frq] = wt(fb,sig);

%% Extract seizureTimes to plot when the seizure is occuring

if (seizureTimes.isKey(recordId))
    currentSeizureTimes = seizureTimes(recordId);
    [seizureCount, ~] = size(currentSeizureTimes);
    randColors = rand(seizureCount, 3);
    randColors(:,3) = 0;
else
    seizureCount = 0;
    randColors = [0,0,0];
end


%% Plot the scalogram
% Do note that while the axes are linked, their labels are not, because
% of the inability to update multiple axes while using datetickzoom
figure('units','normalized','outerposition',[0.2 0.2 0.8 0.8]);
p1 = subplot(3,1,1);

% Plot the actual scalogram 
hold on;
pcolor(t,frq,abs(cfs));

% Plot the seizure periods
min_f = min(frq);
max_f = max(frq);
for i = 1:seizureCount
    [~,~,~,HH,MM,SS] = datevec(currentSeizureTimes(i,1));
    startTime = datenum( (HH*60*60 + MM*60 + SS)/(60*60*24) );
    plot( [startTime, startTime], [min_f, max_f], 'color', randColors(i,1:3) );

    [~,~,~,HH,MM,SS] = datevec(currentSeizureTimes(i,2));
    endTime = datenum( (HH*60*60 + MM*60 + SS)/(60*60*24) );
    plot( [endTime, endTime], [min_f, max_f], 'color', randColors(i,1:3) );
end
hold off;

datetickzoom('x', 'MM:SS', 'keeplimits');
set(gca,'yscale','log');
shading interp;
axis tight;
title(['Scalogram for ' EyeSideNames{eyeSide} ' of record ' FName]);
xlabel('Time (s)');
ylabel('Frequency (Hz)');

%% Plot the raw signals
p2 = subplot(3,1,2);
hold on;
plot(t, sig);

min_s = min(sig);
max_s = max(sig);
for i = 1:seizureCount
    [~,~,~,HH,MM,SS] = datevec(currentSeizureTimes(i,1));
    startTime = datenum( (HH*60*60 + MM*60 + SS)/(60*60*24) );
    plot( [startTime, startTime], [min_s, max_s], 'color', randColors(i,1:3) );

    [~,~,~,HH,MM,SS] = datevec(currentSeizureTimes(i,2));
    endTime = datenum( (HH*60*60 + MM*60 + SS)/(60*60*24) );
    plot( [endTime, endTime], [min_s, max_s], 'color', randColors(i,1:3) );
end
hold off;

datetickzoom('x', 'MM:SS', 'keeplimits');

%% Plot the eyeOpen signals
p3 = subplot(3,1,3);
hold on;
plot(t, eyeOpenPartial);

min_e = min(sig);
max_e = max(sig);
for i = 1:seizureCount
    [~,~,~,HH,MM,SS] = datevec(currentSeizureTimes(i,1));
    startTime = datenum( (HH*60*60 + MM*60 + SS)/(60*60*24) );
    plot( [startTime, startTime], [min_e, max_e], 'color', randColors(i,1:3) );

    [~,~,~,HH,MM,SS] = datevec(currentSeizureTimes(i,2));
    endTime = datenum( (HH*60*60 + MM*60 + SS)/(60*60*24) );
    plot( [endTime, endTime], [min_e, max_e], 'color', randColors(i,1:3) );
end
hold off;

datetickzoom('x', 'MM:SS', 'keeplimits');

%% Link the axes of the subplots
linkaxes([p1, p2, p3], 'x');
xlim([min(t) max(t)]);
end