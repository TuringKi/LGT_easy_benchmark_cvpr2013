classdef Modalities < handle
    
    properties
        pastimage;
        
        pastposition;
        
        parameters;

        sample_mask;
        
        map;
        
        map_size;
        
        combined;
        
        color_on;
        
        color_foreground;
        
        color_background;
        
        color_map;
        
        motion_on;
        
        motion_map;
        
        shape_on;
        
        shape_shape;
        
        shape_map;
    end;
    
    methods
        
        function [obj] = Modalities(parameters)

            obj.map_size = parameters.window;
            
            obj.parameters = parameters;
            
            obj.color_on = parameters.color.enabled;
            
            obj.motion_on = parameters.motion.enabled;
            
            obj.shape_on = parameters.shape.enabled;
            
            obj.flush();
            
        end;
        
        function [] = flush(obj)
            obj.pastimage = [];
            obj.map = [];
            obj.sample_mask = [];
            obj.pastposition = [];

            obj.color_map = [];
            obj.color_foreground = [];
            obj.color_background = [];
            
            obj.motion_map = [];
            
            obj.shape_map = [];
            obj.shape_shape = [];
        end;
                
        function [] = mask(obj, positions)
            
            if (isempty(obj.sample_mask))
                return;
            end;
            
            mask = zeros(size(obj.sample_mask)) + 1;
            
            [w h] = size(mask);
            
            K = 1 - scalemax(gaussKernel(eye(2) * obj.parameters.mask), 1);
            
            [ow oh] = size(K);
            o = uint32([ow oh] ./ 2);
            
            for i = 1:size(positions, 1)
                
                y = uint32(double(positions(i, 2)) - obj.pastposition(2) + obj.map_size / 2);
                x = uint32(double(positions(i, 1)) - obj.pastposition(1) + obj.map_size / 2);   
                
                if (x < 1 || x > w || y < 1 || y > h)
                    continue;
                end;

                mask = patchOperation(mask, K, int32([x y] - o), '*');
            end;

            obj.sample_mask = obj.sample_mask .* mask;
            
        end;
        
        function [] = update(obj, image, position, pool, indices)
                        
            obj.sample_mask = ones(obj.map_size, obj.map_size);
 
            if (isempty(obj.pastimage))
                obj.pastimage = image;
                obj.pastposition = position;
                return;
            end;
            
            context.current_image = image;
            context.current_position = position;
            context.previous_image = obj.pastimage;
            context.previous_position = obj.pastposition;            
            context.map_size = obj.map_size;
            context.pool = pool;
            context.indices = indices;
            
            if obj.shape_on
                t = cputime;
                obj.update_shape(context);
                display(sprintf('Shape update %.3fs', cputime() - t));                
            end;
            
            if obj.color_on
                t = cputime;
                obj.update_color(context);
                display(sprintf('Color update %.3fs', cputime() - t));
            end;
            
            if obj.motion_on
                t = cputime;
                obj.update_motion(context);
                display(sprintf('Motion update %.3fs', cputime() - t));
            end;

            obj.pastimage = image;
            obj.pastposition = position;
            
        end;
        
        function [positions] = candidates(obj, N)
            
            obj.map = ones(obj.map_size, obj.map_size);
            usable = 0;
            
            if obj.color_on && ~isempty(obj.color_map)
                obj.map = obj.map .* obj.color_map;
                usable = 1;
            end;

            if obj.motion_on && ~isempty(obj.motion_map)
                obj.map = obj.map .* obj.motion_map;
                usable = 1;
            end;
            
            if obj.shape_on && ~isempty(obj.shape_map)
                obj.map = obj.map .* obj.shape_map;
                usable = 1;
            end;

            if ~usable
               positions = [];
               return;
            end
            
            obj.combined = obj.map;
                      
            threshold = max(max(obj.map)) * 0.2;
            
            se = ones(5);
            obj.map = obj.map .* (imfilter(double(obj.map > threshold), se) > 15);
            
            %obj.map = obj.map .* imdilate(imerode(obj.map > threshold, se), se);

            positions = zeros(N, 2);
            
            for i = 1:N
                tmap = obj.map .* obj.sample_mask;

                tmap(tmap < threshold) = 0;
                
                pos = sampleProbabilityMap(tmap');
                              
                if (isempty(pos) || any(pos < 1) || any(pos > obj.map_size))
                    if (i == 1)
                        positions = [];
                    else
                        positions = positions(1:i-1, :);
                    end;
                    break;
                end;
                
                x = uint32(pos(2) + obj.pastposition(1) - obj.map_size / 2);
                y = uint32(pos(1) + obj.pastposition(2) - obj.map_size / 2);  

                positions(i, 1:2) = [x y];

                obj.mask([x y]);

            end;

        end;
        
        
        function [] = debug(obj)
           global monitor;
           
           if exist('monitor','var') 
               if (~isempty(monitor) && monitor.isEnabled())
            
                images = cell(6, 1);
                
                images{1} = scalemax(obj.color_map, 255);
                images{2} = scalemax(obj.motion_map, 255);
                images{3} = scalemax(obj.shape_map, 255);

                images{4} = scalemax(obj.combined, 255);
                                
                images{5} = scalemax(obj.map, 255);

                images{6} = scalemax(obj.sample_mask, 255);

                images{end + 1} = [];
                monitor.images(1, images{:});
               end;
            end;
            
        end 
        
        function [map] = update_shape(obj, context)
            positions = context.pool.positions();
            
            if (context.pool.count < 3)
                map = obj.shape_map;
                return;
            end;

            hull = convhull(positions(:, 1), positions(:, 2));
            positions = positions(hull, :);
            
            x = positions(:, 2) - context.current_position(2) + obj.map_size / 2;
            y = positions(:, 1) - context.current_position(1) + obj.map_size / 2;
            
            if (isempty(obj.shape_shape))
                obj.shape_shape = zeros(obj.map_size, obj.map_size);
            end;
            
            p = obj.parameters.shape.persistence;
            
%             obj.shape_shape = scalemax(p * obj.shape_shape + (1- p) * poly2mask(x, y, obj.map_size, obj.map_size), 1);
% 
%             radius = obj.parameters.shape.expand;
%             
%             if (radius > -1)
%                 se = logical(coneFilter(radius * 2 + 1, 1, 0, radius, radius));
%                 obj.shape_map = imdilate(obj.shape_shape > 0.3, se) .* 0.7 + 0.3 .* obj.shape_shape;
%             else
%                 obj.shape_map = ones(obj.map_size, obj.map_size);
%             end
            radius = obj.parameters.shape.expand;
            

            %se = logical(coneFilter(radius * 2 + 1, 1, 0, radius, radius));
            
            origin = mean([x, y], 1);
            vector = [x, y] - ones(size(x, 1), 1) * origin;
            len = sqrt(sum(vector .^2, 2));
            scale = (len + radius) ./ len;
            expanded =  ones(size(x, 1), 1) * origin + vector .* [scale , scale];
            
            new_shape = poly2mask(x, y, obj.map_size, obj.map_size) * 0.3 + poly2mask(expanded(:, 1), expanded(:,2), obj.map_size, obj.map_size) * 0.7;
            
            %new_shape = poly2mask(x, y, obj.map_size, obj.map_size);
            %new_shape = imdilate(poly2mask(x, y, obj.map_size, obj.map_size), se); % * 0.7 + 0.3 * new_shape;

            obj.shape_shape = scalemax(p * obj.shape_shape + (1- p) * new_shape, 1);

% CHANGE END

            obj.shape_map= normalize(obj.shape_shape);
            
            map = obj.shape_map;
        end;
        
        function [map] = update_color(obj, context)
            
            if (isempty(obj.color_foreground))
                obj.color_foreground = normalise(ones(obj.parameters.color.bins));
                obj.color_background = normalise(ones(obj.parameters.color.bins));
            end;
            if strcmp(obj.parameters.color.color_space,'hsv')
                imagecs = round(context.current_image.hsv() .* 255);
            elseif strcmp(obj.parameters.color.color_space, 'rgb')
                imagecs = context.current_image.rgb();
            end;
            
            bins = obj.parameters.color.bins;
            
            radius = obj.parameters.color.fg_sampling;            
            
            M = logical(coneFilter(obj.parameters.color.fg_sampling * 2 + 1, 1, 0, radius, radius));

            positions = context.pool.positions();
            positions = positions(context.indices, :);
            
            j = 0;

            samples = zeros(0, 3);
            perpoint = sum(sum(M));
            for i = 1:size(positions, 1)
                
                P = sample_image_points(imagecs(:, :, :), positions(i, :), M);
                
                if (isempty(P))
                    continue;
                end;
                
                samples(end+1:end+size(P, 1), 1:3) = P;
                j = j + perpoint;

            end;
            
            if j > 0
                fgappearance = normalise(ndHistc(samples, linspace(0,256,bins(1)+1), linspace(0,256,bins(2)+1), linspace(0,256,bins(3)+1)));
                w = obj.parameters.color.fg_persistence;
                obj.color_foreground = w * obj.color_foreground + (1 - w) * fgappearance;
            end;

            spacing = obj.parameters.color.bg_sampling(1);
            width = obj.parameters.color.bg_sampling(2);            

            appearance = zeros(context.map_size, context.map_size, 3);
            [appearance mask] = patchOperation(appearance, imagecs, -int32(context.current_position - (context.map_size) / 2), '=');
            
           positions = context.pool.positions();
            
            if (context.pool.count >= 3)

                hull = convhull(positions(:, 1), positions(:, 2));
                positions = positions(hull, :);

                x = positions(:, 2) - context.current_position(2) + obj.map_size / 2;
                y = positions(:, 1) - context.current_position(1) + obj.map_size / 2;

                if (isempty(obj.shape_shape))
                    obj.shape_shape = zeros(obj.map_size, obj.map_size);
                end;

                segmentation = poly2mask(x, y, obj.map_size, obj.map_size);
                smask = imdilate(segmentation, ones(spacing + width)) & ~imdilate(segmentation, ones(spacing)) & mask;

                c1 = appearance(:, :, 1);
                c2 = appearance(:, :, 2);
                c3 = appearance(:, :, 3);

                p = (sum(sum(segmentation)) / numel(segmentation));

                if p > 0.01
                    P = [c1(smask), c2(smask), c3(smask)];
                    bgappearance = normalise(ndHistc(P, linspace(0,256,bins(1)+1), linspace(0,256,bins(2)+1), linspace(0,256,bins(3)+1)) + 1);
                    w = obj.parameters.color.bg_persistence;
                    obj.color_background = w * (obj.color_background) + (1 - w) * bgappearance;
                end;
            end;


            p = 0.1; %(sum(sum(context.segmentation)) / prod(size(context.segmentation)));

            model = p .* (obj.color_foreground) ./ ((p .* obj.color_foreground + (1 - p) .* obj.color_background));
            
            if (bins(1) > 1)
                appearance(:, :, 1) = floor(appearance(:, :, 1) / (256 / bins(1)));
            end;
            if (bins(2) > 1)
                appearance(:, :, 2) = floor(appearance(:, :, 2) / (256 / bins(2)));
            end;
            if (bins(3) > 1)
                appearance(:, :, 3) = floor(appearance(:, :, 3) / (256 / bins(3)));
            end;
            
            obj.color_map = backproject( appearance(:, :, bins > 1), model);

            mask = imdilate(imerode(mask, ones(2)), ones(2));
            
            obj.color_map(~mask) = 0;
            
            obj.color_map = normalize(obj.color_map);
            
            map = obj.color_map;

        end
        
        function [map] = update_motion(obj, context)
            
            if (isempty(context.indices))
                map = obj.motion_map;
                return;
            end;
            
            cur_positions = context.pool.positions();
            pre_positions = context.pool.trajectories.history(1);
            
            move = pre_positions(context.indices, :) - cur_positions(context.indices, :);

            if (all(~isnan(move)))
                
                v = wmean(move, context.pool.weights(context.indices)');
                
                gray1 = uint8(patchOperation(zeros(context.map_size), context.previous_image.gray(), - context.current_position - v + context.map_size / 2, '='));
                gray2 = uint8(patchOperation(zeros(context.map_size), context.current_image.gray(), - context.current_position + context.map_size / 2, '='));

                [~, y, x] = harris(gray2, 1, obj.parameters.motion.harris_threshold, 2, 0);

                [flow, ok] = OpticalFlowLKHier(gray2, gray1, x', y', obj.parameters.motion.lk_size, obj.parameters.motion.lk_layers);

                result = zeros(size(gray1));

                flow = round(flow' - [x, y]);
                
                weights = zeros(sum(ok), 1);
                
                for a = find(ok)

                    n = norm(flow(a, :));

                    weights(a) = exp(-n * obj.parameters.motion.damping);
                 
                    result( y(a), x(a)) = weights(a);

                end;
                
%                weights = normalize(weights);

%                 if (var(weights) < 1e-6)
%                     return;
%                 end;

                result = conv2(result, gaussKernel(eye(2) * 90), 'same');

                result = normalize(result)  .* 0.99 + 0.01 * 1 / numel(result);

                if (isempty(obj.motion_map))
                    obj.motion_map = ones(size(result));
                end;
            
                obj.motion_map = obj.parameters.motion.persistence * obj.motion_map + ((1 - obj.parameters.motion.persistence) * result);
            
                obj.motion_map = normalize(obj.motion_map);
 
            end
            
            map = obj.motion_map;
        end
        
    end;

      
        
    
end
