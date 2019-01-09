function [ frcst, varargout ] = tsf_cv( fhandler, data, datetimes, H, nTrain, nTest, cvType, eX, varargin )
    %TSF_CV Cross-validation of time-series forecasting model.
    %   Detailed explanation goes here
    %   cvType: 1 - rolling window (default), 2 - expanded window
    %   
    
    if(nargin < 2)
        error('Forecasting model function handler must be non empty');
    end
    
    if(nargin < 3 || isempty(data) || isempty(datetimes) || nnz(size(data) ~= size(datetimes)))
        error('Data and datetimes must be non empty matrixes or vectors with the equal number of row and column');
    end
    
    nObs = size(data, 1);
    
    if(nargin < 4)
        % one step-ahead forecast
        H = 1;
    end
    
    if(nargin < 5)
        % use 70% of observations as the training sample size
        nTrain = fix(0.7*nObs);
    end
    
    if(nargin < 6)
        % use all observations after training sample as a test sample
        nTest = nObs - nTrain;
    end

    if(nargin < 7)
        % rolling window CV
        cvType = 'RW';
    end
    
    if(nargin < 8)
        % 
        eX = [];
    end
    
    if(nTrain > nObs)
        error('The training (in-sample) period exceeds the data size');
    end

    if(nTrain + nTest > nObs)
        error('The test (out-of-sample) period exceeds the data size');
    end
    
    nCV = fix(nTest/H);
    
    frcst = nan(nCV,1);
    
    disp(['Start, t = ', datestr(now(), 'HH:MM:ss')]);
    for k = 1:nCV
        switch cvType
            case 'RW'
                % rolling window
                trainRange = 1+(k-1)*H:nTrain+(k-1)*H;
                exRange = 1+(k-1)*H:nTrain+k*H;
            case 'EW'
                % expanded window
                trainRange = 1:nTrain+(k-1)*H;
                exRange = 1:nTrain+k*H;
            otherwise
                error(['Cross-validation schema "', cvType, '" is not recognized']);
        end
        
        dataTrain = data(trainRange,:);
        datetimesTrain = datetimes(trainRange,:);
        if(~isempty(eX))
            exTrain = eX(exRange,:);
        else
            exTrain = [];
        end
        
        % forecast for H horizont
        [frcst((k-1)*H+1:k*H,:), output] = fhandler(dataTrain, datetimesTrain, H, exTrain, varargin{:});
        
        for i = 1:length(output)
            varargout{i}{k} = output{i};
        end
        
        disp(['Done ', num2str(k) ,', t = ', datestr(now(), 'HH:MM:ss')]);
    end
end
