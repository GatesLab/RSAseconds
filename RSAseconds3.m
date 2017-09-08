function RSAseconds3(where, low, high)
%  the following fields must be populated prior to running:
%
%       where = 'type here the path to the folder where your data are';
%       low = .##; type the lower bound for the frequency range of interest (e.g., .15)
%       high = .##; type the higher bound for the frequency range of interest (e.g., .40)
%       
%       Adapted July 2013 for use with Actiheart software.
%updated 2014
%updated oct 2015 for mac
%% load

cd(where)
if ismac==1
    cleanmacpollution(where)
end
list = dir; list(1:2,:) = [];
subjects = length(list(:,1));
outputloc = fullfile(where, 'RSA');
mkdir(outputloc)

putmissing = fullfile(where, 'Problems');
mkdir(putmissing)
problems.length= 'Begin';

%% window
% s(n,k) = sumI(ai)[sum(N-1)x(m+nL)hi(m)e^-j2pi(k/K)m]^2
now = 4; % found to work in Hannson 2006, 2007
Nw = 4*32;         % window length for thirty seconds, when using 250 SR; use 31 so 16 is the center

cd(where)
[multipeak, a]=multipeakwind(Nw,now); % creates file

%% Concatenate, Interpolate, and get estimates
for p = 1: subjects
    % "load" does not work consistently to load excel on mac; neither does
    % xlsread
    data = load(fullfile(where, list(p).name));
    if round(data(1)) ~= data(1) && data(1)<10
       data = round(data*1000); % this is to put it in msecs rather than seconds
    end
    countmissing(p) = length(find(data >= 2000));
    togetmean = data;
    togetmean(find(togetmean == 2000))=[];
    meandata = mean(togetmean); 
    data(find(data>=2000)) = meandata; 

    Ndata=length(data); %nD is the number of occurrences in the series
    
    x=zeros(Ndata,1);
    
    x(1)=data(1);              %integrate across time
    x(2)=data(2)+data(1);
    for i=3:Ndata;
        x(i)=data(i)+x(i-1);
    end
    
    SR=250;  % sampling rate
    xx = 250:SR:(round(x(end)));
    y= spline(x,data,xx);  % make from point-process to evenly distributed time poitns
    
    y=y-mean(y); % mean center
    
    % STFT
    % spectrogram(x,window,noverlap,F,fs)
    
    if length(y) > 124
    F= [low:1/32:high];
    
    for i = 1:4
        [S31,F31,T31,P32]=spectrogram(y,multipeak(:,i), 124, F, 4); %get the power (P)
        if i == 1
            RSA2 = zeros(size(P32)); %initiate
        end
        RSA2 = P32*a(i) + RSA2; %a weights add to 1
    end
    
     meanRSA = log(2*sum(RSA2)/128); %typical log 2*power;
    %scale by dividing by number of points (L) per Matlab fft documentation
    
    
    forsave =vertcat(T31,meanRSA)';
    
    [pathstr, name, ext] = fileparts(list(p).name);
    output = fullfile(outputloc, [name '_RSA.xlsx'] );
    xlswrite(output, forsave);
    
    outfile2 = [outputloc '\MissingAndOutliers.mat'];
    save(outfile2, 'countmissing')
    clear RSA
    else
    problems.length = char(problems.length, list(p).name);
    movefile(fullfile(where, list(p).name), fullfile(putmissing, list(p).name))
    end
end

disp('All done!')




