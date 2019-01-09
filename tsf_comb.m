function [ frcst, mcsInfo ] = tsf_comb( frcstCalc, datetimesCalc, combMethod, pricesComb, frcstComb, varargin)
%TSF_COMB Summary of this function goes here
%   Detailed explanation goes here
    
    %TODO: check length of forecasts >= length of prices
    %TODO: check that forecasts models number is 2 or greater
    
    loss210paramDef = [0.01, 10, 3, -3, 0.7, 0.7];
    
    if(strcmp(combMethod, 'MPV') || contains(combMethod, 'MCS'))
        mcsInfo = cell(2,1);
    
        % For MPV or MCS trimmed methods the first varargin is parameters of MCS routine
        if(nargin < 6)
            mcsLossType = 'L1';
            mcsWin = 24;
            mcsAlpha = 0.5;
            mcsRule = 'R';
            mcsLossParam = [];
            if(strcmp(mcsLossType, 'L210'))
                mcsLossParam = loss210paramDef;
            end
        else
            mcsParam = varargin{1};
            mcsLossType = mcsParam{1};
            mcsWin = mcsParam{2};
            mcsAlpha = mcsParam{3};
            mcsRule = mcsParam{4};
            mcsLossParam = [];
            if(strcmp(mcsLossType, 'L210'))
                % For MCS loss function L210 the last cell of mcsParam is an vector of the loss function parameters
                if(length(mcsParam) < 5)
                    mcsLossParam = loss210paramDef;
                else
                    mcsLossParam = mcsParam{5};
                end
            end
        end
        
        lossParam = [];
        if(strcmp(combMethod, 'MCS-IML210'))
            % For MCS-IML210 the second varargin is vector of the L210 loss function parameters for weighting (not for MCS trimming)
            if(nargin < 7)
                lossParam = loss210paramDef;
            else
                lossParam = varargin{2};
            end
        end
    elseif(strcmp(combMethod, 'IML210') || strcmp(combMethod, 'BI-ML210'))
        % For IML210 and BI-ML210 the first varargin is vector of of the L210 loss function parameters
        if(nargin < 6)
            lossParam = loss210paramDef;
        else
            lossParam = varargin{1};
        end
    end
    
    switch combMethod
        case 'SA'
            % Simple averaging (SA)
            frcst = fc_sa(frcstCalc);
        case 'SM'
            % Simple median (SM)
            frcst = fc_sa(frcstCalc, 1);
        case 'TA'
            % Trimmed averaging (TA)
            frcst = fc_ta(frcstCalc);
        case 'TM'
            % Trimmed median (TM)
            frcst = fc_ta(frcstCalc, 1);
        case 'WA'
            % Windsorized averaging (WA)
            frcst = fc_wa(frcstCalc);
        case 'WM'
            % Windsorized median (WM)
            frcst = fc_wa(frcstCalc, 1);
        case 'OLS'
            % Ordinary Least Squares (OLS)
            frcst = fc_ols(frcstCalc, pricesComb, frcstComb);
        case 'IRLS'
            % Iteratively Reweighted Least Squares (IRLS)
            frcst = fc_irls(frcstCalc, pricesComb, frcstComb);
        case 'LAD'
            % Least Absolute Deviation (LAD) = Quantile Regression with p = 0.5 (median)
            frcst = fc_lad(frcstCalc, pricesComb, frcstComb);
        case 'PW'
            % Positive Weights (PW) OLS - nonnegative linear least-squares problem
            frcst = fc_pw(frcstCalc, pricesComb, frcstComb);
        case 'CLS'
            % Constrained Least Squares (CLS): PW + normalized weights
            frcst = fc_cls(frcstCalc, pricesComb, frcstComb);
        case 'IRMSE'
            % Inverted Root Mean Squared Error (RMSE)
            frcst = fc_irmse(frcstCalc, pricesComb, frcstComb);
        case 'IMSE'
            % Inverted Mean Squared Error (IMSE)
            frcst = fc_imse(frcstCalc, pricesComb, frcstComb);
        case 'IMAE'
            % Inverted Mean Absolute Error (IMAE)
            frcst = fc_imae(frcstCalc, pricesComb, frcstComb);
        case 'IDMAE'
            % Inverted Daily-Weighted Mean Absolute Error (DMAE)
            frcst = fc_idmae(frcstCalc, pricesComb, frcstComb);
        case 'IML210'
            % Inverted mean outlier protective L210 loss (IML210)
            frcst = fc_iml210(frcstCalc, pricesComb, frcstComb, lossParam);
        case 'MPV'
            % Model confidence set p-value with all models
            [frcst, mcsInfo{1}, mcsInfo{2}] = fc_mcs_mpv(frcstCalc, pricesComb, frcstComb, mcsLossType, mcsWin, eps, mcsRule, mcsLossParam);
        case 'BI-RMSE'
            % Best Individual forecast based on RMSE
            frcst = fc_bi_rmse(frcstCalc, pricesComb, frcstComb);
        case 'BI-MSE'
            % Best Individual forecast based on MSE
            frcst = fc_bi_mse(frcstCalc, pricesComb, frcstComb);
        case 'BI-MAE'
            % Best Individual forecast based on MAE
            frcst = fc_bi_mae(frcstCalc, pricesComb, frcstComb);
        case 'BI-ML210'
            % Best Individual forecast based on ML210
            frcst = fc_bi_ml210(frcstCalc, pricesComb, frcstComb, lossParam);
        case 'BI-WMAE'
            % Best Individual forecast based on averaged WMAE
            frcst = fc_bi_wmae(frcstCalc, pricesComb, frcstComb);
        case 'BI-DMAE'
            % Best Individual forecast based on averaged DMAE
            frcst = fc_bi_dmae(frcstCalc, pricesComb, frcstComb);
        case 'MSER'
            % to implement Mean Square Error Ranks. (todo)
            error('Not implemented yet');
            %frcst = [];
            %kmeans(mean((frcstComb - pricesComb).^2), 4);
            %Mean Square Error Ranks: The method of MSE ranks, proposed by Aiolfi and Timmermann
            % (2006), sorts single models into clusters with respect to their MSE values by
            % a k-means algorithm, then forecasts are pooled within each cluster. Finally, this method
            % determines the weights of each cluster in combination so as to be inversely proportional
            % to the models ranks. This combination method can be expected to be more robust than
            % the methods of LS weights and MSE weights, because it is less sensitive to outliers
            % (Timmermann 2006).

        % MCS trimmed forecast combinations
            
        case 'MCS-SA'
            % Model confidence set trimmed, Simple averaging (SA)
            mcsIdx = mcs_trim(pricesComb, frcstComb, mcsLossType, mcsWin, mcsAlpha, mcsRule, mcsLossParam);
            frcst = fc_sa(frcstCalc(:,mcsIdx));
        case 'MCS-SM'
            % Model confidence set trimmed, Simple median (SM)
            mcsIdx = mcs_trim(pricesComb, frcstComb, mcsLossType, mcsWin, mcsAlpha, mcsRule, mcsLossParam);
            frcst = fc_sa(frcstCalc(:,mcsIdx), 1);
        case 'MCS-OLS'
            % Model confidence set trimmed, Ordinary Least Squares (OLS)
            mcsIdx = mcs_trim(pricesComb, frcstComb, mcsLossType, mcsWin, mcsAlpha, mcsRule, mcsLossParam);
            frcst = fc_ols(frcstCalc(:,mcsIdx), pricesComb, frcstComb(:,mcsIdx));
        case 'MCS-IRLS'
            % Model confidence set trimmed, Iteratively Reweighted Least Squares (IRLS)
            mcsIdx = mcs_trim(pricesComb, frcstComb, mcsLossType, mcsWin, mcsAlpha, mcsRule, mcsLossParam);
            frcst = fc_irls(frcstCalc(:,mcsIdx), pricesComb, frcstComb(:,mcsIdx));
        case 'MCS-LAD'
            % Model confidence set trimmed, Least Absolute Deviation (LAD) = Quantile Regression with 0.5 (median)
            mcsIdx = mcs_trim(pricesComb, frcstComb, mcsLossType, mcsWin, mcsAlpha, mcsRule, mcsLossParam);
            frcst = fc_lad(frcstCalc(:,mcsIdx), pricesComb, frcstComb(:,mcsIdx));
        case 'MCS-PW'
            % Model confidence set trimmed, Positive Weights (PW) OLS - nonnegative linear least-squares problem
            mcsIdx = mcs_trim(pricesComb, frcstComb, mcsLossType, mcsWin, mcsAlpha, mcsRule, mcsLossParam);
            frcst = fc_pw(frcstCalc(:,mcsIdx), pricesComb, frcstComb(:,mcsIdx));
        case 'MCS-CLS'
            % Model confidence set trimmed, Constrained Least Squares (CLS): PW + normalized weights
            mcsIdx = mcs_trim(pricesComb, frcstComb, mcsLossType, mcsWin, mcsAlpha, mcsRule, mcsLossParam);
            frcst = fc_cls(frcstCalc(:,mcsIdx), pricesComb, frcstComb(:,mcsIdx));
        case 'MCS-IRMSE'
            % Model confidence set trimmed, Inverted Root Mean Squared Error (RMSE)
            mcsIdx = mcs_trim(pricesComb, frcstComb, mcsLossType, mcsWin, mcsAlpha, mcsRule, mcsLossParam);
            frcst = fc_irmse(frcstCalc(:,mcsIdx), pricesComb, frcstComb(:,mcsIdx));
        case 'MCS-IMSE'
            % Model confidence set trimmed, Inverted Mean Squared Error (IMSE)
            mcsIdx = mcs_trim(pricesComb, frcstComb, mcsLossType, mcsWin, mcsAlpha, mcsRule, mcsLossParam);
            frcst = fc_imse(frcstCalc(:,mcsIdx), pricesComb, frcstComb(:,mcsIdx));
        case 'MCS-IMAE'
            % Model confidence set trimmed, Inverted Mean Absolute Error (IMAE)
            mcsIdx = mcs_trim(pricesComb, frcstComb, mcsLossType, mcsWin, mcsAlpha, mcsRule, mcsLossParam);
            frcst = fc_imae(frcstCalc(:,mcsIdx), pricesComb, frcstComb(:,mcsIdx));
        case 'MCS-IML210'
            % Model confidence set trimmed, Inverted mean outlier protective L210 loss (IML210)
            mcsIdx = mcs_trim(pricesComb, frcstComb, mcsLossType, mcsWin, mcsAlpha, mcsRule, mcsLossParam);
            frcst = fc_iml210(frcstCalc(:,mcsIdx), pricesComb, frcstComb(:,mcsIdx), lossParam);
        case 'MCS-IDMAE'
            % Model confidence set trimmed, Inverted Daily-Weighted Mean Absolute Error (DMAE)
            mcsIdx = mcs_trim(pricesComb, frcstComb, mcsLossType, mcsWin, mcsAlpha, mcsRule, mcsLossParam);
            frcst = fc_idmae(frcstCalc(:,mcsIdx), pricesComb, frcstComb(:,mcsIdx));
        case 'MCS-BI'
            % Model confidence set trimmed, Best Individual model based on MCS p-value
            mcsIdx = mcs_trim(pricesComb, frcstComb, mcsLossType, mcsWin, mcsAlpha, mcsRule, mcsLossParam);
            frcst = frcstCalc(:,mcsIdx(end));
        case 'MCS-MPV'
            % Model confidence set p-value with trimmed models
            [frcst, mcsIdx] = fc_mcs_mpv(frcstCalc, pricesComb, frcstComb, mcsLossType, mcsWin, mcsAlpha, mcsRule, mcsLossParam);
        otherwise
            error(['Forecast combinations method "', combMethod, '" is not recognized']);
    end
    
    %datetimes = datetimesCalc;
