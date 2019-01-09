function [ dataf, outliers ] = ts_outliers( data, type, param )
%TS_OUTLIERS Filter the outliers from time-series using the different methods.
%   
%   INPUT:
%     data - time-series for filtering
%     type - outliers filter type:
%           TFP - Threshold filter on prices
%           SFP - Standard deviation filter on prices
%           RFP - Recursive filter on prices (iterative SFP)
%           PFP - Percentage filter on prices
%           MFP - Moving filter on prices (sliding SFP)
%           CFP - Combined filter on prices
%     param - filter parameters:
%           TFP - the fixed price threshold value, default is 0.5
%           SFP - the standard deviation number, default is 3
%           RFP - the standard deviation number, default is 3
%           PFP - symmetric percentage of highest and lowest prices, default is 2.5%
%           MFP - if scalar - the standard deviation number, 
%                       if two-elements vector: the first is standard deviation number, the second is  moving window size;
%                       default is [1.96 672] (1.96 - 95% prediction interval of normal PDF, 672 ~ 1 month in hours)
%           CFP - if scalar - the fraction of filters that must treats the observation as outlier, default is 0.5 (i.e. 50%);
%                      if cell array - the first cell is fraction of filters, the next cells are form one to three
%                      elements cell where first is filter type, second (optional) is filter parameters (the same as
%                      described above) and third (optional) is filter weight (default is equal weights schema)
%                      Examples:
%                      - Full parametrization: {0.5, {'TFP', 0.5, 1/5}, {'SFP', 3, 2/5}, {'RFP', 3, 1/10}, {'MFP', [3 4*7*24], 1/5}, {'PFP', 2.5, 1/10}}
%                      - Equal weights schema: {0.5, {'TFP', 0.5}, {'SFP', 3}, {'RFP', 3}, {'MFP', [3 4*7*24]}, {'PFP', 2.5}}
%                      - Default parameters: {0.5, {'TFP'}, {'SFP'}, {'RFP'}, {'MFP'}, {'PFP'}}
%                      - Combination of 3 filters only with default parameters: {0.5, {'TFP'}, {'SFP'}, {'MFP'}}
%
%   Output:
%       dataf - filtered time-series
%       outliers - two column logical matrix with outliers flag (positive and negative)
%
%   Copyright (c) 2018 by Dmitriy O. Afanasyev
%   Versions:
%   v0.1 2018.01.07: initial version
%   v0.2 2018.03.07: refactoring of CFP input param variable
%   v0.3 2018.04.17: weighted voting for CFP
%
    
    if(nargin < 3)
        param = [];
    end
    
    switch type
        case 'TFP'
            % Threshold filter on prices
            [dataf, spikes, drops] = of_tfp(data, param);
        case 'SFP'
            % Standard deviation filter on prices
            [dataf, spikes, drops] = of_sfp(data, param);
        case 'RFP'
            % Recursive filter on prices
            [dataf, spikes, drops] = of_rfp(data, param);
        case 'PFP'
            % Percentage filter on prices
            [dataf, spikes, drops] = of_pfp(data, param);
        case 'MFP'
            % Moving filter on prices
            [dataf, spikes, drops] = of_mfp(data, param);
        case 'CFP'
            % Combined filter on prices
            [dataf, spikes, drops] = of_cfp(data, param);
        otherwise
            error(['Outliers filter method ', type ,' not recognized']);
    end
    
    outliers = [spikes drops];
end


function [ dataf, spikes, drops ] = of_tfp(data, param)
    if(nargin < 2 || isempty(param))
        tr = 0.5;
    else
        tr = param;
    end

    outrep = mean(data);

    spikes = (data >= tr);
    drops = (data <= -tr);

    dataf = data;
    dataf(spikes) = outrep;
    dataf(drops) = outrep;
end

function [ dataf, spikes, drops ] = of_sfp(data, param)
    if(nargin < 2 || isempty(param))
        ns = 3;
    else
        ns = param;
    end

    outrep = mean(data);

    spikes = (data >= mean(data) + ns*std(data));
    drops = (data <= mean(data) - ns*std(data));

    dataf = data;
    dataf(spikes) = outrep;
    dataf(drops) = outrep;
end

function [ dataf, spikes, drops ] = of_rfp(data, param)
    if(nargin < 2 || isempty(param))
        ns = 3;
    else
        ns = param;
    end

    outrep = mean(data);

    spikes = zeros(size(data));
    drops = zeros(size(data));
    dataf = data;
    repflag = true;
    while(repflag)
        spikestmp = logical(dataf >= mean(dataf)+ns*std(dataf));
        dropstmp = logical(dataf <= mean(dataf)-ns*std(dataf));

        if(nnz(spikestmp))
            dataf(spikestmp) = outrep;
        end
        if(nnz(dropstmp))
            dataf(dropstmp) = outrep;
        end

        if(~nnz(spikestmp) && ~nnz(dropstmp))
            repflag = false;
        end

        spikes = spikes + spikestmp;
        drops = drops+ dropstmp;
    end
    spikes = (spikes == 1);
    drops = (drops == 1);
end

