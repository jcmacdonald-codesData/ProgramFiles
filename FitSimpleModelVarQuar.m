function [paramfitAggFixp]= FitSimpleModelVarQuar(alphac)

close all
warning off;
set(0,'DefaultFigureVisible','on')
% stop/start figures from displaying in matlab, switch 'off' to 'on to display
% import data 
ChinaData = readtable('ChinaDataReshaped.csv');
%Province = readtable('ProvinceNames.csv');
%Province = table2array(Province);
%Province = string(Province);
ProvincePops = readtable('ChinaProvincePops.csv');
ProvincePops = table2array(ProvincePops);
% national total cases
CCt = table2array(ChinaData(:,end-2));
CData2 = table2array(ChinaData(:,15));
CData1 = CCt - CData2;
% national total quarintined 
QCt = table2array(ChinaData(:,end));
% national current quarintined
%Mt = table2array(ChinaData(:,end));
%Qtd = Mt(2:end);
% national daily cases
%Ctd = diff(CCt);
%tdt=1:length(CCt);
% storage bin for fit parameteres 
%FitparamsAgg = zeros(2,5);

T=4.64;
T_e=2.71;
tau=3;
rho=1;
sqwt=0.01;
%alphac=1/14;
p = .06;
Mc0 = 0.00172837295386061;
N1 = sum(ProvincePops); % China pop
N1 = N1 - ProvincePops(14); % China pop les Hubei 
N2 = ProvincePops(14);
% retrieve province name
%Name = Province(its);
% provincial total cases
CC1 = CData1;
CC1 = CC1(CC1 > 0);
td1=2:length(CC1);
CC2 = CData2;
CC2 = CC2(CC2 > 0);
%CC2=CC2(2:end);
td2 = 2:length(CC2);
if length(td1) > length(td2)
    td = td1;
end
if length(td1) <= length(td2)
    td = td2;
end
%zers1 = length(CCt)-length(CC1)+1;
%zers2 = length(CCt) - length(CC2)+1;
QC = QCt;
M=table2array(ChinaData(:,end-1));
Qd = M(2:end);
% provincial daily cases
Cd1 = diff(CC1);
% account for no new reported cases on day after first reported case
if Cd1(1) == 0
    %Cd(1) = 2*Cd(2)-Cd(3);
    Cd1(1) = (Cd1(2))/2;
    Cd1(2)= (Cd1(2))/2;
    if Cd1(2) == 0
            Cd1(1) = Cd1(3)/3;
            Cd1(2) = Cd1(3)/3;
            Cd1(3) = Cd1(3)/3;
    end
end
if Cd1(end) == 0
    %Cd(1) = 2*Cd(2)-Cd(3);
    Cd1(end) = (Cd1(end-1))/2;
    Cd1(end-1)= (Cd1(end-1))/2;
    if Cd1(end-1) == 0
            Cd1(end) = Cd1(end-2)/3;
            Cd1(end-1) = Cd1(end-2)/3;
            Cd1(end-2) = Cd1(end-2)/3;
    end
end
if Cd1(1) < 0
    Cd1(1) = -Cd1(1);
end
ind0=find(Cd1==0);
   if isempty(ind0)==0
    Cd1(ind0)=1/3*Cd1(ind0-1)+1/3*Cd1(ind0+1);
    Cd1(ind0-1)=2/3*Cd1(ind0-1);
    Cd1(ind0+1)=2/3*Cd1(ind0+1);
   end
    
Cd2 = diff(CC2);
    % account for no new reported cases on day after first reported case
if Cd2(1) == 0
   %Cd(1) = 2*Cd(2)-Cd(3);
    Cd2(1) = (Cd2(2))/2;
    Cd2(2)= (Cd2(2))/2;
    if Cd2(2) == 0
            Cd2(1) = Cd2(3)/3;
            Cd2(2) = Cd2(3)/3;
            Cd2(3) = Cd2(3)/3;
    end
