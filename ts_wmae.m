function [ wmae, awmae ] = ts_wmae( actual, frcst, nTradePeriods )
%TS_WMAE Summary of this function goes here
%   Detailed explanation goes here

    if(nargin < 3)
        nTradePeriods = 24;
    end
    
    [nObs, nModels] = size(frcst);
    
    nTpInWeek = 7*nTradePeriods;
    
    nWeeks = fix(nObs/nTpInWeek);
    
    wmae = zeros(nWeeks, nModels);
    
    for i = 1:nWeeks
        for k = 1:nModels
            tRange = (i-1)*nTpInWeek+1 : i*nTpInWeek;
            wmae(i,k) = 100 * mean(abs(actual(tRange) - frcst(tRange,k))) / mean(actual(tRange));
        end
    end
    
    awmae = mean(wmae);
end

