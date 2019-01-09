function [ dmae, admae ] = ts_dmae( actual, frcst, nTradePeriods )
%TS_DMAE Summary of this function goes here
%   Detailed explanation goes here

    if(nargin < 3)
        nTradePeriods = 24;
    end
    
    [nObs, nModels] = size(frcst);
    
    nTpInDay = nTradePeriods;
    
    nDays = fix(nObs/nTpInDay);
    
    dmae = zeros(nDays, nModels);
    
    for i = 1:nDays
        for k = 1:nModels
            tRange = (i-1)*nTpInDay+1 : i*nTpInDay;
            dmae(i,k) = 100 * mean(abs(frcst(tRange,k)-actual(tRange))) / mean(actual(tRange));
        end
    end
    
    admae = mean(dmae);
end