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
end_day = 12; %day
end_hour = 19; %24 hour format
end_minute = 15; %minute

start_year = 2020; %year
start_month = 3; %month
start_day = 11; %day
start_hour = 16; %24 hour format
start_minute = 2; %minute

end_year = 2020; %year
end_month = 3; %month
end_day = 11; %day
end_hour = 16; %24 hour format
end_minute = 8; %minute

% 
% 
start_time= datetime(start_year,start_month,start_day,start_hour,start_minute,0);
end_time = datetime(end_year,end_month,end_day,end_hour,end_minute,0);


%%%%%% Going Back Some Number of Hours From Now %%%%%%%
% end_time = datetime(2020,3,9,22,0,0);
% start_time= end_time - hours(3);

end_time = datetime('now');
start_time= end_time - hours(8);
% % 
% % start_date = datetime(start_time.Year,start_time.Month,start_time.Day);
% % end_date = datetime(end_time.Year,end_time.Month,end_time.Day);

odtLogFolder = 'Z:\Strontium ODT Position Monitoring and Logs\odt-log';
[odtBeamData,odtTimes] = loadLogData(start_time,end_time,odtLogFolder);

xodtLogFolder = 'Z:\Strontium ODT Position Monitoring and Logs\xodt-log';
[xodtBeamData,xodtTimes] = loadLogData(start_time,end_time,xodtLogFolder);

%now to adjust the time range. Start point should be the start date plus
%the number of hours 

odtFirstLogTime = odtTimes(1);
odtLastLogTime = odtTimes(length(odtTimes));

xodtFirstLogTime = xodtTimes(1);
xodtLastLogTime = xodtTimes(length(xodtTimes));

beamTrajectoryFig = figure;
%     hFig.Visible='off';
% xodtBeamFig.MenuBar='None';
% xodtBeamFig.ToolBar='None';
beamTrajectoryFig.Name= 'Beam Position Tracking from Log';
beamTrajectoryFig.Resize='Off';
beamTrajectoryFig.Position(1)=1;
beamTrajectoryFig.Position(2)=70;
beamTrajectoryFig.Position(3)=1920;
beamTrajectoryFig.Position(4)=920;
beamTrajectoryFig.DoubleBuffer='Off';  
clf(beamTrajectoryFig);

cmap=jet;
scatterSize = 20;
odtAx=subplot(1,2,1);
hold(odtAx,'on');
plot(odtAx,odtBeamData(:,1),odtBeamData(:,2),'-','Color',[0.6,0.6,0.6])
scatter(odtAx,odtBeamData(:,1),odtBeamData(:,2),scatterSize,odtTimes,'filled');
daspect(odtAx,[1,1,1])
set(odtAx,'ydir','reverse')

colormap(odtAx,cmap)
odtbar = colorbar(odtAx);
ylabel(odtbar,'Time in Hours');

caxis(odtAx,[odtFirstLogTime,odtLastLogTime]);
title(odtAx,'ODT Beam Position vs Time','fontsize',18)
ylabel(odtAx,'Y Centroid [Pixels]','fontsize',18);
xlabel(odtAx,'X Centroid [Pixels]','fontsize',18);
grid on
% annotation('textbox',[.6 .7 .3 .3],'String',str,'FitBoxToText','on');
xodtAx=subplot(1,2,2);
hold(xodtAx,'on')
plot(xodtAx,xodtBeamData(:,1),xodtBeamData(:,2),'-','Color',[0.6,0.6,0.6])
scatter(xodtAx,xodtBeamData(:,1),xodtBeamData(:,2),scatterSize,xodtTimes,'filled');
daspect(xodtAx,[1,1,1])
set(xodtAx,'ydir','reverse')

colormap(xodtAx,cmap)
xodtbar=colorbar(xodtAx);
ylabel(xodtbar,'Time in Hours');
caxis(xodtAx,[xodtFirstLogTime,xodtLastLogTime]);
title(xodtAx,'XODT Beam Position vs Time','fontsize',18)
ylabel(xodtAx,'Y Centroid [Pixels]','fontsize',18);
xlabel(xodtAx,'X Centroid [Pixels]','fontsize',18);
grid on