end

function [ frcst ] = fc_sa(frcstCalc, isMedian)
    if(nargin < 2)
        isMedian = 0;
    end
    
    if(~isMedian)
        frcst = mean(frcstCalc, 2);
    else
        frcst = median(frcstCalc, 2);
    end
end

function [ frcst ] = fc_ta(frcstCalc, isMedian)
    if(nargin < 2)
        isMedian = 0;
    end
    
    mComb = size(frcstCalc,2);
    if(mComb >= 3)
        sorted = sort(frcstCalc, 2);
        if(~isMedian)
            frcst = mean(sorted(:,2:end-1), 2);
        else
            frcst = median(sorted(:,2:end-1), 2);
        end
    else
        % if number of individual forecasts less 3 then use SA
        frcst = fc_sa(frcstCalc, isMedian);
    end
end

function [ frcst ] = fc_wa(frcstCalc, isMedian)
    if(nargin < 2)
        isMedian = 0;
    end
    
    mComb = size(frcstCalc,2);
    if(mComb >= 3)
        sorted = sort(frcstCalc, 2);
        sorted(:,1) = sorted(:,2);
        sorted(:,end) = sorted(:,end-1);
        if(~isMedian)
            frcst = mean(sorted, 2);
        else
            frcst = median(sorted, 2);
        end
    else
        % if number of individual forecasts less 3 then use SA
        frcst = fc_sa(frcstCalc, isMedian);
    end
