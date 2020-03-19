function [odtVid,odtSrc]=BothODTBeamMonitorTriggered()
%   2/09/2020

%Function for initializing the ODT (or XODT) Camera to monitor the ODT
%(XODT) position, so that an image of the ODT beams on the camera is taken
%when a hardware trigger is received by the camera. See also,
%ODTBeamMonitor in the case that you want the images to be taken without a
%hardware trigger (i.e. a continuous stream)
%   The function displays the image of the ODT (XODT) beam on the camera
%   and fits a 2D gaussian to it.  The center of the gaussian is
%   identified, and the resulting x and y coordinates are plotted.

%   Notes from the "initialize Camera" function on which this code is based:

%   Initializes the Blackfly PGE-12A2M-CS camera according to the
%   GigE Vision camera standards.
%   All non essential featuers have been disabled.  The PacketSize and
%   exposure time can be changed.
%
%   TROUBLESHOOTING
%   If the camera is not working properly.  Close MATLAB and run the camera
%   from the Fly Capture software.  Follow the instructions on the getting
%   started page to ensure that the PacketSize is set appropriately.
%
%   If the number of pictures per run is not specified (numPics), the
%   camera will run indefinitely.  It is recommended that the camera be
%   stopped when changing imaging folders or when the camera is not in use.
%
%   The recommended maximum operating temperature is 55C according to the
%   documentation, but I have observed temperatures up to 59C.  This can be
%   monitored via the DeviceTemperature propertiy of src.
%
%   GPIO 0 - The external trigger given by the user (input)
%   GPIO 1 - Exposure active signal (output)


%% Initial Definitions and Parameters
    
odtROI = [180 250 850 925];
odtROI = [175 275 820 960];
odtROI = [150 250 820 960]; % After color filter change
%         odtROI = [1 960 1 1280];  % FULL ROI of ODT Camera
%         ROI = [1 960/10 1 1280/10];
odtCameraNumber = 2;
%         cameraNumber = 1;
odtExposureTime = 10000;
odtCameraGain = 0.01;

xodtROI = [365 455 430 520];
xodtROI = [365 465 380 520];
xodtROI = [350 450 380 520];
%         ROI = [400 450 425 475];  
%         ROI = [1 608 1 808]; % FULL ROI of XODT Camera
xodtCameraNumber = 1;
xodtExposureTime = 1000;
xodtCameraGain = 0.01;

maxBitSignal=2^8;
maxSum=960/2*1280/2*2^8;


%%% MANUAL OPTIONS SETTINGS %%%
maxTime=120*60;  %SET THIS FOR LENGTH OF INDIVIDUAL SCANS
theCLim=[1 256];
yLimPD=[10^6 maxSum/2];
useROI=1;
textColor = 'w';

lastPreviewTime = 0;
     
%% Initialize Camera to accept triggers and get fluorescence count
disp('Initializing ODT Camera')
odtVid = videoinput('gige', odtCameraNumber, 'Mono8'); %default setting
%     vid = videoinput('gige', numCam, 'Mono12Packed'); %use 12-bit ADC, Packed?
odtSrc = getselectedsource(odtVid);

odtSrc.AcquisitionFrameRateAuto = 'Off';

% odtSrc.GainAuto = 'Off';
set(odtSrc,'GainAuto','Off')   
set(odtSrc,'ExposureAuto','Off')

%gigecamlist;

odtVid.FramesPerTrigger = 1;
odtVid.TriggerRepeat = Inf;

triggerconfig(odtVid, 'hardware', 'DeviceSpecific', 'DeviceSpecific'); %Sets the BlackFLY to receive hardware triggers (triggers from external TTL, i.e. from Cicero).
odtSrc.TriggerMode = 'On';
odtSrc.TriggerSource = 'Line0';    
%     src.LineMode = 'Trigger'% maybe? - Kurt;
odtSrc.TriggerActivation = 'RisingEdge';
%    src.TriggerActivation = 'FallingEdge';

%src.LineDebounceTime=10;
odtSrc.TriggerDelayEnabled = 'False';
odtSrc.BinningVertical=1;
odtSrc.BinningHorizontal=1;

odtVid.LoggingMode = 'memory';

odtSrc.ExposureTime=odtExposureTime; %Exposure time in us; for 300us actually goes to 300.765;
%src.ExposureTime=10000; %Exposure time in us; for 300us actually goes to 300.765;   
%src.ExposureTime=exposureTime;
odtSrc.Gain=odtCameraGain;
odtSrc.PacketSize = 9000;
odtSrc.GammaEnabled='False';

disp('ODT Camera Initialized')


