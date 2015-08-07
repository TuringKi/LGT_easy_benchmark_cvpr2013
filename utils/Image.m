classdef Image < handle

    properties
        
        rgbimage;

        grayimage;
        
        hsvimage;
        
        isize;

        source;
    end

    methods
        
        function [obj] = Image(i)
            
            if ischar(i)
                image = imread(i);

                
                obj.source = i;
                if size(image, 3) > 1
                    obj.rgbimage = image;
                else
                    obj.grayimage = image;
                end;
            end;
            
            [x y] = obj.size();
            obj.isize = [x y];
        end;
        
        function [grayimg] = gray(obj)
            if (isempty(obj.grayimage))
                obj.grayimage = rgb2gray(obj.rgbimage);
            end;
            grayimg = obj.grayimage;
        end;
        
        function [hsvimg] = hsv(obj)
            if (isempty(obj.hsvimage))
                obj.hsvimage = rgb2hsv(obj.rgb());
            end;
            hsvimg = obj.hsvimage;
        end;

        function [rgbimg] = rgb(obj)
            if (isempty(obj.rgbimage))
                s = size(obj.grayimage);
                s(3) = 3;
                obj.rgbimage = zeros(s);
                
                obj.rgbimage(:,:,1) = obj.grayimage;
                obj.rgbimage(:,:,2) = obj.grayimage;
                obj.rgbimage(:,:,3) = obj.grayimage;
            end;
            rgbimg = obj.rgbimage;
        end;
        
        function [w h] = size(obj)
            if (isempty(obj.rgbimage))
                [w h] = size(obj.grayimage);
            else
                [w h] = size(obj.rgbimage);
                h = h / 3;
            end;
        end;
        
        function [w] = width(obj)
            if (isempty(obj.rgbimage))
                w = size(obj.grayimage, 2);
            else
                w = size(obj.rgbimage, 2);
                %w = w / 3;
            end;
        end;
        
        function [h] = height(obj)
            if (isempty(obj.rgbimage))
                h = size(obj.grayimage, 1);
            else
                h = size(obj.rgbimage, 1);
                %w = w / 3;
            end;
        end;
        
        function [P] = sample_gray_rectangle(obj, x, y, w, h)
            
            x = max(min(x, obj.isize(2) - 1), 1);
            y = max(min(y, obj.isize(1) - 1), 1);
            w = max(min(w, obj.isize(2) - x), 1);
            h = max(min(h, obj.isize(1) - y), 1);
            
            I = obj.gray();
            
            P = I(y:y+h, x:x+w);
            
            P = P(:);
            
        end;
        
        function [P] = sample_gray_center(obj, x, y, dx, dy)
            
            P = obj.sample_gray_rectangle(x - dx, y-dy, 2 * dx, 2 * dy);
            
        end;
        
        function [cropped] = crop(obj, rectangle)
            c = zeros([rectangle(3), rectangle(4), 3]);
            
            c = patchOperation(c, obj.rgb(), -rectangle(1:2), '=');
            
            cropped = Image(1);
            
            cropped.rgbimage = c;
            
        end;
        
        function [scaled] = scale(obj, scale)
            
            scaled = Image(1);
            
            scaled.rgbimage = imresize(obj.rgb(), scale);
            
        end;
        
    end
    
    
end
