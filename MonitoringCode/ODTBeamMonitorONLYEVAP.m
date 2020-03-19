function [] = ODTBeamMonitorONLYEVAP( ROIName )
%Function for initializing the ODT (or XODT) Camera to monitor the ODT
%(XODT) position
%   The function displays the image of the ODT (XODT) beam on the camera
%   and fits a 2D gaussian to it.  The center of the gaussian is
%   identified, and the resulting x and y coordinates are plotted.
if (nargin < 1)
    ROIName = 'odt';
end
    
lowerROIName = lower(ROIName);

switch lowerROIName
    case {'odt','odtbeam'}
%         ROI = [170 230 850 900];
        ROI = [1 960 1 1280];  % FULL ROI of ODT Camera
%         ROI = [1 960/10 1 1280/10];
        cameraNumber = 2;
        exposureTime = 50;
        cameraGain = 0.01;
    case {'xodt','xodtbeam'}
%         ROI = [180 230 180 230];
        ROI = [100 200 200 300];  % FULL ROI of XODT Camera
%         ROI = [1 304/4 1 404/4];
        cameraNumber = 1;
        exposureTime = 50;
        cameraGain = 0.01;
    otherwise
        error('Input ROIName was given as %s and the associated ROI could not be set',ROIName)
end
maxBitSignal=2^8;
maxSum=960/2*1280/2*2^8;


%%% MANUAL OPTIONS SETTINGS %%%
maxTime=50;  %SET THIS FOR LENGTH OF INDIVIDUAL SCANS
theCLim=[1 256];
yLimPD=[10^6 maxSum/2];
useROI=1;

framePeriod = 0.05; %%   Fastest frame rate is ~17Hz no matter what WAS 0.001    SLOWED DOWN BECAUSE IT WAS LOGGING INCORRECTLY        SETS TIME BETWEEN ITERATIONS
% exposureTime = 300000.765038;  %Sr84 exposure time for before 8/4   Weak Sr84 MOT
% exposureTime = 100000.765038;
% exposureTime = 10000.765038;
% exposureTime = 200000.765038;
% exposureTime = 30000.765038;   
% exposureTime = 3000.765038;
% exposureTime = 1500.765038;
exposureTime = 50;
% cameraGain = 9.2668;
cameraGain = 0.01;


previewPeriod = 0.2;
lastPreviewTime = 0;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    hFig=figure;
    hFig.Visible='off';
    hFig.MenuBar='None';
    hFig.ToolBar='None';
    hFig.Name= 'Integrated Camera Signal';
    hFig.CloseRequestFcn=@CloseRequestFcn;
    hFig.Resize='Off';
    hFig.Position(1)=100;
    hFig.Position(2)=100;
    hFig.Position(3)=1800;
    hFig.Position(4)=700;
    hFig.DoubleBuffer='Off';  
    hFig.Color = 'red';

    
    xlim([0 maxTime]);    

    hold on     

     
     
    %%WITH IMAGING PREVIEWS 
    hXPosAxes=subplot(221);
    hXPosAxes.FontSize=14;
    ylabel(hXPosAxes,'Beam X Position (pixel)');
%     xlabel(hXPosAxes,'Time');
    xlim([0 maxTime]);    %Photodiod x axis limits
   % ylim([0 20e6]);  Photodiode y axis limist
    hold on  
    grid on
    
    hYPosAxes=subplot(223);
    hYPosAxes.FontSize=14;
    ylabel(hYPosAxes,'Beam Y Position (pixel)');
    xlabel(hYPosAxes,'Time');
    xlim([0 maxTime]);    %Photodiod x axis limits
   % ylim([0 20e6]);  Photodiode y axis limist
    hold on   
    grid on
    
    
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
     
     
     %%%% THIS SHOULD BE SET TO RESOLUTION OF CAMERA OR ELSE TO THE SIZE OF
     %%%% THE IMAGE FOR THE WHOLE IMAGE 
     if useROI
         sampleFrame=zeros(ROI(2)-ROI(1),ROI(4)-ROI(3));%imread('blackfly_2015_08_04_18_29_11.4205.tiff');
     end
%      hold on;  
     
     hImage=imshow(sampleFrame,'Parent', hImageAxes);
     hImage=imagesc(ROI(3:4),ROI(1:2),sampleFrame);
     hImageAxes.CLim=theCLim;
     colormap hot
    
     hYPosAxes.Position=[0.0500    0.100    0.3500    0.400];
     hXPosAxes.Position=[0.0500    0.5500    0.3500    0.4000];
% % % % %      hImageAxes.Position=[0.46    0.125    0.525    0.815];
     
     hYPosAxes.Position=[0.0500    0.100    0.4400    0.400];
     hXPosAxes.Position=[0.0500    0.5500    0.4400    0.4000];
% % %      relXPos = 0.46;
     relXPos = 0.53;
% % %      relYPos = 0.125;
     relYPos = 0.05;
     relHeight = 0.8965;