disp('Initializing XODT Camera')
xodtVid = videoinput('gige', xodtCameraNumber, 'Mono8'); %default setting
%     vid = videoinput('gige', numCam, 'Mono12Packed'); %use 12-bit ADC, Packed?
xodtSrc = getselectedsource(xodtVid);

xodtSrc.AcquisitionFrameRateAuto = 'Off';

set(xodtSrc,'GainAuto','Off')   
set(xodtSrc,'ExposureAuto','Off')

%gigecamlist;

xodtVid.FramesPerTrigger = 1;
xodtVid.TriggerRepeat = Inf;

triggerconfig(xodtVid, 'hardware', 'DeviceSpecific', 'DeviceSpecific'); %Sets the BlackFLY to receive hardware triggers (triggers from external TTL, i.e. from Cicero).
xodtSrc.TriggerMode = 'On';
xodtSrc.TriggerSource = 'Line0';    
%     src.LineMode = 'Trigger'% maybe? - Kurt;
xodtSrc.TriggerActivation = 'RisingEdge';
%    src.TriggerActivation = 'FallingEdge';

%src.LineDebounceTime=10;
xodtSrc.TriggerDelayEnabled = 'False';
xodtSrc.BinningVertical=1;
xodtSrc.BinningHorizontal=1;

xodtVid.LoggingMode = 'memory';


xodtSrc.ExposureTime=xodtExposureTime; %Exposure time in us; for 300us actually goes to 300.765;
%src.ExposureTime=10000; %Exposure time in us; for 300us actually goes to 300.765;   
%src.ExposureTime=exposureTime;
xodtSrc.Gain=xodtCameraGain;
xodtSrc.PacketSize = 9000;
xodtSrc.GammaEnabled='False';

disp('XODT Camera Initialized')


startTime=now;

%%Set up Output Figure
hFig=figure;
%     hFig.Visible='off';
hFig.MenuBar='None';
hFig.ToolBar='None';
hFig.Name= ['ODT and XODT Beam Coordinates'];
hFig.Resize='Off';
hFig.CloseRequestFcn=@CloseRequestFcn;
hFig.Position(1)=1;
hFig.Position(2)=70;
hFig.Position(3)=1920;
hFig.Position(4)=980;
hFig.DoubleBuffer='Off';  


imagesLowerEdge = 0.5;
imagesHeight = 0.48;

odtImageLeftEdge = 0.05;
xodtImageLeftEdge = 0.55;

imagesWidth = 0.42;

xPlotsLowerEdge = 0.28;
xPlotsHeight = 0.18;

yPlotsLowerEdge = 0.05;
yPlotsHeight = 0.18;

odtPosLeftEdge = 0.05;
xodtPosLeftEdge = 0.55;

plotsWidth = 0.42;


odtXPosAxes = axes(hFig,'Position',[odtPosLeftEdge xPlotsLowerEdge plotsWidth xPlotsHeight]);
odtYPosAxes = axes(hFig,'Position', [odtPosLeftEdge yPlotsLowerEdge plotsWidth yPlotsHeight]);

xodtXPosAxes = axes(hFig,'Position',[xodtPosLeftEdge xPlotsLowerEdge plotsWidth xPlotsHeight]);
xodtYPosAxes = axes(hFig,'Position', [xodtPosLeftEdge yPlotsLowerEdge plotsWidth yPlotsHeight]);

odtImageAxes = axes(hFig,'Position',[odtImageLeftEdge imagesLowerEdge imagesWidth  imagesHeight ]);
xodtImageAxes = axes(hFig,'Position',[xodtImageLeftEdge imagesLowerEdge imagesWidth  imagesHeight ]);



StopFcn=@(videoInput, callbackdata) disp([datestr(now) ' Video stopped.']);

odtVid.TriggerFcn=@ODTTriggerFcn;
odtVid.StartFcn=@ODTStartFcn;
odtVid.StopFcn=StopFcn;

xodtVid.TriggerFcn=@XODTTriggerFcn;
xodtVid.StartFcn=@XODTStartFcn;
xodtVid.StopFcn=StopFcn;





start(odtVid);
start(xodtVid);

function CloseRequestFcn(handle, callbackdata)
   disp('Closing feed...');
   if isvalid(odtVid)
       stop(odtVid); 
   end            
   delete(odtVid);
   if isvalid(xodtVid)
       stop(xodtVid); 
   end            
   delete(xodtVid);
   delete(gcf);
end  

