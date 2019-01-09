function [ frcst ] = epf_naive( prices, datetimes, H )
%EPF_NAIVE Summary of this function goes here
%   Detailed explanation goes here
    
    if(nargin < 3)
        H = 24;
    end
    
    dayFrcst = weekday(datetimes(end)+1);

    if(ismember(dayFrcst, [2,7,1]))
        % for Monday, Saturdays and Sundays - use the same day of previous week
        frcst = prices(end-6*H-(H-1):end-6*H);
    else
        % for Tuesday, Wednesdays, Thursdays and Fridays - use previous day
        frcst = prices(end-(H-1):end);
        
        % for Tuesday, Wednesdays, Thursdays and Fridays - use Monday
        %delta = dayFrcst-2;
        %frcst = prices(end-delta*H+1:end-(delta-1)*H);
    end
    
end