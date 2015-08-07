classdef MotionObserver < handle
    
    properties
        trajectories = {};
        count;
        
    end;
    
    methods
        
        function [obj] = MotionObserver()
            obj.flush();
        end;
        
        function [] = flush(obj)
            obj.trajectories = {};
            obj.count = 0;            
        end;
        
        function [count] = add(obj, position)
            
            obj.trajectories{obj.count + 1} = [position(1), position(2)];
            obj.count = length(obj.trajectories);   
            count = obj.count;
            
        end;

        function [count] = remove_all(obj, indices)
            
            indices = indices(indices > 0 & indices <= obj.count);
            
            if (~isempty(indices))
                
                mask = true(obj.count, 1);
                
                mask(indices) = 0;
                
                obj.trajectories = obj.trajectories(mask);
                obj.count = obj.count - length(indices);
                
            end;
            
            count = obj.count;
            
        end;
        
        function [] = frame(obj, positions)

            n = size(positions, 1);

            for i = 1:n
                obj.trajectories{i}(end+1, :) = positions(i, :);
            end;
            
        end;
           
        
        function [] = paint_figure(obj)

            for i = 1 : obj.count
                nx = obj.trajectories{i}(:, 1);
                ny = obj.trajectories{i}(:, 2);
                line(ny, nx, 'Color', [0 0 0.5]);
            end;

        end;
        
        function [c] = compare(obj, motion, metric)
            
            c = ones(obj.count, 1) * 0.5;
            
            for i = 1:obj.count;
                c(i) = metric(motion, obj.trajectories{i});
            end;
            
        end;
        
        function [D] = distances(obj, metric)
            
            D = zeros(obj.count);
            
            for i = 1:obj.count
                for j = 1:i
            
                	D(i, j) = metric(obj.trajectories{i}, obj.trajectories{j});
                    
                end;
            end;
            
            D = D + D';
            
        end;
        
        function [] = save(obj, file)
            trajectories = obj.trajectories; %#ok<PROP,NASGU>
            
            save(file, 'trajectories');
            
        end;
        
        function [l] = lengths(obj)
            
            l = zeros(obj.count, 1);
            
            for i = 1:obj.count
                l(i) = size(obj.trajectories{i}, 1);
            end;
            
        end;
        
        function [h] = history(obj, shift)
            
            h = nan(obj.count, 2);
            
            for i = 1:obj.count
                l = size(obj.trajectories{i}, 1);
                if (l <= shift)
                    continue;
                end;
                
                h(i, :) = obj.trajectories{i}(l - shift, :);
            end;
            
        end;
        
        function [t] = mean(obj, indices, length, weights)
            
            l = obj.lengths();

            len = min(min(l(indices)), length);
            
            t = zeros(len, 2);

            for i = indices'

               t = t + obj.trajectories{i}((l(i)-len+1):l(i), :) .* weights(i);
            end
            
            t = t ./ sum(weights(indices));  
        end;
        
    end;

end


