classdef TrackerMonitor < handle
    
   properties
       figureId;
       enabled;
       pause;
   end

    methods
    
        function [obj] = TrackerMonitor(figureId) 
            obj.enabled = 0;
            obj.pause = 0;
            obj.figureId = figureId;
        end;
    
        function [] = setEnabled(obj, e)
            obj.enabled= (e ~= 0);
        end;
        
        function [e] = isEnabled(obj)
            e = obj.enabled;
        end;
        
        function [] = setPause(obj)
            obj.pause=1;
        end;
        
        function [hf] = window(obj, channel, title)
            if (~obj.enabled)
                hf = -1;
                return;
            end;
            channel = max(1, channel);
            hf = sfigure(obj.figureId + channel);
            if (nargin > 2)
                set(hf, 'Name', sprintf('Debug: %s (channel %d)', title, channel), 'NumberTitle', 'off');
            else
                set(hf, 'Name', sprintf('Debug: channel %d', channel), 'NumberTitle', 'off');
            end;
        end;
                
        function [] = image(obj, channel, image)
             if (~obj.enabled)
                return;
            end;
            
            obj.window(channel);
            
            imshow(image ./ 255);
            
            hold on;
                        
            if (obj.pause)
                try
                    waitforbuttonpress;
                catch e
                    obj.enabled=0;
                end;
            else
                drawnow;
            end;
            
        end;
        
                        
        function [] = images(obj, channel, varargin)
             if (~obj.enabled)
                return;
            end;
            
            obj.window(channel);
            
            n = length(varargin) - 1;
            
            sx = floor(sqrt(n));
            sy = ceil(n / sx);

            for i = 1:n
                subplot(sx, sy, i);
                imshow(varargin{i} ./ 255);
            end;
            
            hold on;
                        
            if (obj.pause)
                try
                    waitforbuttonpress;
                catch e
                    obj.enabled=0;
                end;
            else
                drawnow;
            end;
            
        end;
        
    end;
   
end