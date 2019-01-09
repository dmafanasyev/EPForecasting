function [ frcst, output ] = epf_scarx( prices, datetimes, H, load, varargin)
%EPF_SCARX Summary of this function goes here
%   Detailed explanation goes here
    
    if(nargin < 3)
        H = 24;
    end
    
    if(nargin < 4)
        load = [];
    end
    
    if(nargin < 5)
        seasonType = 0;
        outliersFilter = 0;
        outliersFilterParam = [];
    else
        seasonType = varargin{1};
        %if(seasonType ~= 0)
        if(~isempty(seasonType))
            seasonParam = varargin{2};
        end
        
        if(nargin < 7)
            outliersFilter = 0;
            outliersFilterParam = [];
        else
            outliersFilter = varargin{3};
            if(nargin < 8)
                outliersFilterParam = [];
            else
                outliersFilterParam = varargin{4};
            end
        end
    end
    
    if(seasonType)
        % remove LTSC
        [ltsc, pricesl] = ts_ltsc(log(prices), seasonType, seasonParam, H);
        
        if(outliersFilter)
            % filter outliers
            % remove weekly STSC
            [stscw, pricesw] = ts_stsc(pricesl, 1, 7*H);
            % remove daily STSC
            [stscd, pricesd] = ts_stsc(pricesw, 1, H);
            % filter outliers for LTSC estimation
            [pricesx, output{1}] = ts_outliers(pricesd, outliersFilter, outliersFilterParam);
            % remove correct LTSC from filtered prices
            [ltsc, prices] = ts_ltsc(ltsc + stscw + stscd + pricesx, seasonType, seasonParam, H);
        else
            prices = pricesl;
        end
        
        frcstLtsc = ltsc(end-H+1:end);
        
        if(~isempty(load))
            [~, load] = ts_ltsc(log(load), seasonType, seasonParam, H);
        end
    end
    
    [pricesH, datetimesH] = ts_trade_periods(H, prices, datetimes);
    
    calStart = 8;
    
    % calibration data
    pricesHCal = pricesH(calStart:end,:);
    % lagged prices
    pricesHLag7 = pricesH(calStart-7:end-6,:);
    % price signal from previous day
    priceSignal = get_price_signal_int(pricesH(calStart-1:end,:));
    
    if(seasonType == 0)
        % remove mean for ARX case
        pricesHCal = log(pricesHCal);
        pricesHCalMean = mean(pricesHCal, 1);
        pricesHCal = pricesHCal - repmat(pricesHCalMean, size(pricesHCal,1), 1);
        pricesHLag7 = log(pricesHLag7);
        pricesHLag7 = pricesHLag7 - repmat(mean(pricesHLag7, 1), size(pricesHLag7,1), 1);
        priceSignal = log(priceSignal);
        priceSignal = priceSignal - mean(priceSignal);
    end
    
    % daily dummy
    datesCal = datetimesH(calStart:end,1);
    daysCal = get_days_dummy_int(datesCal);
    
    % load predictions
    if(~isempty(load))
        loadH = ts_trade_periods(H, load);
        loadH = loadH(calStart:end,:);
        if(seasonType == 0)
            loadH = log(loadH);
        end
    end
    
    frcstH = zeros(1,H);
    
    for hour = 1:H
        y = pricesHCal(4:end,hour);
        x = [pricesHCal(3:end-1,hour) pricesHCal(2:end-2,hour) pricesHLag7(4:end-1,hour) priceSignal(4:end-1,1) daysCal(4:end,:)];
        xFrcst = [pricesHCal(end,hour) pricesHCal(end-1,hour) pricesHLag7(end,hour) priceSignal(end,1) get_days_dummy_int(datesCal(end)+1)];
        
        if(~isempty(load))
            x = [x loadH(4:end-1,hour)];
            xFrcst = [xFrcst loadH(end,hour)];
        end

        beta = regress(y, x);
        frcstH(1,hour) = xFrcst*beta;
    end
    
    if(seasonType == 0)
        frcst = exp(pricesHCalMean + frcstH)';
    else
        frcst = exp(frcstLtsc + frcstH');
    end
    
    if(~exist('output', 'var'))
        output = [];
    end
end

function days = get_days_dummy_int ( dates )
    days = [(weekday(dates) == 2) (weekday(dates) == 7) (weekday(dates) == 1)];
end

function signal = get_price_signal_int ( prices )
    signal = min(prices, [], 2);
end