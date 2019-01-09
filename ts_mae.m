function [ mae, amae ] = ts_mae( actual, frcst, nTradePeriods )
%TS_MAE Summary of this function goes here
%   Detailed explanation goes here

    if(nargin < 3)
        nTradePeriods = 24;
    end
    
    [nObs, nModels] = size(frcst);
    
    nTpInDay = nTradePeriods;
    
    nDays = fix(nObs/nTpInDay);
    
    mae = zeros(nDays, nModels);
    
    for i = 1:nDays
        for k = 1:nModels
            tRange = (i-1)*nTpInDay+1 : i*nTpInDay;
            mae(i,k) = mean(abs(frcst(tRange,k)-actual(tRange)));
        end
    end
    
    amae = mean(mae);
end