function ODTStartFcn(vidInputHandle, callbackdata)

    

    xlim([0 maxTime]);    
   % ylim([8.4e6 1.0e7]);
    hold on     


   % Initialize ODT Axes for Center Position Plotting
    odtXPosAxes.FontSize=11;
    ylabel(odtXPosAxes,{'ODT Beam', 'X Position (pixel)'});
    %     xlabel(hXPosAxes,'Time');
    xlim([0 maxTime]);    %Photodiod x axis limits
    % ylim([0 20e6]);  %Photodiode y axis limist
    hold(odtXPosAxes ,'on')  
    grid(odtXPosAxes, 'on')

    odtYPosAxes.FontSize=11;
    ylabel(odtYPosAxes,{'ODT Beam', 'Y Position (pixel)'});
    xlabel(odtYPosAxes,'Time (s)');
    xlim([0 maxTime]);    %Photodiod x axis limits
    % ylim([0 20e6]); % Photodiode y axis limist
    hold(odtYPosAxes ,'on')  
    grid(odtYPosAxes, 'on')

   
    % Set up Axes for Camera Image Plot

    ROI = odtROI;

    set(odtImageAxes, 'XLimMode','manual',...
         'YLimMode','manual',...
         'ZLimMode','manual',...
         'XLimMode','manual',...
         'ALimMode','manual');

    odtImageAxes.YLim=[ROI(1),ROI(2)];
    odtImageAxes.XLim=[ROI(3),ROI(4)];
    
    
    %Blank initial image
    sampleFrame=rand(ROI(2)-ROI(1),ROI(4)-ROI(3));%imread('blackfly_2015_08_04_18_29_11.4205.tiff');
    %      hold on; 
    imagesc(odtImageAxes,ROI(3:4),ROI(1:2),sampleFrame);
    set(odtImageAxes,'ydir','reverse')