function [ dataf, spikes, drops ] = of_pfp(data, param)
    if(nargin < 2 || isempty(param))
        p = 2.5;
    else
        p = param;
    end

    outrep = mean(data);

    spikes = (data >= prctile(data, 100-p));
    drops = (data <= prctile(data, p));

    dataf = data;
    dataf(spikes) = outrep;
    dataf(drops) = outrep;
end

function [ dataf, spikes, drops ] = of_mfp(data, param)
    defWin = 4*7*24;
    
    if(nargin < 2 || isempty(param))
        ns = 1.96;
        win = defWin;
    else
        if(isvector(param))
            ns = param(1);
            win = param(2);
        else
            ns = param;
            win = defWin;
        end
    end

    nObs = length(data);
    nWin = nObs/win;

    spikes = zeros(size(data));
    drops = zeros(size(data));
    dataf = data;
    for i=1:nWin
        if(i < nWin)
            rngWin = (i-1)*win+1:i*win;
        else
            rngWin = (i-1)*win+1:nObs;
        end

        datawin = data(rngWin);
        meanwin = mean(datawin);
        stdwin = std(datawin);

        spikes(rngWin) = (datawin >= meanwin+ns*stdwin);
        drops(rngWin) = (datawin <= meanwin-ns*stdwin);
        datawin(spikes(rngWin)==1) = meanwin;
        datawin(drops(rngWin)==1) = meanwin;
        dataf(rngWin) = datawin;
    end

    spikes = (spikes == 1);
    drops = (drops == 1);
end

function [ dataf, spikes, drops ] = of_cfp(data, param)
    defWeight = 1/5;
    defFilters = {{'TFP', [], defWeight}, {'SFP', [], defWeight}, {'RFP', [], defWeight}, {'MFP', [], defWeight}, {'PFP', [], defWeight}};
    
    if(nargin < 2 || isempty(param))
        q = 0.5;
        filters = defFilters;
    else
        if(iscell(param))
            q = param{1};
            filters = param(2:end);
        else
            q = param;
            filters = defFilters;
        end
    end
    
    nFilters = length(filters);
    nObs = size(data,1);
    spikes = false(nObs, nFilters);
    drops = false(nObs, nFilters);
    fweight = zeros(1, nFilters);
    
    for k=1:nFilters
        ftype = filters{k}{1};
        if(length(filters{k}) >= 2)
            fparam = filters{k}{2};
        else
            fparam = [];
        end
        
        if(length(filters{k}) >= 3)
            fweight(k) = filters{k}{3};
        else
            fweight(k) = defWeight;
        end
        
        switch ftype
            case 'TFP'
                filterfunc = @of_tfp;
            case 'SFP'
                filterfunc = @of_sfp;
            case 'RFP'
                filterfunc = @of_rfp;
            case 'MFP'
                filterfunc = @of_mfp;
            case 'PFP'
                filterfunc = @of_pfp;
            otherwise
                error(['Outliers filter method ', ftype ,' not recognized']);
        end
        
        [~, spikes(:,k), drops(:,k)] = filterfunc(data, fparam);
    end

    outrep = mean(data);
    
    %spikes = sum(fweight.*spikes, 2);
    spikes = round(fweight*spikes', 2);
    spikes = (spikes >= q);
    
    %drops = sum(fweight.*drops, 2);
    drops = round(fweight*drops', 2);
    drops = (drops >= q);
    
%     spikes = sum(spikes, 2);
%     spikes = (spikes >= q*nFilters);
% 
%     drops = sum(drops, 2);
%     drops = (drops >= q*nFilters);
    
    dataf = data;
    dataf(spikes) = outrep;
    dataf(drops) = outrep;
end


%         case 'SFR'
%             % Single filter on returns
%             if(nargin < 3 || isempty(param))
%                 n = 3;
%             else
%                 n = param;
%             end
%             
%             outrep = mean(data);
%             
%             dif = data(2:end)-data(1:end-1);
%             dif = [0; dif];
%             
%             spikes = (dif >= mean(dif) + n*std(dif));
%             drops = (dif <= mean(dif) - n*std(dif));
%             
%             dataf = data;
%             dataf(spikes) = outrep;
%             dataf(drops) = outrep;
%         case 'RFD'
%             % Recursive filter on differences
%             if(nargin < 3 || isempty(param))
%                 n = 3;
%             else
%                 n = param;
%             end
%             
%             outrep = mean(data);
%             
%             spikes = zeros(size(data));
%             drops = zeros(size(data));
%             dataf = data;
%             
%             dif = dataf(2:end)-dataf(1:end-1);
%             dif = [0; dif];
%             up = mean(dif) + n*std(dif);
%             lo = mean(dif) - n*std(dif);
%             
%             for i = 1:length(dataf)
%                 if(i == 1)
%                     d = dataf(i);
%                 else
%                     d = dataf(i)-dataf(i-1);
%                 end
%                 if d > up
%                     dataf(i) = outrep;
%                     spikes(i) = 1;
%                 end
%                 if d < lo
%                     dataf(i) = outrep;
%                     drops(i) = 1;
%                 end
%             end
%             
%             spikes = (spikes > 0);
%             drops = (drops > 0);
