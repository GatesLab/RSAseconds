function cleanmacpollution(loc)
%CLEANMACPOLLUTION deletes the annoying search trace files generated by MAC.
%   CLEANMACPOLLUTION(WHERE) deletes the annoying search trace generated
%   by MAC OS for all subdirectorys under WHERE.
%
%   MAC OS has the bad habit of creating garbage finder data file in every
%   directory it touches. Usually this means your flashdrive will be
%   polluted by numerous unwanted files once you've plugged it into a mac.
%   On OS 9 these garbages are FINDER.DAT; on OS X they are .DS_Store;
%   Use this little tool to remove those unwanted files;

% Written by Siyi Deng; 12-19-2007;

if nargin < 1 || isempty(loc), loc = uigetdir; end
if ~loc, return; end
s = genpath(loc);
p = strfind(s,pathsep);
q = [[1,p(1:end-1)+1];p-1];
mc = {'FINDER.DAT','.DS_Store'}; % OS 9, OS X;
for v = 1:numel(mc)
    for k = 1:size(q,2)
        thePath = [s(q(1,k):q(2,k)),filesep];
        if exist([thePath,mc{v}],'file')
            disp(['Deleting ',thePath,mc{v},'...']);
            delete([thePath,mc{v}]);
        end
        if exist([thePath,'private'],'dir')
            if exist([thePath,'private',filesep,mc{v}],'file')            
                disp(['Deleting ',thePath,'private',filesep,mc{v},'...']);
                delete([thePath,'private',filesep,mc{v}]);
            end
        end
    end
end

end % CLEANMACPOLLUTION;
