function RSAseconds(where, low, high, mindware)
%  the following fields must be populated prior to running:
%
%       where = 'type here the path to the folder where your data are';
%       low = .##; type the lower bound for the frequency range of interest (e.g., .15)
%       high = .##; type the higher bound for the frequency range of interest (e.g., .40)
%
%       Adapted July 2013 for use with Actiheart software.
%updated 2014
%updated oct 2015 for mac
%updated Sept 2017 to integrate MindWare & alternative platforms
%% load

% Check number of inputs.
if nargin > 4
    error('myfuns:RSAseconds:TooManyInputs', ...
        'requires at most 4 inputs');
end
mindware = 1;

% Fill in unset optional values.
switch nargin
    case 2
        mindware = 0;
end

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
    
    if mindware == 1
        [A,B] = xlsfinfo(fullfile(where, list(p).name));
        if any(strcmp(B, 'IBI Series')) == 0
            problems.sheet = char(problems.sheet, list(p).name);
            movefile(fullfile(where, list(p,:)), fullfile(putmissing, list(p).name))
        else
            datao = xlsread(fullfile(where, list(p).name), 'IBI Series');
            if any(strcmp(B, 'HRV Stats')) == 0
                problems.sheet = char(problems.sheet, list(p).name);
                movefile(fullfile(where, list(p).name), fullfile(putmissing, list(p).name))
            else
                [datalength,strdata]= xlsread(fullfile(where, list(p).name), 'HRV Stats');
                countnan = 0;  %identifies empty epochs
                
                if isempty(datao) == 0 % only works if not empty
                    datao(1,:) = []; % the first row is just a count of columns
                    for pp = 1: length(datao(1,:))
                        if datalength(38,1) == 9998 || datalength(38,1) == 9999 % if missing
                            countnan = 1+countnan;
                            %elseif isnan(datalength(40,pp)) == 1
                            %countnan = 1+countnan;
                        else
                            countnan = countnan + 0;
                        end
                    end
                end
                if isempty(datao)==1
                    movefile(fullfile(where, list(p).name), fullfile(putmissing, list(p).name))
                elseif countnan >= 1
                    movefile(fullfile(where, list(p).name), fullfile(putmissing, list(p).name))
                else
                    for i = 1: length(datao(1,:)) % do for each epoch; in terms of seconds
                        % due to differences in MindWare versions, need to find unique
                        % indices for end and start time per segment.
                        CharString = char(strdata);
                        xe = strmatch('End Time', CharString, 'exact');
                        if length(xe) > 1
                            xe(1) = [];  % we want the second one
                        end
                        xs = strmatch('Start Time', CharString, 'exact');
                        if length(xs) > 1
                            xs(1) = [];
                        end
                        
                        reallength(i,1) = round(datalength(xe-1,i) - datalength(xs-1,i)); %subtract 1 due to removal of text row during import
                        
                        flag = 1;
                        added = 0;
                        theend = min(find(isnan(datao(:,i))==0, 1, 'last'), max(find(datao(:,i)>0)));
                        datao(find(datao(:,i)>1500),i) = 1500; % so insanely high ones aren't considered
                        datao(find(datao(:,i)==0),i) = NaN; % so zeros aren't kept
                        meanibi = mean(datao(1:theend,i));
                        standdev = std(datao(1:theend,i));
                        missingnan = 1;
                        totalshouldbe = reallength(i,1)*1000 - 2; % cast in terms of msecs
                        for t = 1: theend
                            if isnan(datao(t,i)) == 1
                                missingnan(end+1) = t;
                            elseif datao(t,i)-meanibi > standdev*3
                                flag(end+1) = t;
                                problems.outlier = char(problems.outlier, list(p).name);
                            else
                                added = added + datao(t,i);
                            end
                        end
                        flag(1) = [];
                        missingnan(1) = [];
                        
                        if isempty(flag) == 0 || isempty(missingnan)==0
                            flagmiss = vertcat(flag,missingnan);
                            xxxx = length(flagmiss);
                            replace = (totalshouldbe-added)/xxxx;
                            for ppp = 1:length(flagmiss)
                                datao(flagmiss(ppp), i) = replace;
                            end
                        end
                        
                        
                        lastone = find(isnan(datao(:,i))==1,1, 'first') -1;
                        if isempty(lastone) == 1 || lastone == 0
                            lastone = find(datao(:,i)>0, 1, 'last');
                        end
                        
                        if i == 2
                            lastfirst = find(isnan(datao(:,1))==1,1, 'first')-1;
                            if isempty(lastfirst) ==1
                                lastfirst = find(datao(:,1),1,'last');
                            end
                            datao(lastfirst,1) = datao(lastfirst,1) + datao(1,i);
                            datao(lastfirst+1:lastfirst+lastone-1,1) = datao(2:lastone,i);
                        end
                        if i > 2
                            lastfirst = find(datao(:,1), 1, 'last');
                            datao(lastfirst,1) = datao(lastfirst,1) + datao(1,i);
                            datao(lastfirst+1:lastfirst+lastone-1,1) = datao(2:lastone,i);
                        end
                    end
                    data = datao(:,1);
                    data(1) = []; % the first on is usually mid beat
                    lastone = find(isnan(data(:,1))==1,1, 'first')-1;
                    if isempty(lastone == 1)
                        lastone = find(data>0,1,'last');
                    end
                    data(lastone:length(data)) = [];
                    
                end
            end
        end
    else
        data = load(fullfile(where, list(p).name));
        
        if round(data(1)) ~= data(1) && data(1)<10
            data = round(data*1000); % this is to put it in msecs rather than seconds
        end
        countmissing(p) = length(find(data >= 2000));
        togetmean = data;
        togetmean(find(togetmean == 2000))=[];
        meandata = mean(togetmean);
        data(find(data>=2000)) = meandata;
        
    end
    
    %% run STFT analysis
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
        
        clear RSA
    else
        problems.length = char(problems.length, list(p).name);
        movefile(fullfile(where, list(p).name), fullfile(putmissing, list(p).name))
    end
end

disp('All done!')




