function [vid,src]=ODTBeamMonitorTriggered( ROIName )
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
if (nargin < 1)
    ROIName = 'xodt';
end
    
lowerROIName = lower(ROIName);

switch lowerROIName
    case {'odt','odtbeam'}
        ROI = [180 250 850 925];
%         ROI = [1 960 1 1280];  % FULL ROI of ODT Camera
%         ROI = [1 960/10 1 1280/10];
        cameraNumber = 2;
%         cameraNumber = 1;
        exposureTime = 100;
        cameraGain = 0.01;
    case {'xodt','xodtbeam'}
        ROI = [300 500 300 600];
%         ROI = [400 450 425 475];  
%         ROI = [1 608 1 808]; % FULL ROI of XODT Camera
        cameraNumber = 1;
        exposureTime = 50;
        cameraGain = 0.01;
    otherwise
        error('Input ROIName was given as %s and the associated ROI could not be set',ROIName)
end
maxBitSignal=2^8;
maxSum=960/2*1280/2*2^8;


%%% MANUAL OPTIONS SETTINGS %%%
maxTime=120*60;  %SET THIS FOR LENGTH OF INDIVIDUAL SCANS
theCLim=[1 256];
yLimPD=[10^6 maxSum/2];
useROI=1;

previewPeriod = 0.2;
lastPreviewTime = 0;
     
%% Initialize Camera to accept triggers and get fluorescence count

    vid = videoinput('gige', cameraNumber, 'Mono8'); %default setting
%     vid = videoinput('gige', numCam, 'Mono12Packed'); %use 12-bit ADC, Packed?
    src = getselectedsource(vid);
    
    src.AcquisitionFrameRateAuto = 'Off';

    src.GainAuto = 'Off';

    %gigecamlist;
    
    vid.FramesPerTrigger = 1;
    vid.TriggerRepeat = Inf;
    
    triggerconfig(vid, 'hardware', 'DeviceSpecific', 'DeviceSpecific'); %Sets the BlackFLY to receive hardware triggers (triggers from external TTL, i.e. from Cicero).
    src.TriggerMode = 'On';
    src.TriggerSource = 'Line0';    
%     src.LineMode = 'Trigger'% maybe? - Kurt;
    src.TriggerActivation = 'RisingEdge';
%    src.TriggerActivation = 'FallingEdge';

    %src.LineDebounceTime=10;
    src.TriggerDelayEnabled = 'False';
    src.BinningVertical=1;
    src.BinningHorizontal=1;
   
    vid.LoggingMode = 'memory';
   
    src.ExposureTime=exposureTime; %Exposure time in us; for 300us actually goes to 300.765;
    %src.ExposureTime=10000; %Exposure time in us; for 300us actually goes to 300.765;   
    %src.ExposureTime=exposureTime;
    src.Gain=cameraGain;
    src.PacketSize = 9000;
    src.GammaEnabled='False';
    
    
    startTime=now;
    
    
    
    StopFcn=@(videoInput, callbackdata) disp([datestr(now) ' Video stopped.']);

    vid.TriggerFcn=@TriggerFcn;
    vid.StartFcn=@StartFcn;
    vid.StopFcn=StopFcn;  
    
    start(vid)
      
    
    function CloseRequestFcn(handle, callbackdata)
       disp('Closing feed...');
       if isvalid(vid)
           stop(vid); 
       end            
       delete(vid);
       delete(gcf);
    end  
    
    function StartFcn(vidInputHandle, callbackdata)

        %%Set up Output Figure
        hFig=figure;
    %     hFig.Visible='off';
        hFig.MenuBar='None';
        hFig.ToolBar='None';
        hFig.Name= [ROIName,' Beam Coordinates on Camera'];
        hFig.Resize='Off';
        hFig.CloseRequestFcn=@CloseRequestFcn;
        hFig.Position(1)=100;
        hFig.Position(2)=100;
        hFig.Position(3)=1800;
        hFig.Position(4)=700;
        hFig.DoubleBuffer='Off';  
        
        xlim([0 maxTime]);    
       % ylim([8.4e6 1.0e7]);
        hold on     


       % Initialize Axes for Center Position Plotting
        hXPosAxes=subplot(221);
        hXPosAxes.FontSize=14;
        ylabel(hXPosAxes,'Beam X Position (pixel)');
        %     xlabel(hXPosAxes,'Time');
        xlim([0 maxTime]);    %Photodiod x axis limits
        % ylim([0 20e6]);  %Photodiode y axis limist
        hold on  
        grid on

        hYPosAxes=subplot(223);
        hYPosAxes.FontSize=14;
        ylabel(hYPosAxes,'Beam Y Position (pixel)');
        xlabel(hYPosAxes,'Time');
        xlim([0 maxTime]);    %Photodiod x axis limits
        % ylim([0 20e6]); % Photodiode y axis limist
        hold on   
        grid on
        

        % Initialize Axes for Camera Image Plot
        hImageAxes=subplot(122);
        hImageAxes.FontSize=14;

        ylabel(hImageAxes,'Y Pixel');
        xlabel(hImageAxes,'X Pixel');
        title(hImageAxes, 'Live Preview');

        set(hImageAxes, 'XLimMode','manual',...
             'YLimMode','manual',...
             'ZLimMode','manual',...
             'XLimMode','manual',...
             'ALimMode','manual');

         hImageAxes.YLim=[1 960/2];
         hImageAxes.XLim=[1 1280/2];

         if useROI
             hImageAxes.YLim=[1 ROI(2)-ROI(1)];
             hImageAxes.XLim=[1 ROI(4)-ROI(3)];
         end

         if useROI
             %Blank initial image
             sampleFrame=zeros(ROI(2)-ROI(1),ROI(4)-ROI(3));%imread('blackfly_2015_08_04_18_29_11.4205.tiff');
         end
    %      hold on;  

         hImage=imshow(sampleFrame,'Parent', hImageAxes);
         hImage=imagesc(ROI(3:4),ROI(1:2),sampleFrame);
