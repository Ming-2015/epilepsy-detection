% sample rate at 128Hz
Fs = 128;
% Creating filter bank for the sample data
fb = cwtfilterbank('SignalLength',10000,...
    'SamplingFrequency',Fs,...
    'VoicesPerOctave',12);
% Extracting one set of data to use for the example
sig = ECGData.Data(5,1:10000);
% Get the wavelet transform coefficients of the signal using the
% filterbank, asa well as the frequencies corresponding to the scales
[cfs,frq] = wt(fb,sig);
t = (0:9999)/Fs;

figure;
pcolor(t,frq,abs(cfs));

set(gca,'yscale','log');
shading interp;
axis tight;

title('Scalogram');
xlabel('Time (s)');
ylabel('Frequency (Hz)')