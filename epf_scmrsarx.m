function [ frcst ] = epf_scmrsarx( prices, datetimes, H, load, varargin)
    %EPF_SCMRSARX Summary of this function goes here
    %   Detailed explanation goes here
    
    if(nargin < 3)
        H = 24;
    end
    
    if(nargin < 4)
        load = [];
    end
    
    defOutPercent = [0.95 0.05];
    
    if(nargin < 5)
        seasonType = 0;
        outPercent = defOutPercent;
    else
        seasonType = varargin{1};
        if(seasonType ~= 0)
            seasonParam = varargin{2};
        end
        
        if(nargin < 7)
            outPercent = defOutPercent;
        else
            outPercent = varargin{3};
        end
    end
    
    spikePrice = quantile(log(prices), outPercent(1));
    dropPrice = quantile(log(prices), outPercent(2));
    
    if(seasonType == 1) % wavelet db24
        dwtmode('sp0','nodisp');
        pricesExt = [prices; mean(prices(end-H+1:end))];
        [C, L] = wavedec(log(pricesExt), seasonParam + 2, 'db24');
        ltsc = wrcoef('a', C, L, 'db24', seasonParam);
        ltsc = ltsc(1:end-1,:);
    elseif(seasonType == 2) % HP filter
        ltsc = hpfilter(log(prices), seasonParam);
    elseif(seasonType == 3) % EMD filter
        [~, ltsc] = emd_processing(log(prices), seasonParam);
    end
    
    if(seasonType ~= 0)
        frcstLtsc = ltsc(end-H+1:end);
        prices = log(prices) - ltsc;
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
        % remove mean for no seasonality case 
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
    
    % MRS(3) model switching flags
    S = [1 1 1 1 1 1 1 1 1];
    
    % load predictions
    if(~isempty(load))
        loadH = ts_trade_periods(H, load);
        loadH = loadH(calStart:end,:);
        loadH = log(loadH);
        S = [1 1 1 1 1 1 1 1 1 1 1];
    end
    
    % MRS(3) model & estimator configuration
    advOpt.distrib = 'GED2';
    advOpt.std_method = 2;
    advOpt.printIter = 0;
    advOpt.printOut = 0;
    advOpt.doPlots = 0;
    advOpt.useMex = 1;
    
    advOpt.constCoeff.nS_Param{1} = {0};
    advOpt.constCoeff.covMat{1}(1,1) = {'e'};
    advOpt.constCoeff.covMat{2}(1,1) = {'e'};
    advOpt.constCoeff.covMat{3}(1,1) = {'e'};
    %advOpt.constCoeff.K{1} = {0, 'e', 'e'};
    advOpt.constCoeff.K{1} = {0, -1, 1};% normal distriburion under base regime and skewed GND ver.2 under outliers regimes
    advOpt.constCoeff.p = {'e', 'e', 'e';...
        'e', 'e', 'e';...
        'e', 'e', 'e';};
    
    frcstH = zeros(1,H);
    
    for hour = 1:H
        y = pricesHCal(4:end,hour);
        x = [ones(length(y), 1) pricesHCal(3:end-1,hour) pricesHCal(2:end-2,hour) pricesHLag7(4:end-1,hour) priceSignal(4:end-1,1) daysCal(4:end,:)];
        xFrcst = [1 pricesHCal(end,hour) pricesHCal(end-1,hour) pricesHLag7(end,hour) priceSignal(end,1) get_days_dummy_int(datesCal(end)+1)];
        
        advOpt.constCoeff.S_Param{1} = {0, spikePrice, dropPrice;...
            'e', 0, 0;...
            'e', 0, 0;...
            'e', 0, 0;...
            'e', 0, 0;...
            'e', 0, 0;...
            'e', 0, 0;...
            'e', 0, 0};
        
        if(~isempty(load))
            x = [x loadH(4:end-1,hour)];
            xFrcst = [xFrcst loadH(end,hour)];
            
            advOpt.constCoeff.S_Param{1} = {0, spikePrice, dropPrice;...
                'e', 0, 0;...
                'e', 0, 0;...
                'e', 0, 0;...
                'e', 0, 0;...
                'e', 0, 0;...
                'e', 0, 0;...
                'e', 0, 0;...
                'e', 0, 0};
        end
        
        % estimate model MRS(k)
        mrs = MS_Regress_Fit(y, x, 3, S, advOpt);
        frcstH(1,hour) = MS_Regress_For(mrs, xFrcst);
        
        %beta = regress(y, x);
        %frcstH(1,hour) = xFrcst*beta;
    end
    
    if(seasonType == 0)
        frcst = exp(pricesHCalMean + frcstH)';
    else
        frcst = exp(frcstLtsc + frcstH');
    end
end

function days = get_days_dummy_int ( dates )
    days = [(weekday(dates) == 2) (weekday(dates) == 7) (weekday(dates) == 1)];
end

function signal = get_price_signal_int ( prices )
    signal = min(prices, [], 2);
end