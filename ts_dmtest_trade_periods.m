function [ dmstat, pvalue ] = ts_dmtest_trade_periods( actual, forecasts, tp, power)
%TS_DMTEST_TRADE_PERIODS Summary of this function goes here
%   Detailed explanation goes here

%     if(nargin < 7)
%         alpha = 0.05;
%     end
    
    nModels = size(forecasts, 2);
    
    dmstat = zeros(nModels, nModels, tp);
    pvalue = zeros(nModels, nModels, tp);
    actualH = ts_trade_periods(tp, actual);
    
    for i = 1:nModels
        for j = 1:nModels
            if(i ~= j)
                benchmarkH = ts_trade_periods(tp, forecasts(:,i));
                forecastsH = ts_trade_periods(tp, forecasts(:,j));
                for k = 1:tp
                    dmstat(i,j,k) = dmtest(abs(benchmarkH(:,k) - actualH(:,k)), abs(forecastsH(:,k) - actualH(:,k)), 1, power);
                    pvalue(i,j,k) = 1 - normcdf(dmstat(i,j,k));
                end
            end
        end
    end
end