end

function [ frcst ] = fc_ols(frcstCalc, pricesComb, frcstComb)
    mComb = size(frcstComb,2);
    if(mComb >= 2)
        w = regress(pricesComb, [ones(size(frcstComb,1),1) frcstComb]);
        frcst = [ones(size(frcstCalc,1),1) frcstCalc]*w;
	else
        % if number of individual forecasts less 2 then use one model
        frcst = frcstCalc;
    end
end

function [ frcst ] = fc_irls(frcstCalc, pricesComb, frcstComb)
    mComb = size(frcstComb,2);
    if(mComb >= 2)
        w = robustfit(frcstComb, pricesComb); % constant is adeed by default
        frcst = [ones(size(frcstCalc,1),1) frcstCalc]*w;
	else
        % if number of individual forecasts less 2 then use one model
        frcst = frcstCalc;
    end
end

function [ frcst ] = fc_lad( frcstCalc, pricesComb, frcstComb)
    mComb = size(frcstComb,2);
    if(mComb >= 2)
        beta = quantreg(frcstComb, pricesComb, 0.5);
        frcst = frcstCalc*beta;
	else
        % if number of individual forecasts less 2 then use one model
        frcst = frcstCalc;
    end
end

function [ frcst ] = fc_pw(frcstCalc, pricesComb, frcstComb)
    mComb = size(frcstComb,2);
    if(mComb >= 2)
        options = optimoptions('lsqlin', 'Algorithm', 'interior-point', 'Display', 'none');
        w = lsqlin(frcstComb, pricesComb, [], [], [], [], zeros(mComb,1), Inf(mComb,1), [], options);
        w(abs(w) <= eps) = 0;
        frcst = frcstCalc*w;
	else
        % if number of individual forecasts less 2 then use one model
        frcst = frcstCalc;
    end