end
if Cd2(end) == 0
    %Cd(1) = 2*Cd(2)-Cd(3);
    Cd2(end) = (Cd2(end-1))/2;
    Cd2(end-1)= (Cd2(end-1))/2;
    if Cd2(end-1) == 0
            Cd2(end) = Cd2(end-2)/3;
            Cd2(end-1) = Cd2(end-2)/3;
            Cd2(end-2) = Cd2(end-2)/3;
    end
end
if Cd2(1) < 0
    Cd2(1) = -Cd2(1);
end
ind0=find(Cd2==0);
   if isempty(ind0)==0
    Cd2(ind0)=1/3*Cd2(ind0-1)+1/3*Cd2(ind0+1);
    Cd2(ind0-1)=2/3*Cd2(ind0-1);
    Cd2(ind0+1)=2/3*Cd2(ind0+1);
   end
tq = find(QC > 0);
C1 = Cd1(1:end);
C2 = Cd2(1:end);
[mx,im]=max(Cd2); 
ids=[1:im-2,im+2:length(Cd2)];
tds=td(ids);
C2 = C2(ids);
   
Cdd1 = C1;
Cdd1(1)=Cd1(1);
Td1=.1609*C1;
Cdd2 = Cd2;
Cdd2(1)=Cd2(1);
Td2=.1609*C2;
    
I01g = (C1(1)/rho)*T;
I02g = (C2(2)/rho)*T;
% fit values from entire country fit with exception of I0
paramguess = [I01g,(1.66014398889413e-08)*(1e8),	1407.12998368299,...
              0.391575667314593,I02g,(1.66014398889413e-08)*(1e8),...
              1407.12998368299,0.391575667314593];
lb = [I01g*.5, 2/T , 0 , .01 , I02g*.5, 2/T , 0 , .01 ];
ub = [I01g*2,6/T, inf , 1  ,I02g*2, 6/T , inf , 1 ];

M = M';
C1 = C1';
C2 = C2';
    
function X0 = IC(param,QC,C1,C2,M,tq,Td,N,its)
    I0 = param(1);
    beta = param(2);
    phi = param(4);
    S0=N;
    
    if its == 1
        C = C1;
        
    end
    if its == 2
        C = C2;
    
    end
    E0=beta*(1-phi*rho)*tau*I0;
    Ec0=beta*(phi*rho)*tau*I0;
    Ic0=phi*rho*I0;
    X0=[S0 E0 I0 Ec0 Ic0 p*QC(1) C(1) phi*rho*C(1) M(tq(1))*(C(tq(1))/(C1(tq(1))+C2(tq(1))))];
    %X0=[S0 E0 I0 Ec0 Ic0 QC(1) C(1) Td(1) Mc0];        
end