%          hImageAxes.CLim=theCLim;
         colormap hot
         colorbar

        % Setting Sizes of Data Axes and Image Axes
         hYPosAxes.Position=[0.0500    0.100    0.3500    0.400];
         hXPosAxes.Position=[0.0500    0.5500    0.3500    0.4000];

         hYPosAxes.Position=[0.0500    0.100    0.4400    0.400];
         hXPosAxes.Position=[0.0500    0.5500    0.4400    0.4000];
         
        % Calculations for and setting of  Image Axes Aspect Ratio in Pixels such that the
         % pixels appear square in the plotted image (image not stretched or
         % squeezed

         relXPos = 0.53;
         relYPos = 0.085;
         relHeight = 0.84;
         relWidth = 0.4377;

         trueWidth = hFig.Position(3)*relWidth;
         trueHeight = hFig.Position(4)*relHeight;

         hImageAxes.Position=[relXPos    relYPos    relWidth    relHeight];
         naturalAspectRatio = trueWidth/trueHeight;
         ROIRatio = (ROI(4)-ROI(3))/(ROI(2)-ROI(1));

         if ROIRatio > naturalAspectRatio
             height = relHeight*(trueWidth/trueHeight)*(1/ROIRatio);
             yPos = relYPos + (relHeight-height)/2;
             hImageAxes.Position=[relXPos    yPos    relWidth    height];
         else
             width = relWidth*(trueHeight/trueWidth)*ROIRatio;
             xPos = relXPos + (relWidth-width)/2;
             hImageAxes.Position=[xPos    relYPos    width    relHeight];
         end 

         
        
        %% Store figure and relevant data in the "vidInputHandle.UserData" so that it can be accessed from a trigger call.    
   vidInputHandle.UserData = struct('iter',1, 'times',zeros(100000,1), 'xCenterPositionVec',zeros(100000,1),'hxplot',plot(hXPosAxes,[0],[0],'-ob'), ...
       'yCenterPositionVec',zeros(100000,1),'hyplot',plot(hYPosAxes,[0],[0],'-ob'),...
       'hFig',hFig,'hXPosAxes',hXPosAxes,'hYPosAxes',hYPosAxes,'hImage',hImage,'hImageAxes',hImageAxes);
        
        disp([datestr(now) ' Starting video... Waiting for ' num2str(vid.TriggerRepeat+1) ' hardware triggers.'])

    end

    function TriggerFcn(vidInputHandle, callbackdata)
        %Abbreviate vidInputHandle.UserData as ud
        ud = vidInputHandle.UserData;
        
%         %Indicate Trigger Retreival
%         disp([datestr(now) ' Trigger ' num2str(ud.iter) ' received.'])
        %Getting Image Taken on Trigger
        img=getdata(vid);
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
        [~,xo,wx,yo,wy,fi]=fit2DGauss(ROI,img,cm);
        ud.xCenterPositionVec(ud.iter)=xo;
        ud.yCenterPositionVec(ud.iter)=yo;
        cla(ud.hXPosAxes);  % Clearing axes to prevent from wasting memory
        delete(findall(gcf,'type','annotation')) %Delete the display of current value
        cla(ud.hYPosAxes); 
        delete(findall(gcf,'type','annotation')) %Delete the display of current value
        ud.hxplot = plot(ud.hXPosAxes,ud.times(1:ud.iter),ud.xCenterPositionVec(1:ud.iter),'-r');  %Plotting X centers
        ud.hyplot = plot(ud.hYPosAxes,ud.times(1:ud.iter),ud.yCenterPositionVec(1:ud.iter),'-r');  %Plotting Y centers
        set(ud.hxplot,'LineWidth',4)
        set(ud.hyplot,'LineWidth',4)
        annotation('textbox',[0.27 0 0.3 0.3], 'String', [num2str(ud.yCenterPositionVec(ud.iter),3)], 'FitBoxToText','on','FontSize',32); %Display currently plotted value on graph as an annotation
        annotation('textbox',[0.27 0.5 0.3 0.3], 'String', [num2str(ud.xCenterPositionVec(ud.iter),3)], 'FitBoxToText','on','FontSize',32);
        if (now-startTime)*24*60*60>maxTime

            %Getting the data from the plot
            do=get(ud.hXPosAxes,'Children');
            times=get(do,'XData');
            xcenter=get(do,'YData');

            do = get(ud.hYPosAxes,'Children');
            ycenter = get(do,'YData');


            %Saving the plotted data to files
            save([datestr(now,'yyyy_mm_dd_HH_MM_SS') '_beamCenterVsTime.mat'],'times','xcenter','ycenter');  
            save([datestr(now,'yyyy_mm_dd_HH_MM_SS') '_lastImageOfRun.mat'],'img')
            savefig([datestr(now,'yyyy_mm_dd_HH_MM_SS') '_TraceAndFinalImage'])
            imwrite(img,[datestr(now,'yyyy_mm_dd_HH_MM_SS') '_FinalImage.tiff'],'tiff');

           cla(hXPosAxes); 

           ud.iter=1;
           ud.times=zeros(100000,1);
           ud.numCountsVec = zeros(100000,1);

           %Resetting the start time of the photodiod plot
           startTime=now;
           %Resetting the last time a preview image was plotted to 0 
           lastPreviewTime =0;
           vidInputHandle.UserData=ud;
        else
            if ud.times(ud.iter)-lastPreviewTime > previewPeriod
                %Plotting Camera Image as a 2D plot
                cla(ud.hImageAxes)
                imagesc(ud.hImageAxes,ROI(3:4),ROI(1:2),img);
                colorbar
                hold on
%                         hImage.CData=img;     
                plot(ud.hImageAxes,[xo],[yo],'.b','markersize',32);
                plot(ud.hImageAxes,[cmx],[cmy],'.r','markersize',32);
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
                plot(ud.hImageAxes,[xvh(1) xvh(size(xvh))],[yvh(1) yvh(size(yvh))],'r'); 
                plot(ud.hImageAxes,[xvv(1) xvv(size(xvv))],[yvv(1) yvv(size(yvv))],'g');
                tel=-pi:0.1:pi+0.2;
                xel=wx*cos(tel);
                yel=wy*sin(tel);
                xelrot = xel.*cos(-fi)-yel.*sin(-fi);
                yelrot = xel.*sin(-fi)+yel.*cos(-fi);
                xelrot = xelrot+xo;
                yelrot = yelrot+yo;
                plot(ud.hImageAxes,xelrot,yelrot,'linewidth',4);
                %Setting the most recent time a camera image was
                %plotted
                lastPreviewTime = ud.times(ud.iter);
            end
            drawnow;
            ud.iter = ud.iter+1;
            vidInputHandle.UserData=ud;  %Passing user data to the next iteration of the Timer object
        end
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

function [Amp,xo,wx,yo,wy,fi] = fit2DGauss(ROI,img,cm)
    % Fits the image data to a gaussing using lsqcurvefit (square error
    % minimization by iterative algorithm.
    guess=double([max(max(img)),mean([ROI(3) ROI(4)]),abs((ROI(3)-ROI(4))./2)...
        ,mean([ROI(1) ROI(2)]),abs((ROI(1)-ROI(2))./2),0]);
    guess = [124  cm(1)   17  cm(2)   27    0.2854];
    lb = double([0,0,0,0,0,-pi./4]); %
    ub = double([guess(1).*2,max([ROI(3) ROI(4)]),guess(3).*2,max([ROI(1) ROI(2)]),guess(5).*2,pi./4]);
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
end

function F = D2GaussFunctionRot(x,xdata)
    % Gaussian functional form.
    %% x = [Amp, x0, wx, y0, wy, fi]
    %%
    xdatarot(:,:,1)= xdata(:,:,1)*cos(x(6)) - xdata(:,:,2)*sin(x(6));
    xdatarot(:,:,2)= xdata(:,:,1)*sin(x(6)) + xdata(:,:,2)*cos(x(6));
    x0rot = x(2)*cos(x(6)) - x(4)*sin(x(6));
    y0rot = x(2)*sin(x(6)) + x(4)*cos(x(6));

    F = x(1)*exp(   -((xdatarot(:,:,1)-x0rot).^2/(2*x(3)^2) + (xdatarot(:,:,2)-y0rot).^2/(2*x(5)^2) )    );
end