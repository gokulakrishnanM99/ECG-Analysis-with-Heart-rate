clc;
clear all;
close all;
file='location\file.xlsx'; %location of the excel
range='B3:B5010'; %II mode is chosen from 6 modes
%Raw ECG data
x=xlsread(file,range);
ecg=detrend(x,0);
N=length(x);
T=10; %time in sec
fs=N/T;
t=0:1/fs:(N-1)/fs;
f1=N/10; 

% if you have data in dat format, use this instaed of excel format
%x1 = load('ecg_data.dat');
%fs = 200;                
%t = [0:N-1]/fs; 

figure(1);
plot(t,ecg); %original signal
xlabel('second');
ylabel('Volts');
title('Input ECG Signal');

ecg = ecg - mean (ecg);    
ecg = ecg/ max( abs(ecg ));
 
figure(2);
plot(t,ecg); %After normalisation
xlabel('second');
ylabel('Volts');
title('Normalized ECG Signal');

% LPF (1-z^-6)^2/(1-z^-1)^2
b=[1 0 0 0 0 0 -2 0 0 0 0 0 1];
a=[1 -2 1];
h_LP=filter(b,a,[1 zeros(1,12)]);
LP = conv (ecg ,h_LP);
LP = LP/ max( abs(LP));
figure(3);
plot([0:length(LP)-1]/fs,LP); %Low pass filter
xlabel('second');
ylabel('Volts');
title(' ECG Signal after LPF');
xlim([0 max(t)]);

b = [-1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 32 -32 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1];
a = [1 -1];
h_HP=filter(b,a,[1 zeros(1,32)]);
HP = conv (LP ,h_HP);
HP = HP/ max( abs(HP ));
 
figure(4);
plot([0:length(HP)-1]/fs,HP); %High Pass filter
xlabel('second');
ylabel('Volts');
title(' ECG Signal after HPF');
xlim([0 max(t)]);

%Squaring
Sq = (HP .^2);
Sq = Sq/ max( abs(Sq));
figure(5);
plot([0:length(Sq)-1]/fs,Sq); %Squared signal
xlabel('second');
ylabel('Volts');
title(' ECG Signal Squaring');
xlim([0 max(t)]);

h = ones (1 ,31)/31;
Avg = conv (Sq ,h);
Avg = Avg (15+[1: N]);
Avg = Avg/ max( abs(Avg ));
 
figure(6);
plot([0:length(Avg)-1]/fs,Avg); %Averaging
xlabel('second');
ylabel('Volts');
title(' ECG Signal after Averaging');

%R peak detection
max_h = max(Avg);
thresh = mean (Avg);
poss_reg =(Avg>thresh*max_h)';
left = (find(diff([0 poss_reg])==1));
right = find(diff([poss_reg 0])==-1);
for i=1:length(left)
    [R_value(i) R_loc(i)] = max( ecg(left(i):right(i)) );
    R_loc(i) = R_loc(i)-1+left(i);
end
R_loc=R_loc(find(R_loc~=0));
figure(7);
plot (t,ecg/max(ecg) , t(R_loc) ,R_value , 'r^');
legend('ECG','R');
title('ECG Signal with R peak');

%heart rate & HRV
rwave=0;
U=0;
flag=0;
c=0;
flag1=0;
flagdif=0;
heart=0;
for i=1:1:N
    hrv(i)=0;
end
for i=1:1:N
    if Avg(i)>=thresh
        U=1;
    end
    if U==1
        if Avg(i)<= thresh
            rwave=rwave+1;
            flag=i;
            c=c+1;
            if c==1
                flag1=flag;
                flagdif=flag;
            end
            if c==2
                flagdif=flag-flag1;
                flag1=flag;
                c=1;
            end
            U=0;
        end
    end
    hrv(i)=flagdif+hrv(i);
end
rate=rwave*(60/T);
disp('The heart rate of the person is:');
disp(rate);
if rate>=70 && rate<=85
    disp('The person has normal heart rate');
end
if rate<70
    disp('The person has bradycardia');
end
if rate>85
    disp('The person has tachycardia');
end
figure(8);
plot(t,hrv/3);
title('Heart rate variability');
xlabel('Time (s)');
ylabel('Heart rate (bpm)');

figure(9);
plot(t,ecg);
hold on
plot(t,hrv/f1,'r');
title('ECG signal with Heart rate variability');
xlabel('Time (s)');
ylabel('Amplitude (milliV)');

