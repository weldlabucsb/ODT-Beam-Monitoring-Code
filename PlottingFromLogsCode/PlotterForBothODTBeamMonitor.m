%%%%%% Inputting Date Range %%%%%%%


start_year = 2020; %year
start_month = 3; %month
start_day = 11; %day
start_hour = 14; %24 hour format
start_minute = 30; %minute

end_year = 2020; %year
end_month = 3; %month
end_day = 11; %day
end_hour = 15; %24 hour format
end_minute = 15; %minute

start_year = 2020; %year
start_month = 3; %month
start_day = 11; %day
start_hour = 13; %24 hour format
start_minute = 25; %minute

end_year = 2020; %year
end_month = 3; %month
end_day = 11; %day
end_hour = 23; %24 hour format
end_minute = 0; %minute

start_time= datetime(start_year,start_month,start_day,start_hour,start_minute,0);
end_time = datetime(end_year,end_month,end_day,end_hour,end_minute,0);

% start_date = datetime(start_year,start_month,start_day);
% end_date = datetime(end_year,end_month,end_day);


%%%%%% Going Back Some Number of Hours From Now %%%%%%%
% end_time = datetime(2020,3,9,22,0,0);
% start_time= end_time - hours(10);
% 
% start_date = datetime(start_time.Year,start_time.Month,start_time.Day);
% end_date = datetime(end_time.Year,end_time.Month,end_time.Day);

camera = 'odt'; %'odt'  OR  'xodt'


logFolder = ['Z:\Strontium ODT Position Monitoring and Logs\',camera,'-log'];
[beamData,times] = loadLogData(start_time,end_time,logFolder);

firstLogTime = times(1);
lastLogTime = times(length(times));

%now to adjust the time range. Start point should be the start date plus
%the number of hours 
numDays = datenum(end_time)-datenum(start_time);
initial_t = start_time.Hour + start_time.Minute/60;
final_t = numDays*24 + end_time.Hour + end_time.Minute/60;
str = strcat(datestr(start_date),' to ',datestr(end_date));
xodtBeamFig = figure;
%     hFig.Visible='off';
% xodtBeamFig.MenuBar='None';
% xodtBeamFig.ToolBar='None';
xodtBeamFig.Name= [upper(camera),' Beam Coordinates and Widths from Log'];
xodtBeamFig.Resize='Off';
xodtBeamFig.Position(1)=1;
xodtBeamFig.Position(2)=70;
xodtBeamFig.Position(3)=1920;
xodtBeamFig.Position(4)=920;
xodtBeamFig.DoubleBuffer='Off';  
clf;
subplot(2,2,1);
plot(times,beamData(:,1),'ko-');
xlim([firstLogTime,lastLogTime]);
ylabel('X Centroid [Pixels]','fontsize',18);
xlabel('Time [Hour].','fontsize',18);
grid on
% annotation('textbox',[.6 .7 .3 .3],'String',str,'FitBoxToText','on');
subplot(2,2,2);
plot(times,beamData(:,2),'ro-');
xlim([firstLogTime,lastLogTime]);
ylabel('Y Centroid [Pixels]','fontsize',18);
xlabel('Time [Hour].','fontsize',18);
grid on

subplot(2,2,3);
plot(times,beamData(:,3),'bo-');
xlim([firstLogTime,lastLogTime]);
ylabel('Major Width [Pixels]','fontsize',18)
xlabel('Time [Hour]','fontsize',18);
grid on

subplot(2,2,4);
plot(times,beamData(:,4),'go-');
xlim([firstLogTime,lastLogTime]);
ylabel('Minor Width [Pixels]','fontsize',18)
xlabel('Time [Hour]','fontsize',18);
grid on
%middle section pressures vs oven pressures
% figure(3)
% scatter(pressures(:,2),pressures(:,1),50,'b','filled')
% xlabel('Oven Pressure, [Torr]','fontsize',18);
% ylabel('Middle Pressure, [Torr]','fontsize',18);




