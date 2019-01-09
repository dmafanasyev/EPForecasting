function [ frcst, addInfo ] = tsf_comb_cv( combMethods, prices, frcstind, datetimes, H, cvSchema, nComb, varargin)
%TSF_COMB_CV Summary of this function goes here
%   Detailed explanation goes here

    if(~iscell(combMethods))
        combMethods = {combMethods};
    end
    
    nObs = size(frcstind, 1);
    mCombMethods = size(combMethods, 2);
    
    cvNum = fix((nObs-nComb)/H);
    
    frcst = nan(cvNum, mCombMethods); % forecast combination
    addInfo = cell(cvNum, mCombMethods); % additional information from FC metod
    
    for m = 1:mCombMethods
        %disp(['Start: FC method ', combMethods{m}, ', ', num2str(m), ' of ', num2str(mCombMethods), ', t = ', datestr(now(), 'HH:MM:ss')]);
        for k = 1:cvNum
            switch cvSchema
                case 'RW'
                    % rolling window
                    calibRng = 1+(k-1)*H:nComb+(k-1)*H;
                    combRng = nComb+(k-1)*H+1:nComb+k*H;
                case 'EW'
                    % expanding window
                    calibRng = 1:nComb+(k-1)*H;
                    combRng = nComb+(k-1)*H+1:nComb+k*H;
                otherwise
                    error(['Cross-validation schema "', cvSchema, '" is not recognized']);
            end

            frcstComb = frcstind(combRng,:);
            datetimesComb = datetimes(combRng);
            pricesCalib = prices(calibRng);
            frcstCalib = frcstind(calibRng,:);

            % forecast combination
            [frcst((k-1)*H+1:k*H,m), addInfo{k,m}] =  tsf_comb(frcstComb, datetimesComb, combMethods{m}, pricesCalib, frcstCalib, varargin{:});
        end
        %disp(['Done: FC method ', combMethods{m}, ', ', num2str(m), ' of ', num2str(mCombMethods), ', t = ', datestr(now(), 'HH:MM:ss')]);
    end
end