% % %      relWidth = 0.5250;
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
     

    [vid, src]=initializeCameraFreeRun;   

    myTimer=timer;
    myTimer.ExecutionMode='fixedSpacing';
    myTimer.Period=framePeriod;       
    myTimer.TimerFcn=@TimerFcn;
    myTimer.StartDelay=0.05;           
    myTimer.StartFcn=@TimerStartFcn;
    
    disp(myTimer.UserData)
    
    startTime=now;
  
    function CloseRequestFcn(handle, callbackdata)
           disp('Closing feed...');
           if isvalid(vid)
               stop(vid); 
           end
           delete(hFig);              
           delete(myTimer);
           delete(vid);
    end        

    function TimerStartFcn(handle, callbackdata)
       whitebg(hFig, 'white');
       handle.UserData = struct('iter',1, 'times',zeros(100000,1), 'xNumCountsVec',zeros(100000,1),'hxplot',plot(hXPosAxes,[],[],'-ob') ...
           ,'yNumCountsVec',zeros(100000,1),'hyplot',plot(hYPosAxes,[],[],'-ob'),'plotiter',1,'plottimes',zeros(10000,1));
    end
   
     function TimerFcn(handle,callbackdata)
         if isequal(vid.Running,'on');
            trigger(vid);
            pause(0.001);
            if vid.FramesAvailable>0 
                %Getting Video Image
                img=getdata(vid);
                ud=handle.UserData;
                
                if useROI
                    img = img(ROI(1):ROI(2),ROI(3):ROI(4));
                end
                %Drawing 1D Photodiode Plot (If the graph length is less than maxTime)
                ttlcounts = sum(sum(img))
                
                %Summing up all of the pixels
                [cmx,cmy] = centerOfMass(ROI,img);
                cm = [cmx,cmy];
                [Amp,xo,wx,yo,wy,fi]=fit2DGauss(ROI,img,cm);
                ud.times(ud.iter) = (now-startTime)*24*60*60;
                if (ttlcounts > 1000)&&(ttlcounts<40000)
                    ud.plottimes(ud.plotiter) = (now-startTime)*24*60*60;
                    ud.xNumCountsVec(ud.plotiter)=xo;
                    ud.yNumCountsVec(ud.plotiter)=yo;
                    ud.plotiter = ud.plotiter+1;
                    cla(hXPosAxes);  %Need to clear the photodiode plot every cycle or it slows down from too many overlaid graphs.  I am totally failing to figure out how to not have 'hold on' and graph like I want.  It shouldn't be so hard if I understood matlab plotting better.
                    cla(hYPosAxes);  %Need to clear the photodiode plot every cycle or it slows down from too many overlaid graphs.  I am totally failing to figure out how to not have 'hold on' and graph like I want.  It shouldn't be so hard if I understood matlab plotting better.
                    delete(findall(gcf,'type','annotation')) %Delete the display of current value
                    ud.hxplot = plot(hXPosAxes,ud.plottimes(2:ud.plotiter-1),ud.xNumCountsVec(2:ud.plotiter-1),'.r','linestyle','none','markersize',26);  %Plotting the total integral of the light count.  i.e. Photodiode count
                    ud.hyplot = plot(hYPosAxes,ud.plottimes(2:ud.plotiter-1),ud.yNumCountsVec(2:ud.plotiter-1),'.r','linestyle','none','markersize',26);  %Plotting the total integral of the light count.  i.e. Photodiode count
                    set(ud.hxplot,'LineWidth',4)
                    set(ud.hyplot,'LineWidth',4)
                    annotation('textbox',[0.27 0 0.3 0.3], 'String', num2str(ud.yNumCountsVec(ud.plotiter-1),3), 'FitBoxToText','on','FontSize',32); %Display currently plotted value on graph as an annotation
                    annotation('textbox',[0.27 0.5 0.3 0.3], 'String', num2str(ud.xNumCountsVec(ud.plotiter-1),3), 'FitBoxToText','on','FontSize',32);
                end
                if (now-startTime)*24*60*60>maxTime
                    
                    %Getting the data from the plot
                do=get(hXPosAxes,'Children');
                times=get(do,'XData');
                xcenter=get(do,'YData');
                
                do = get(hYPosAxes,'Children');
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
                   
                   %Stopping and restarting the video
                   stop(vid)
                   start(vid)
                   %Resetting the start time of the photodiod plot
                   startTime=now;
                   %Resetting the last time a preview image was plotted to 0 
                   lastPreviewTime =0;
                   handle.UserData=ud;
                else
                    if ud.times(ud.iter)-lastPreviewTime > previewPeriod
                        %Plotting Camera Image as a 2D plot
                        cla(hImageAxes)
                        imagesc(hImageAxes,ROI(3:4),ROI(1:2),img);
                        hold on
