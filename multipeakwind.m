
function [multipeak,weight]=multipeakwind(N,now);
% [multipeak,weights]=multipeakwind(N,now);

% Calculates the 'now' (default 8) windows 
% 
% now : A number between 2 and 8 (default 8)
% N   : Window length
% multipeak: The windows in a matrix as columns, (normalized). 
% weight: Weights




if nargin==1
  now=8;
end



  K1=20;         % Peak in dB 
  K2=30;         % Penalty value in dB

  B=(now+2)/N    % Resolution in spectrum

  loge=log10(exp(1));
  C=2*K1/10/B/loge;
  l=[1:N-1]';
  r0=2/C*(1-exp(-C*B/2));
  r=(2*C-exp(-C*B/2)*(2*C*cos(pi*B.*l)-4*pi.*l.*sin(pi*B.*l)))./(C^2+(2*pi.*l).^2);

  rpeak=[r0;r];  % Covariance function peaked spectrum

  r=2*sin(pi*B.*l)./(2*pi.*l);
  rbox=[B;r];

  rpen=10^(K2/10)*[1;zeros(N-1,1)]-(10^(K2/10)-1)*rbox; % Covariance function penalty function

  Ry=toeplitz(rpeak);
  Rx=toeplitz(rpen);
  [RR]=chol(Rx);
  C=inv(RR')*Ry*inv(RR);
  [Q,T]=schur(C);
  F=inv(RR)*Q;
  RD=F'*Ry*F;
  RD=diag(RD);
  [RDN,h]=sort(RD);
  for i=1:length(RD)
    FN(:,i)=F(:,h(i))./sqrt(F(:,h(i))'*F(:,h(i)));
  end
  RDN=RDN(length(RD):-1:1);  
  FN=FN(:,length(RD):-1:1);

  weight=RDN(1:now)/sum(RDN(1:now))
  multipeak=FN(:,1:now);
%  multipeak=FN(:,1:now);
%   eval(['save ' loadfile ' ' 'multipeak'])
%end

   