end

function [ frcst ] = fc_cls(frcstCalc, pricesComb, frcstComb)
    mComb = size(frcstComb,2);
    if(mComb >= 2)
        options = optimoptions('lsqlin', 'Algorithm', 'interior-point', 'Display', 'none');
        w = lsqlin(frcstComb, pricesComb, [], [], ones(1,mComb), ones(1,1), zeros(mComb,1), Inf(mComb,1), [], options);
        w(abs(w) <= eps) = 0;
        frcst = frcstCalc*w;
	else
        % if number of individual forecasts less 2 then use one model
        frcst = frcstCalc;
    end
end

function [ frcst ] = fc_irmse(frcstCalc, pricesComb, frcstComb)
    irmse = 1./sqrt(mean((frcstComb - pricesComb).^2));
    w = (irmse./sum(irmse, 2))';
    frcst = frcstCalc*w;
end

function [ frcst ] = fc_imse(frcstCalc, pricesComb, frcstComb)
    imse = 1./mean((frcstComb - pricesComb).^2);
    w = (imse./sum(imse, 2))';
    frcst = frcstCalc*w;
end

function [ frcst ] = fc_imae(frcstCalc, pricesComb, frcstComb)
    imae = 1./mean(abs(frcstComb - pricesComb));
    w = (imae./sum(imae, 2))';
    frcst = frcstCalc*w;
