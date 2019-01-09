function [ dataH, datetimesH ] = ts_trade_periods( nTradePeriods, data, datetimes)
%TS_TRADE_PERIODS Summary of this function goes here
%   Detailed explanation goes here
%     if(nargin < 2 || isempty(data) || isempty(datetimes) || nnz(size(data) ~= size(datetimes)))
%         error('Data and datetimes must be non empty matrixes or vectors with the equal number of rows and columns');
%     end
    
    if(nargin < 3)
        datetimes = [];
    end
    
    [nObs, nHours] = size(data);
    
    if(nTradePeriods == nHours)
        dataH = data;
        if(~isempty(datetimes))
            datetimesH = datetimes;
        end
    else
        nDays = floor(nObs/nTradePeriods);
        
        if(nDays < 1)
            error(['Number of observations is smaller then ', num2str(nTradePeriods)]);
        end
        
        nBalance = nObs - nDays*nTradePeriods;
        if(nBalance > 0)
            warning(['Number of observations does not consist of an integer number of days, the last ', num2str(nBalance), ' observations are ignored']);
        end
        
        dataH = data(1:nDays*nTradePeriods);
        if(~isempty(datetimes))
            datetimesH = datetimes(1:nDays*nTradePeriods);
        end

        dataH = (reshape(dataH, nTradePeriods, nDays))';
        if(~isempty(datetimes))
            datetimesH = (reshape(datetimesH, nTradePeriods, nDays))';
        end
    end
end
