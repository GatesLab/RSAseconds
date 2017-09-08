function rsaseconds9(where, low, high)

%% This function has been created by Kathleen M. Gates (2011; update 2014; update for Mac oct. 2015; debugged April 2017)
%  the following fields must be populated prior to running:
%       where = 'type here the path to the folder where your data are';
%       low = .##; type the lower bound for the frequency range of interest (e.g., .15)
%       high = .##; type the higher bound for the frequency range of interest (e.g., .40)
%% concatenate

cd(where)
if ismac==1
    cleanmacpollution(where)
end
list = dir; list(1:2,:) = [];
putmissing = fullfile(where, 'Problems');
mkdir(putmissing)
outputloc = fullfile(where, 'RSA');
mkdir(outputloc)
subjects = length(list(:,1));
problems.outlier = 'Begin';
problems.skips = 'Begin';
problems.sheet = 'Begin';
problems.length= 'Begin';

%% window
% s(n,k) = sumI(a_i)[sum(N-1)x(m+nL)h_i(m)e^-j2p_i(k/K)m]^2; a_i is the window
% weight, summed over 4 windows.
now = 4;           % found to work in Hannson 2006, 2007
Nw = 4*32;         % window length for thirty two seconds, when using 250 SR;
cd(where)
[multipeak, a]=multipeakwind(Nw,now); % creates new file in working directory

%% Concatenate, Interpolate, and get estimates
for p = 1: subjects
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
            
            
            Ndata=length(data); %nData is the number of occurrences in the series
            
            x=zeros(Ndata,1);
            
            x(1)=data(1);              %integrate across time
            x(2)=data(2)+data(1);
            for i=3:Ndata;
                x(i)=data(i)+x(i-1);
            end
            
            SR=250;  % sampling rate
            xx = 250:SR:(round(x(end)));
            y= spline2(x,data,xx);
            
            % STFT
            % first center data
            y = y-mean(y);
            % spectrogram(x,window,noverlap,F,fs)
            
            F= [low:1/32:high];
            if length(y) >124
                for i = 1:4
                    [S31,F31,T31,P32]=spectrogram(y,multipeak(:,i), 124, F, 4); %get the power (P)
                    if i == 1
                        RSA2 = zeros(size(P32)); %initiate
                    end
                    RSA2 = P32*a(i) + RSA2; %a weights add to 1
                end
                
                
                
                meanRSA = log(2*sum(RSA2)/128);
                %scaled per matlab fft documentation
                
                forsave =vertcat(T31,meanRSA)';
                findit = regexp(list(p).name, '.xls');
                name = list(p).name(1:findit-1);
                output = fullfile(outputloc, [name '_RSA.xlsx'] );
                identifier = 'MATLAB:xlswrite:AddSheet';
                warning('off',identifier)
                if ismac==1
                    csvwrite(output, forsave);
                else
                    xlswrite(output, data, 'IBIseries');
                    xlswrite(output, forsave, 'RSAseconds');
                end
                
                if ismac==0
                    DeleteEmptyExcelSheets(output)
                end
                
                clear RSA
            else
                problems.length = char(problems.length, list(p).name);
                movefile(fullfile(where, list(p).name), fullfile(putmissing, list(p).name))
                
            end
        end
    end
end


%% save problems
problems.outlier(1,:) = [];
problems.skips (1,:) = [];
problems.sheet(1,:) = [];
problems.length(1,:) = [];
if isempty(problems.skips) == 0
    disp('W_A_R_N_I_N_G:');
    disp('The following files contain skipped segments:');
    disp(problems.skips);
end
% if isempty(problems.outlier) == 0
%     disp('W_A_R_N_I_N_G:');
%     disp('The following files contain outliers that are at least 3 times the standard deviation:');
%     disp(problems.outlier);
% end
outfile = fullfile(where, 'problems.mat');
save(outfile, 'problems');
disp('All done!')