%                         hImage.CData=img;     
                        plot(hImageAxes,[xo],[yo],'.b','markersize',32);
                        plot(hImageAxes,[cmx],[cmy],'.r','markersize',32);
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
                        plot(hImageAxes,[xvh(1) xvh(size(xvh))],[yvh(1) yvh(size(yvh))],'r'); 
                        plot(hImageAxes,[xvv(1) xvv(size(xvv))],[yvv(1) yvv(size(yvv))],'g');
                        tel=-pi:0.1:pi+0.2;
                        xel=wx*cos(tel);
                        yel=wy*sin(tel);
                        xelrot = xel.*cos(-fi)-yel.*sin(-fi);
                        yelrot = xel.*sin(-fi)+yel.*cos(-fi);
                        xelrot = xelrot+xo;
                        yelrot = yelrot+yo;
                        plot(hImageAxes,xelrot,yelrot,'linewidth',4);
                        %Setting the most recent time a camera image was
                        %plotted
                        lastPreviewTime = ud.times(ud.iter);
                    end
                     drawnow;
                     ud.iter = ud.iter+1;
                     handle.UserData=ud;  %Passing user data to the next iteration of the Timer object
                end
                

     %%FOR OD PREVIEWER
                %Checking if it has been long enough to plot a new preview


            end
         end
         
     end
 
    function [Amp,xo,wx,yo,wy,fi] = fit2DGauss(ROI,img,cm)
        
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
        [x,resnorm,residual,exitflag] = lsqcurvefit(@D2GaussFunctionRot,guess,xdata,Z,lb,ub,options);
        Amp = x(1);
        xo = x(2);
        wx = x(3);
        yo = x(4);
        wy = x(5);
        fi = x(6);
    end

    function [x,y] = centerOfMass(ROI,img)
        [X,Y] = meshgrid((ROI(3):ROI(4)),(ROI(1):ROI(2)));
        X = double(X);
        Y = double(Y);
        img = double(img);
        sume = sum(sum(img));
        x = (sum(sum(X.*img)))./(sume);
        y = (sum(sum(Y.*img)))./(sume);
    end
 
    hFig.Visible='On';
    start(vid)
    start(myTimer);
    
    
    function [vid,src] = initializeCameraFreeRun
    %INITIALIZECAMERAFREERUN Summary of this function goes here
    %   Detailed explanation goes here
%         vid = videoinput('gige', 1, 'Mono12Packed'); %use 12-bit ADC, Packed?
        vid = videoinput('gige', cameraNumber, 'Mono8'); %use 12-bit ADC, Packed?
        src = getselectedsource(vid);    

        src.VideoMode='Mode1';

        vid.FramesPerTrigger = 1;
        set(src,'GainAuto','Off')   
        set(src,'ExposureAuto','Off')
        %         src.AllGain = 0; %Gain 
        src.ExposureTime=exposureTime; %Exposure time in us.  
        %         src.ExposureTime=300000.765038; %Exposure time in us.  for Weak Sr 84 Blue MOT
        %src.ExposureTime=10000; %Exposure time in us; for 300us actually goes to 300.765; 
        src.Gain = cameraGain;
        %        src.ExposureTime=100000.765038;
        src.PacketSize = 9000;
        src.PacketDelay = 100000;
        src.GammaEnabled='False';
        vid.FrameGrabInterval=1;
        vid.TriggerRepeat = Inf;
        triggerconfig(vid,'manual');

%         set(src,'AutoFunctionAOIHeight',480);  %%%% ADDED BECAUSE IT WAS NOT FINDING THE AOI CORRECTLY
%         set(src,'AutoFunctionAOIWidth',640);   %%%% ADDED BECAUSE IT WAS NOT FINDING THE AOI CORRECTLY
%        vid.TriggerFrameDelay = 10;  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
        
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%S  src.Gain=13;   %TRYING TO REALLY CRANK UP THE GAIN

        function ErrorFcn(vidobj,callbackdata)
           stop(myTimer);
           whitebg(hFig, 'red')
           disp([datestr(callbackdata.Data.AbsTime) ': ' callbackdata.Data.Message]);
           disp([vidobj.FramesAcquired ' frames acquired before crash.']);
           disp('Stopping the camera...');
            
           stop(vidobj); 

           pause(0.5);
           disp('Starting camera...');
           start(vidobj);
           pause(0.5);
           start(myTimer);
           
           
        end

        function StartFcn(vidobj,callbackdata)
           disp('Starting video');
        end
        vid.ErrorFcn=@ErrorFcn;    

    end

    function F = D2GaussFunctionRot(x,xdata)
        %% x = [Amp, x0, wx, y0, wy, fi]
        %%
        xdatarot(:,:,1)= xdata(:,:,1)*cos(x(6)) - xdata(:,:,2)*sin(x(6));
        xdatarot(:,:,2)= xdata(:,:,1)*sin(x(6)) + xdata(:,:,2)*cos(x(6));
        x0rot = x(2)*cos(x(6)) - x(4)*sin(x(6));
        y0rot = x(2)*sin(x(6)) + x(4)*cos(x(6));

        F = x(1)*exp(   -((xdatarot(:,:,1)-x0rot).^2/(2*x(3)^2) + (xdatarot(:,:,2)-y0rot).^2/(2*x(5)^2) )    );
    end

end