%          hImageAxes.CLim=theCLim;
    ylabel(odtImageAxes,'Y Pixel');
    xlabel(odtImageAxes,'X Pixel');
    title(odtImageAxes, 'Live Preview');
    colormap(odtImageAxes, hot)
    colorbar(odtImageAxes)

    % Calculations for and setting of  Image Axes Aspect Ratio in Pixels such that the
     % pixels appear square in the plotted image (image not stretched or
     % squeezed
    
    relXPos = odtImageLeftEdge;
    relYPos = imagesLowerEdge;
    relHeight = imagesHeight;
    relWidth = imagesWidth;

    trueWidth = hFig.Position(3)*relWidth;
    trueHeight = hFig.Position(4)*relHeight;

    odtImageAxes.Position=[relXPos    relYPos    relWidth    relHeight];
    naturalAspectRatio = trueWidth/trueHeight;
    ROIRatio = (ROI(4)-ROI(3))/(ROI(2)-ROI(1));

    if ROIRatio > naturalAspectRatio
        height = relHeight*(trueWidth/trueHeight)*(1/ROIRatio);
        yPos = relYPos + (relHeight-height)/2;
        odtImageAxes.Position=[relXPos    yPos    relWidth    height];
    else
        width = relWidth*(trueHeight/trueWidth)*ROIRatio;
        xPos = relXPos + (relWidth-width)/2;
        odtImageAxes.Position=[xPos    relYPos    width    relHeight];
    end 

    set(odtImageAxes,'Units','Point')
    imageWidth=odtImageAxes.Position(3);
    imageHeight=odtImageAxes.Position(4);
%     dataText = text(odtImageAxes,imageWidth-151,imageHeight-46,...
    dataText = text(odtImageAxes,imageWidth-135,imageHeight-46,...
        {['X Centroid: ','None'],...
        ['Y Centroid: ','None'],...
        ['Major Width: ','None'],...
        ['Minor Width: ','None']},...
        'Units','Point','Color',textColor,'FontSize',14,'FontWeight','bold');
        
        

    %% Store relevant data in the "vidInputHandle.UserData" so that it can be accessed from a trigger call.    
    vidInputHandle.UserData = struct('iter',1, 'times',zeros(100000,1), 'xCenterPositionVec',zeros(100000,1),'hxplot',plot(odtXPosAxes,[0],[0],'-ob'), ...
       'yCenterPositionVec',zeros(100000,1),'hyplot',plot(odtYPosAxes,[0],[0],'-ob'),'dataText',dataText);

    disp([datestr(now) ' Starting video... Waiting for ' num2str(odtVid.TriggerRepeat+1) ' hardware triggers.'])

    
end


function XODTStartFcn(vidInputHandle, callbackdata)
    
    xlim([0 maxTime]);    
   % ylim([8.4e6 1.0e7]);
    hold on     


    
   % Initialize XODT Axes for Center Position Plotting
    xodtXPosAxes.FontSize=11;
    ylabel(xodtXPosAxes,{'XODT Beam'; 'X Position (pixel)'});
    %     xlabel(hXPosAxes,'Time');
    xlim([0 maxTime]);    %Photodiod x axis limits
    % ylim([0 20e6]);  %Photodiode y axis limist
    hold(xodtXPosAxes, 'on')  
    grid(xodtXPosAxes, 'on')

    xodtYPosAxes.FontSize=11;
    ylabel(xodtYPosAxes,{'XODT Beam', 'Y Position (pixel)'});
    xlabel(xodtYPosAxes,'Time (s)');
    xlim([0 maxTime]);    %Photodiod x axis limits
    % ylim([0 20e6]); % Photodiode y axis limist
    hold(xodtYPosAxes, 'on')  
    grid(xodtYPosAxes, 'on')
    

   % Set up Axes for Camera Image Plot

    ROI = xodtROI;
    
    ylabel(xodtImageAxes,'Y Pixel');
    xlabel(xodtImageAxes,'X Pixel');
    title(xodtImageAxes, 'Live Preview');

    set(xodtImageAxes, 'XLimMode','manual',...
         'YLimMode','manual',...
         'ZLimMode','manual',...
         'XLimMode','manual',...
         'ALimMode','manual');


     xodtImageAxes.YLim=[ROI(1),ROI(2)];
     xodtImageAxes.XLim=[ROI(3),ROI(4)];

     %Blank initial image
     sampleFrame=rand(ROI(2)-ROI(1),ROI(4)-ROI(3));%imread('blackfly_2015_08_04_18_29_11.4205.tiff');
%      hold on;  

     imagesc(xodtImageAxes,ROI(3:4),ROI(1:2),sampleFrame);
     set(xodtImageAxes,'ydir','reverse')
%      imagesc(xodtImageAxes,ROI(3:4),ROI(1:2),sampleFrame);
%          hImageAxes.CLim=theCLim;
     colormap(xodtImageAxes, hot)
     colorbar(xodtImageAxes)

    % Calculations for and setting of  Image Axes Aspect Ratio in Pixels such that the
     % pixels appear square in the plotted image (image not stretched or
     % squeezed
    
     relXPos = xodtImageLeftEdge;
     relYPos = imagesLowerEdge;
     relHeight = imagesHeight;
     relWidth = imagesWidth;

     trueWidth = hFig.Position(3)*relWidth;
     trueHeight = hFig.Position(4)*relHeight;

     xodtImageAxes.Position=[relXPos    relYPos    relWidth    relHeight];
     naturalAspectRatio = trueWidth/trueHeight;
     ROIRatio = (ROI(4)-ROI(3))/(ROI(2)-ROI(1));

     if ROIRatio > naturalAspectRatio
         height = relHeight*(trueWidth/trueHeight)*(1/ROIRatio);
         yPos = relYPos + (relHeight-height)/2;
         xodtImageAxes.Position=[relXPos    yPos    relWidth    height];
     else
         width = relWidth*(trueHeight/trueWidth)*ROIRatio;
         xPos = relXPos + (relWidth-width)/2;
         xodtImageAxes.Position=[xPos    relYPos    width    relHeight];
     end 
     

     
    set(xodtImageAxes,'Units','Point')
    imageWidth=xodtImageAxes.Position(3);
    imageHeight=xodtImageAxes.Position(4);

    dataText = text(xodtImageAxes,imageWidth-135,imageHeight-46,...
        {['X Centroid: ','None'],...
        ['Y Centroid: ','None'],...
        ['Major Width: ','None'],...
        ['Minor Width: ','None']},...
        'Units','Point','Color',textColor,'FontSize',14,'FontWeight','bold');
     
     
         %% Store relevant data in the "vidInputHandle.UserData" so that it can be accessed from a trigger call.    
    vidInputHandle.UserData = struct('iter',1, 'times',zeros(100000,1), 'xCenterPositionVec',zeros(100000,1),'hxplot',plot(xodtXPosAxes,[0],[0],'-ob'), ...
       'yCenterPositionVec',zeros(100000,1),'hyplot',plot(xodtYPosAxes,[0],[0],'-ob'),'dataText',dataText);

    disp([datestr(now) ' Starting video... Waiting for ' num2str(odtVid.TriggerRepeat+1) ' hardware triggers.'])
    
end


function ODTTriggerFcn(vidInputHandle, callbackdata)
    
    %Abbreviate vidInputHandle.UserData as ud
    ud = vidInputHandle.UserData;

    ROI = odtROI;
%         %Indicate Trigger Retreival
%         disp([datestr(now) ' Trigger ' num2str(ud.iter) ' received.'])
    %Getting Image Taken on Trigger
    img=getdata(odtVid);
    %Set ROI if given
    if useROI
        img = img(ROI(1):ROI(2),ROI(3):ROI(4));
    end

    %Get time at which the image was taken and determine time of image
    %relative to start time in seconds.  Store in vector of ud.times with previous trigger times.
    t=callbackdata.Data;
    t=t.AbsTime;
    pictime=datetime(t(1),t(2),t(3),t(4),t(5),t(6));
    pictimenum=datenum(pictime);
    ud.times(ud.iter) = (pictimenum-startTime)*24*60*60;

     %Calculating Center of Mass as an initial guess of the beam
    %center
    [cmx,cmy] = centerOfMass(ROI,img);
    cm = [cmx,cmy];

    % Calculate Gaussian fit of the beam spot on the camera:
    % (xo,yo) is the coordinate of the fitted gaussian center
    % wx and wy are the standard devaiations of the major and minor
    % standard deviations of the gaussian fit.
    % fi is the angle of rotation of the gaussian fit relative to
    % the case where x and y are the standard deviations along
    % major and minor axes.
    [Amp,xo,wx,yo,wy,fi,Offset]=fit2DGauss(ROI,img,cm);
    ud.xCenterPositionVec(ud.iter)=xo;
    ud.yCenterPositionVec(ud.iter)=yo;
    cla(odtXPosAxes);  % Clearing axes to prevent from wasting memory
    delete(findall(gcf,'type','annotation')) %Delete the display of current value
    cla(odtYPosAxes); 
    delete(findall(gcf,'type','annotation')) %Delete the display of current value
    ud.hxplot = plot(odtXPosAxes,ud.times(1:ud.iter),ud.xCenterPositionVec(1:ud.iter),'-r');  %Plotting X centers
    ud.hyplot = plot(odtYPosAxes,ud.times(1:ud.iter),ud.yCenterPositionVec(1:ud.iter),'-r');  %Plotting Y centers
    set(ud.hxplot,'LineWidth',4)
    set(ud.hyplot,'LineWidth',4)
    
    % Plot Position Data
    
    if wx>wy
        wMaj=wx;
        wMin=wy;
    else
        wMaj=wy;
        wMin=wx;
    end
    
    updateValues('odt',pictime,xo,yo,wMaj,wMin)
    
    
    % Determine whether to put text in the upper right or the lower left
    % corner
    set(odtImageAxes,'Units','Point')
    imageWidth=odtImageAxes.Position(3);
    imageHeight=odtImageAxes.Position(4);
    if (xo>(ROI(4)+ROI(3))/2)&&(yo<(ROI(2)+ROI(1))/2)
        xTextPos = 10;
        yTextPos = 45;
    else
        xTextPos = imageWidth-135;
        yTextPos = imageHeight-46;
    end
    

%     annotation('textbox',[0.27 0 0.3 0.3], 'String', num2str(ud.yCenterPositionVec(ud.iter),3), 'FitBoxToText','on','FontSize',32); %Display currently plotted value on graph as an annotation
%     annotation('textbox',[0.27 0.5 0.3 0.3], 'String', num2str(ud.xCenterPositionVec(ud.iter),3), 'FitBoxToText','on','FontSize',32);
    if (ud.times(ud.iter)-startTime)*24*60*60>maxTime

%         %Getting the data from the plot
%         do=get(odtXPosAxes,'Children');
%         times=get(do,'XData');
%         xcenter=get(do,'YData');
% 
%         do = get(odtYPosAxes,'Children');
%         ycenter = get(do,'YData');
% 
% 
%         %Saving the plotted data to files
%         save([datestr(now,'yyyy_mm_dd_HH_MM_SS') '_beamCenterVsTime.mat'],'times','xcenter','ycenter');  
%         save([datestr(now,'yyyy_mm_dd_HH_MM_SS') '_lastImageOfRun.mat'],'img')
%         savefig([datestr(now,'yyyy_mm_dd_HH_MM_SS') '_TraceAndFinalImage'])
%         imwrite(img,[datestr(now,'yyyy_mm_dd_HH_MM_SS') '_FinalImage.tiff'],'tiff');

       cla(odtXPosAxes); 
       cla(odtYPosAxes); 

       ud.iter=1;
       ud.times=zeros(100000,1);
       ud.numCountsVec = zeros(100000,1);

       %Resetting the start time of the position plot
       startTime=ud.times(ud.idter);
       %Resetting the last time a preview image was plotted to 0 
    else
        %Plotting Camera Image as a 2D plot
        cla(odtImageAxes)
        imagesc(odtImageAxes,ROI(3:4),ROI(1:2),img);
        colormap(odtImageAxes, hot)
        colorbar(odtImageAxes)
        caxis(odtImageAxes,[Offset,(Offset+Amp)])
        hold(odtImageAxes,'on')
%                         hImage.CData=img;     
        plot(odtImageAxes,[xo],[yo],'.b','markersize',32);
        plot(odtImageAxes,[cmx],[cmy],'.r','markersize',32);
        m = -tan(fi);% Point slope formula
        b = (-m*xo + yo);
        xvh = ROI(3):ROI(4);
        yvh = xvh*m + b;
        % generate points along vertical axis
        mrot = -m;
        brot = (mrot*yo - xo);
        yvv = ROI(1):ROI(2);
        xvv = yvv*mrot - brot;
% 
%         % Indicate major and minor axis on plot
% 
        % plot lins 
        plot(odtImageAxes,[xvh(1) xvh(size(xvh))],[yvh(1) yvh(size(yvh))],'r'); 
        plot(odtImageAxes,[xvv(1) xvv(size(xvv))],[yvv(1) yvv(size(yvv))],'g');
        tel=-pi:0.1:pi+0.2;
        xel=wx*cos(tel);
        yel=wy*sin(tel);
        xelrot = xel.*cos(-fi)-yel.*sin(-fi);
        yelrot = xel.*sin(-fi)+yel.*cos(-fi);
        xelrot = xelrot+xo;
        yelrot = yelrot+yo;
        plot(odtImageAxes,xelrot,yelrot,'linewidth',4);

        ud.dataText = text(odtImageAxes,xTextPos,yTextPos,...
            {['X Centroid: ',num2str(xo,4)],...
            ['Y Centroid: ',num2str(yo,4)],...
            ['Major Width: ',num2str(wMaj,4)],...
            ['Minor Width: ',num2str(wMin,4)]},...
            'Units','Point','Color',textColor,'FontSize',14,'FontWeight','bold');
        %Setting the most recent time a camera image was
        %plotted
        drawnow;
        ud.iter = ud.iter+1;
    end


    vidInputHandle.UserData=ud;
end       

function XODTTriggerFcn(vidInputHandle, callbackdata)
    
    %Abbreviate vidInputHandle.UserData as ud
    ud = vidInputHandle.UserData;
    
    
    ROI = xodtROI;
%         %Indicate Trigger Retreival
%         disp([datestr(now) ' Trigger ' num2str(ud.iter) ' received.'])
    %Getting Image Taken on Trigger
    img=getdata(xodtVid);
    %Set ROI if given
    if useROI
        img = img(ROI(1):ROI(2),ROI(3):ROI(4));
    end

    %Get time at which the image was taken and determine time of image
    %relative to start time in seconds.  Store in vector of ud.times with previous trigger times.
    t=callbackdata.Data;
    t=t.AbsTime;
    pictime=datetime(t(1),t(2),t(3),t(4),t(5),t(6));
    pictimenum=datenum(pictime);
    ud.times(ud.iter) = (pictimenum-startTime)*24*60*60;

     %Calculating Center of Mass as an initial guess of the beam
    %center
    [cmx,cmy] = centerOfMass(ROI,img);
    cm = [cmx,cmy];

    % Calculate Gaussian fit of the beam spot on the camera:
    % (xo,yo) is the coordinate of the fitted gaussian center
    % wx and wy are the standard devaiations of the major and minor
    % standard deviations of the gaussian fit.
    % fi is the angle of rotation of the gaussian fit relative to
    % the case where x and y are the standard deviations along
    % major and minor axes.
    [~,xo,wx,yo,wy,fi,~]=fit2DGauss(ROI,img,cm);
    ud.xCenterPositionVec(ud.iter)=xo;
    ud.yCenterPositionVec(ud.iter)=yo;
    cla(xodtXPosAxes);  % Clearing axes to prevent from wasting memory
    delete(findall(gcf,'type','annotation')) %Delete the display of current value
    cla(xodtYPosAxes); 
    delete(findall(gcf,'type','annotation')) %Delete the display of current value
    ud.hxplot = plot(xodtXPosAxes,ud.times(1:ud.iter),ud.xCenterPositionVec(1:ud.iter),'-r');  %Plotting X centers
    ud.hyplot = plot(xodtYPosAxes,ud.times(1:ud.iter),ud.yCenterPositionVec(1:ud.iter),'-r');  %Plotting Y centers
    set(ud.hxplot,'LineWidth',4)
    set(ud.hyplot,'LineWidth',4)
    % Plot Position Data
    
    if wx>wy
        wMaj=wx;
        wMin=wy;
    else
        wMaj=wy;
        wMin=wx;
    end
    
    updateValues('xodt',pictime,xo,yo,wMaj,wMin)
    
    set(xodtImageAxes,'Units','Point')
    if (xo>(ROI(4)+ROI(3))/2)&&(yo<(ROI(2)+ROI(1))/2)
        xTextPos = 10;
        yTextPos = 45;
    else
        imageWidth=xodtImageAxes.Position(3);
        imageHeight=xodtImageAxes.Position(4);
        xTextPos = imageWidth - 135;
        yTextPos = imageHeight - 46;
    end
    % Set text location
%     annotation('textbox',[0.27 0 0.3 0.3], 'String', num2str(ud.yCenterPositionVec(ud.iter),3), 'FitBoxToText','on','FontSize',32); %Display currently plotted value on graph as an annotation
%     annotation('textbox',[0.27 0.5 0.3 0.3], 'String', num2str(ud.xCenterPositionVec(ud.iter),3), 'FitBoxToText','on','FontSize',32);
    if (ud.times(ud.iter)-startTime)*24*60*60>maxTime

%         Getting the data from the plot
%         do=get(xodtXPosAxes,'Children');
%         times=get(do,'XData');
%         xcenter=get(do,'YData');
% 
%         do = get(xodtYPosAxes,'Children');
%         ycenter = get(do,'YData');
% 
% 
%         %Saving the plotted data to files
%         save([datestr(now,'yyyy_mm_dd_HH_MM_SS') '_beamCenterVsTime.mat'],'times','xcenter','ycenter');  
%         save([datestr(now,'yyyy_mm_dd_HH_MM_SS') '_lastImageOfRun.mat'],'img')
%         savefig([datestr(now,'yyyy_mm_dd_HH_MM_SS') '_TraceAndFinalImage'])
%         imwrite(img,[datestr(now,'yyyy_mm_dd_HH_MM_SS') '_FinalImage.tiff'],'tiff');

       cla(xodtXPosAxes); 
       cla(xodtYPosAxes); 

       ud.iter=1;
       ud.times=zeros(100000,1);
       ud.numCountsVec = zeros(100000,1);

       %Resetting the start time of the position plot
       startTime=ud.times(ud.idter);
       %Resetting the last time a preview image was plotted to 0 
       vidInputHandle.UserData=ud;
    else
        %Plotting Camera Image as a 2D plot
        cla(xodtImageAxes)
        imagesc(xodtImageAxes,ROI(3:4),ROI(1:2),img);
        hold(xodtImageAxes,'on')
%                         hImage.CData=img;     
        plot(xodtImageAxes,[xo],[yo],'.b','markersize',32);
        plot(xodtImageAxes,[cmx],[cmy],'.r','markersize',32);
        m = -tan(fi);% Point slope formula
        b = (-m*xo + yo);
        xvh = ROI(3):ROI(4);
        yvh = xvh*m + b;
        % generate points along vertical axis
        mrot = -m;
        brot = (mrot*yo - xo);
        yvv = ROI(1):ROI(2);
        xvv = yvv*mrot - brot;

        % Indicate major and minor axis on plot

        % plot lins 
        plot(xodtImageAxes,[xvh(1) xvh(size(xvh))],[yvh(1) yvh(size(yvh))],'r'); 
        plot(xodtImageAxes,[xvv(1) xvv(size(xvv))],[yvv(1) yvv(size(yvv))],'g');
        tel=-pi:0.1:pi+0.2;
        xel=wx*cos(tel);
        yel=wy*sin(tel);
        xelrot = xel.*cos(-fi)-yel.*sin(-fi);
        yelrot = xel.*sin(-fi)+yel.*cos(-fi);
        xelrot = xelrot+xo;
        yelrot = yelrot+yo;
        plot(xodtImageAxes,xelrot,yelrot,'linewidth',4);
        %Setting the most recent time a camera image was
        %plotted
        

        ud.dataText = text(xodtImageAxes,xTextPos,yTextPos,...
            {['X Centroid: ',num2str(xo,4)],...
            ['Y Centroid: ',num2str(yo,4)],...
            ['Major Width: ',num2str(wMaj,4)],...
            ['Minor Width: ',num2str(wMin,4)],...
            ['TERMINATE']},...
            'Units','Point','Color',textColor,'FontSize',14,'FontWeight','bold');
        
        drawnow;
        ud.iter = ud.iter+1;
        vidInputHandle.UserData=ud;  %Passing user data to the next iteration of the Timer object
    end
    % Set text location
%     dataText.String = {['X Centroid: ', num2str(xo,4)],...
%         ['Y Centroid: ', num2str(yo,4)],...
%         ['Major Width: ',num2str(wMaj,3)],...
%         ['Minor Width: ',num2str(wMin,3)]};
    
   
    vidInputHandle.UserData=ud;
    
    
    
    
end       

end



function [x,y] = centerOfMass(ROI,img)
    % Calculates center of mass (X,Y) coordinate of image
    [X,Y] = meshgrid((ROI(3):ROI(4)),(ROI(1):ROI(2)));
    X = double(X);
    Y = double(Y);
    img = double(img);
    sume = sum(sum(img));
    x = (sum(sum(X.*img)))./(sume);
    y = (sum(sum(Y.*img)))./(sume);
end

function [Amp,xo,wx,yo,wy,fi,offset] = fit2DGauss(ROI,img,cm)
    % Fits the image data to a gaussing using lsqcurvefit (square error
    % minimization by iterative algorithm.
    guess=double([max(max(img)),mean([ROI(3) ROI(4)]),abs((ROI(3)-ROI(4))./2)...
        ,mean([ROI(1) ROI(2)]),abs((ROI(1)-ROI(2))./2),0]);
    guess = [124  cm(1)   17  cm(2)   27    0.2854,20];
    lb = double([0,0,0,0,0,-pi./4,0]); %
    ub = double([guess(1).*2,max([ROI(3) ROI(4)]),guess(3).*2,max([ROI(1) ROI(2)]),guess(5).*2,pi./4,100]);
    [X,Y] = meshgrid((ROI(3):ROI(4)),(ROI(1):ROI(2)));
    xdata = zeros(size(X,1),size(Y,2),2);
    xdata(:,:,1) = X;
    xdata(:,:,2) = Y;
    xdata = double(xdata);
    Z = double(img);
    options = optimoptions('lsqcurvefit','FunctionTolerance',1e-3,'Display','off');
    [x,~,~,~] = lsqcurvefit(@D2GaussFunctionRot,guess,xdata,Z,lb,ub,options);
    Amp = x(1);
    xo = x(2);
    wx = x(3);
    yo = x(4);
    wy = x(5);
    fi = x(6);
    offset = x(7);
end

function F = D2GaussFunctionRot(x,xdata)
    % Gaussian functional form.
    %% x = [Amp, x0, wx, y0, wy, fi, offset]
    %%
    xdatarot(:,:,1)= xdata(:,:,1)*cos(x(6)) - xdata(:,:,2)*sin(x(6));
    xdatarot(:,:,2)= xdata(:,:,1)*sin(x(6)) + xdata(:,:,2)*cos(x(6));
    x0rot = x(2)*cos(x(6)) - x(4)*sin(x(6));
    y0rot = x(2)*sin(x(6)) + x(4)*cos(x(6));

%     F = x(1)*exp(   -((xdatarot(:,:,1)-x0rot).^2/(2*x(3)^2) + (xdatarot(:,:,2)-y0rot).^2/(2*x(5)^2) )    );
    F = x(1)*exp(   -((xdatarot(:,:,1)-x0rot).^2/(2*x(3)^2) + (xdatarot(:,:,2)-y0rot).^2/(2*x(5)^2) )    )+x(7);
end


function updateValues(camera,pictime,xo,yo,wMaj,wMin)

    % OPTION: label each pressure
    pictimenum=datenum(pictime);
    
    to_write = [num2str(xo) ',' num2str(yo) ',' num2str(wMaj) ',' num2str(wMin) ',' num2str(24*mod(pictimenum,1)) ...
        ',' num2str(pictime.Hour) ',' num2str(pictime.Minute) ',' num2str(pictime.Second) newline];
    outerfoldername = strcat('Z:\Strontium ODT Position Monitoring and Logs\',camera,'-log');
    if ~exist(outerfoldername, 'dir')
       mkdir(outerfoldername)
    end
    innerfoldername = strcat('Z:\Strontium ODT Position Monitoring and Logs\',camera,'-log','\',datestr(pictime,'yyyy-mmm'));
    if ~exist(innerfoldername, 'dir')
       mkdir(innerfoldername)
    end
    filename = strcat(innerfoldername,'\',datestr(pictime,'yyyy-mmm-dd'),'.csv');    
    if ~exist(filename, 'file')
       [fileID,errorMsg] = fopen(filename,'a+');
        assert(fileID>0,['Failed to Access File: ',filename,'.  Reason: ',errorMsg])
        fprintf(fileID,['X Centroic' ',' 'Y Centroid' ',' 'Major Width' ',' 'Minor Width' ',' 'Time in fraction of day'...
            ',' 'Hour' ',' 'Minute' ',' 'Second' newline]);
        fprintf(fileID,to_write);
    else
        [fileID,errorMsg] = fopen(filename,'a+');
        assert(fileID>0,['Failed to Access File: ',filename,'.  Reason: ',errorMsg])
        fprintf(fileID,to_write);
        
    end
    fclose(fileID);
end