end

function [ frcst ] = fc_idmae(frcstCalc, pricesComb, frcstComb)
    dmae = ts_dmae(pricesComb, frcstComb);
    iadmae = 1./mean(dmae);
    w = (iadmae./sum(iadmae, 2))';
    frcst = frcstCalc*w;
end

function [ frcst ] = fc_iml210(frcstCalc, pricesComb, frcstComb, lossp)
    loss = loss210((pricesComb-frcstComb), lossp(1), lossp(2), lossp(3), lossp(4), lossp(5), lossp(6));
    imloss = 1./mean(loss);
    w = (imloss./sum(imloss, 2))';
    frcst = frcstCalc*w;
end

function [ frcst ] = fc_bi_ml210(frcstCalc, pricesComb, frcstComb, lossp)
    mloss = mean(loss210((pricesComb-frcstComb), lossp(1), lossp(2), lossp(3), lossp(4), lossp(5), lossp(6)));
	frcst = frcstCalc(:, mloss == min(mloss, [], 2));
end

function [ frcst ] = fc_bi_rmse(frcstCalc, pricesComb, frcstComb)
    rmse = sqrt(mean((frcstComb - pricesComb).^2));
	frcst = frcstCalc(:, rmse == min(rmse, [], 2));
end

function [ frcst ] = fc_bi_mse(frcstCalc, pricesComb, frcstComb)
    mse = mean((frcstComb - pricesComb).^2);
	frcst = frcstCalc(:, mse == min(mse, [], 2));
end

function [ frcst ] = fc_bi_mae(frcstCalc, pricesComb, frcstComb)
    mae = mean(abs(frcstComb - pricesComb));
	frcst = frcstCalc(:, mae == min(mae, [], 2));
end

function [ frcst ] = fc_bi_wmae(frcstCalc, pricesComb, frcstComb)
    [~, awmae] = ts_wmae(pricesComb, frcstComb);
    frcst = frcstCalc(:, awmae == min(awmae, [], 2));
end

function [ frcst ] = fc_bi_dmae(frcstCalc, pricesComb, frcstComb)
    [~, admae] = ts_dmae(pricesComb, frcstComb);
    frcst = frcstCalc(:, admae == min(admae, [], 2));
end

function [ frcst, idx, pvalue ] = fc_mcs_mpv(frcstCalc, pricesComb, frcstComb, lossType, nwin, alpha, rule, lossp)
    [idx, pvalue] = mcs_trim(pricesComb, frcstComb, lossType, nwin, alpha, rule, lossp);
	pvalue = pvalue(size(pvalue,1)-length(idx)+1:end);
    w = (pvalue./sum(pvalue));
    frcst = frcstCalc(:,idx)*w;
end

function [ idx, pvalue ] = mcs_trim(pricesComb, frcstComb, lossType, nwin, alpha, rule, lossp)
    nboot = 2000;
    e = frcstComb - pricesComb;
    
    switch lossType
        case 'L1'
            losses = abs(e);
        case 'L2'
            losses = e.^2;
        case 'L210'
            losses = loss210(e, lossp(1), lossp(2), lossp(3), lossp(4), lossp(5), lossp(6));
        otherwise
            error('The loss function is unknown');
    end
    
    switch rule
        case 'R'
            [idx, pvalue] = mcs(losses, alpha, nboot, nwin);
        case 'SQ'
            [~, ~, ~, idx, pvalue] = mcs(losses, alpha, nboot, nwin);
        otherwise
            error('The MCS rule is unknown');
    end
end