function[z] = Solve_sys(param,td)
    beta = param(2);
    sigma = param(3);
    phi = param(4);
    N = N1;
    param1 = param(1:4);
    X01 = IC(param1,QC,C1,C2,M,tq,Td1,N,1);
    %X01(4) = X01(4)*(C1(tq(1))/(C1(tq(1))+C2(tq(1))));
    %X01(5) = X01(5)*(C1(tq(1))/(C1(tq(1))+C2(tq(1))));
    %X01(6) = X01(6)*(C1(tq(1))/(C1(tq(1))+C2(tq(1))));
    %X01(9) = X01(9)*(C1(tq(1))/(C1(tq(1))+C2(tq(1))));
    psi = sigma + ((1-p)/p)*phi*rho;
    Eode = @(t,X) [-(1+psi)*X(1)*((beta/N)*X(3)),(beta/N)*(1-phi*rho)*X(1)*X(3)- 1/tau*X(2),...
                       1/tau*X(2)-1/T*X(3),(beta/N)*(phi*rho)*X(1)*X(3)- 1/tau*X(4),...
                       1/tau*X(4)-1/T_e*X(5),(beta/N)*(phi*rho)*X(1)*X(3),...
                       rho/T*X(3),1/T_e*X(5),(beta/N)*(phi*rho)/p*X(1)*X(3)-alphac*X(9)]';

   [t,Sol1] = ode45(@(t,X)Eode(t,X),td1,X01);
   
    beta = param(6);
    sigma = param(7);
    phi = param(8);
    N = N2;
    param2 = param(5:8);
    X02 = IC(param2,QC,C1,C2,M,tq,Td2,N,2);
    %X02(4) = X02(4)*(C2(tq(1))/(C1(tq(1))+C2(tq(1))));
    %X02(5) = X02(5)*(C2(tq(1))/(C1(tq(1))+C2(tq(1))));
    %X02(6) = X02(6)*(C2(tq(1))/(C1(tq(1))+C2(tq(1))));
    %X02(9) = X02(9)*(C2(tq(1))/(C1(tq(1))+C2(tq(1))));
    psi = sigma + ((1-p)/p)*phi*rho;
    Eode = @(t,X) [-(1+psi)*X(1)*((beta/N)*X(3)),(beta/N)*(1-phi*rho)*X(1)*X(3)- 1/tau*X(2),...
                       1/tau*X(2)-1/T*X(3),(beta/N)*(phi*rho)*X(1)*X(3)- 1/tau*X(4),...
                       1/tau*X(4)-1/T_e*X(5),(beta/N)*(phi*rho)*X(1)*X(3),...
                       rho/T*X(3),1/T_e*X(5),(beta/N)*(phi*rho)/p*(1-p)*X(1)*X(3)-alphac*X(9)+1/T_e*X(5)]';

   [t,Sol2] = ode45(@(t,X)Eode(t,X),td2,X02);
       
   Cdd1(2:end)=Sol1(2:end,7)+Sol1(2:end,8)-(Sol1(1:end-1,7)+Sol1(1:end-1,8));
   Cdd2(2:end)=Sol2(2:end,7)+Sol2(2:end,8)-(Sol2(1:end-1,7)+Sol2(1:end-1,8));
   CumSq=(Sol1(tq-(tq(1)-1),9))*sqwt + (Sol2(tq-3,9))*sqwt;
  % CumSq(1) = M(tq(1))*sqwt;
   Cds1=Cdd1(1:end);
   Cds2 = Cdd2(ids);
   z=[Cds1',Cds2',CumSq'];
      
      
end
    [paramfit,resnorm] = lsqcurvefit(@Solve_sys,paramguess,td,[C1,C2,M(tq)*sqwt],lb,ub);
    [paramfitAggFixp,resnorm] = lsqcurvefit(@Solve_sys,paramfit,td,[C1,C2,M(tq)*sqwt],lb,ub);
    % store fit parameters 
    %save('paramfitAgg.mat','paramfitAgg')
    
    zfit = Solve_sys(paramfitAggFixp,td);
    Cfit1 = zfit(1:length(td1));
    Cfit2 = zfit(length(Cfit1)+1:length(tds)+length(Cfit1));
    Qfit = zfit(length(Cfit1)+length(Cfit2)+1:end);
    
   % figure
 %   plot(td1,Cfit1,'b-',td1,Cd1,'r*','linewidth',2)
  %  title('China Less Hubei')
%    ylabel('New Daily Cases')
%    xlabel('Days Since First Reported Case')
%     baseFileName = sprintf('CasesChinaLessHubeiFixp.png');
%     fname = 'C:\Users\macdo\Dropbox\COVID-19_modelfitting_data\AggPlots';
%     saveas(gca, fullfile(fname, baseFileName), 'png');
%    figure
%    plot(tds,Cfit2,'b-',td2,Cd2,'r*','linewidth',2)
%    title('Hubei')
%    ylabel('New Daily Cases')
%    xlabel('Days Since First Reported Case')
%     baseFileName = sprintf('CasesHubeiFixp.png');
%     fname = 'C:\Users\macdo\Dropbox\COVID-19_modelfitting_data\AggPlots';
%     saveas(gca, fullfile(fname, baseFileName), 'png');
%    figure 
%    plot(tq,Qfit/(sqwt),'b-',tq,M(tq),'r*','linewidth',2)
%    title('All China')
%    xlabel('Days Since First Reported Case')
%    ylabel('Quarintined Individuals')
%     baseFileName = sprintf('AggQuarFixp.png');
%     fname = 'C:\Users\macdo\Dropbox\COVID-19_modelfitting_data\AggPlots';
%     saveas(gca, fullfile(fname, baseFileName), 'png');
    % store fit parameters 

 
    beta = paramfitAggFixp(2);
     sigma = paramfitAggFixp(3);
    phi = paramfitAggFixp(4);
     Re=beta*T*(1-phi);
    N = N1;
    param1 = paramfitAggFixp(1:4);
    X01 = IC(param1,QC,C1,C2,M,tq,Td1,N,1);
    %X01(4) = X01(4)*(C1(tq(1))/(C1(tq(1))+C2(tq(1))));
    %X01(5) = X01(5)*(C1(tq(1))/(C1(tq(1))+C2(tq(1))));
    %X01(6) = X01(6)*(C1(tq(1))/(C1(tq(1))+C2(tq(1))));
    %X01(9) = X01(9)*(C1(tq(1))/(C1(tq(1))+C2(tq(1))));
      E0=X01(2);
    I0=X01(3);
    psi = sigma + ((1-p)/p)*phi*rho;
    fun=@(x)  log(x)-(Re*(x-1)-(1+psi)*beta*T*(I0+E0)/N);
     Xs=bisection(fun,0,1);
     
     FS1=CC1(1)+1/(1+psi)*N*(1-Xs);
     
     fun=@(x)  log(x)-(beta*T*((x-1)-(1+sigma)*(I0+E0)/N));
     Xs=bisection(fun,0,1);
     
     FS1p0=CC1(1)+1/(1+sigma)*N*(1-Xs);
     
     fsred1=1-FS1/FS1p0;
    paramfitAggFixp(9) = resnorm;
    paramfitAggFixp(10) = FS1;
     paramfitAggFixp(11) = fsred1*100;
     
     beta = paramfitAggFixp(6);
     sigma = paramfitAggFixp(7);
    phi = paramfitAggFixp(8);
     Re=beta*T*(1-phi);
    N = N2;
    param2 = paramfitAggFixp(5:8);
    X02 = IC(param2,QC,C1,C2,M,tq,Td2,N,2);
    %X01(4) = X01(4)*(C1(tq(1))/(C1(tq(1))+C2(tq(1))));
    %X01(5) = X01(5)*(C1(tq(1))/(C1(tq(1))+C2(tq(1))));
    %X01(6) = X01(6)*(C1(tq(1))/(C1(tq(1))+C2(tq(1))));
    %X01(9) = X01(9)*(C1(tq(1))/(C1(tq(1))+C2(tq(1))));
      E0=X02(2);
    I0=X02(3);
    psi = sigma + ((1-p)/p)*phi*rho;
    fun=@(x)  log(x)-(Re*(x-1)-(1+psi)*beta*T*(I0+E0)/N);
     Xs=bisection(fun,0,1);
     
     FS2=CC2(1)+1/(1+psi)*N*(1-Xs);
     
     fun=@(x)  log(x)-(beta*T*((x-1)-(1+sigma)*(I0+E0)/N));
     Xs=bisection(fun,0,1);
     
     FS2p0=CC2(1)+1/(1+sigma)*N*(1-Xs);
     
     fsred2=1-FS2/FS2p0;
   % paramfitAggFixp(9) = resnorm;
    paramfitAggFixp(12) = FS2;
     paramfitAggFixp(13) = fsred2*100;
     
    
  
       paramfitAggFixp(2) = paramfitAggFixp(2)*T;
    paramfitAggFixp(6) = paramfitAggFixp(6)*T;
    paramfitAggFixp(9) = resnorm;
    %save('paramfitChinaSeg.mat','paramfitAggFixp')
    %array2table(paramfitAggFixp)
end