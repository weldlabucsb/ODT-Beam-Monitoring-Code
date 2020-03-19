function [beamData,times] = loadLogData(start_date_time,end_date_time,logFolder)
%loadLogData - Loads the beamData as an Nx4 matrix and the corresponding
%times as an Nx1 vector  
%   The logFolder should be of the form 'Z:\Strontium ODT Position
%   Monitoring and Logs\CAMERANAME-log' where CAMERANAME is either 'odt' or
%   'xodt
%   beam data rows have the format [xo,yo,wMaj,wMin] where (xo,yo) is the
%   centroid position coordinates and wMaj, wMin or the major and minor
%   beam waists
%   start_date and end_date should be matlab datetime objects
%   corresponding to the range of dates to load

start_date = datetime(start_date_time.Year,start_date_time.Month,start_date_time.Day);
end_date = datetime(end_date_time.Year,end_date_time.Month,end_date_time.Day);

beamData = [];
times = [];

currdate = start_date;
previousHours = 0;

while currdate <= end_date
    filename = strcat(logFolder,'\',datestr(currdate,'yyyy-mmm'),'\',datestr(currdate,'yyyy-mmm-dd'),'.csv');
    disp(['Loading: ',datestr(currdate,'yyyy-mmm-dd')])
%     filename = strcat(datestr(currdate,'yyyy-mmmm-dd'),'.csv');
%     these_pressures = readmatrix(filename,'Range','A:C'); ONLY FOR 2019A
%     OR LATER
    try
        file_data = csvread(filename,1,0);
        these_beam_data = file_data(:,1:4);
        these_times = file_data(:,5);
        if currdate==start_date
            these_times_plus_hours = file_data(:,5)+previousHours;
            
            % Format start times as hours and fractions
            startTimeNum=datenum(start_date_time);
            startTimeHour=24*mod(startTimeNum,1);
            
            startIndex = find(these_times>(startTimeHour-(1e-3)),1);
            endIndex = length(these_times);
            if currdate==end_date
                endTimeNum=datenum(end_date_time);
                endTimeHour=24*mod(endTimeNum,1);
                endIndex = find(these_times<(endTimeHour+(1e-3)),1,'last');
            end
            
            added_times = these_times(startIndex:endIndex);
            added_Beam_Data = these_beam_data(startIndex:endIndex,:);
            
            times = [times;added_times];
            beamData = [beamData;added_Beam_Data];
            
        elseif currdate==end_date
            these_times_plus_hours = file_data(:,5)+previousHours;
            
            % Format start times as hours and fractions
            endTimeNum=datenum(end_date_time);
            endTimeHour=24*mod(endTimeNum,1);
            
            
            startIndex = 1;
            endIndex = find(these_times<(endTimeHour+(1e-3)),1,'last');
            
            added_times = these_times_plus_hours(startIndex:endIndex);
            added_Beam_Data = these_beam_data(startIndex:endIndex,:);
            
            times = [times;added_times];
            beamData = [beamData;added_Beam_Data];
        else
            added_times = these_times+previousHours;
            
            beamData = [beamData;these_beam_data];
            times = [times;added_times];
        end
        clear file_data; %get rid of the huge data file
    catch
        message = strcat('No data found for',datestr(currdate));
        warning(message);
    end
    previousHours = previousHours+24;
    currdate = currdate+1;
end
if isempty(times)
    error('No data found in given time range')
end

end

