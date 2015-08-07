classdef HistogramPool < handle
    
    properties
        histogram_size;
        bins;
        histograms = [];
        locations = [];
        weights = [];
        count;
        trajectories;
        colors = {};
        ids = [];
        idcounter;
    end;
    
    methods
        
        function [obj] = HistogramPool(size, bins)
            obj.histogram_size = size;
            obj.bins = bins;
            obj.count = 0;
            obj.idcounter = 0;
            obj.trajectories = MotionObserver();
        end;
        
        function [positions] = move(obj, m)            
            positions = zeros(obj.count, 2);

            for k = 1:obj.count
                obj.locations(k, :) = int32(double(obj.locations(k, :)) + double(m));
                positions(k, 1:2) = obj.locations(k, :);
            end;
            
        end;
     
        function [positions] = absolute(obj, m)
            positions = [];
            if (size(m, 1) == obj.count)
                positions = m;

                for k = 1:obj.count
                    obj.locations(k, :) = int32(double(m(k, 1:2)));
                end;
               
            end;
        end;        
        
        function [count] = new(obj, image, position, weight, color)
            
            if (nargin < 5)
                color = 'red';
            end;
            
            if (ischar(color))
                color = c(color);
            end;
            
            obj.locations(obj.count+1, :) = position;
            obj.ids(obj.count+1) = obj.idcounter;
            obj.idcounter = obj.idcounter + 1;
            
            obj.histograms(obj.count+1, :) = histassemble(uint8(image.gray()), int32([position - obj.histogram_size/2, obj.histogram_size, obj.histogram_size]), obj.bins);
            
            obj.weights(obj.count + 1) = weight;
            obj.colors{obj.count + 1} = color;
            obj.trajectories.add(position);
            
            obj.count = length(obj.ids);
            
            count = obj.count;
            
        end;
                
        function [count] = remove(obj, index)
            
            if (index > 0 && index <= obj.count)
                
                mask = true(obj.count, 1);
                
                mask(index) = 0;
                
                obj.histograms = obj.histograms(logical(mask), :); 
                obj.locations = obj.locations(logical(mask), :);
                obj.weights = obj.weights(mask);
                obj.trajectories.remove_all(index);
                obj.colors = obj.colors(mask);
                obj.ids = obj.ids(mask);
                
                obj.count = length(obj.ids);
                
            end;
            
            count = obj.count;
            
        end;
        
        function [count] = remove_all(obj, indices)
            
            indices = indices(indices > 0 & indices <= obj.count);
            
            if (~isempty(indices))
                
                mask = true(obj.count, 1);
                
                mask(indices) = 0;
                
                obj.histograms = obj.histograms(logical(mask), :); 
                obj.locations = obj.locations(logical(mask), :);
                obj.weights = obj.weights(mask);
                obj.colors = obj.colors(mask);
                obj.trajectories.remove_all(indices);
                obj.ids = obj.ids(mask);
                
                obj.count = length(obj.ids);
                
            end;
            
            count = obj.count;
            
        end;
        
        function [] = push(obj)
            
            obj.trajectories.frame(obj.locations);
            
        end;
        
        function [] = flush(obj)
            obj.locations = [];
            obj.histograms = [];
            obj.colors = {};
            obj.weights = [];
            obj.count = 0;
            obj.ids = [];
            obj.idcounter = 0;
            
            obj.trajectories.flush();
        end;
        
        function [] = paint_figure(obj, scaling)

            %obj.trajectories.paint_figure();
            
            positions = zeros(obj.count, 2);
            s = 2 * scaling;
            for i = 1 : obj.count
                nx = obj.locations(i, 1).* scaling;
                ny = obj.locations(i, 2).* scaling;
                ln = [nx-s, nx+s, nx+s, nx-s, nx-s; ny-s, ny-s, ny+s, ny+s, ny-s];
                line(ln(2,:), ln(1,:), 'Color', obj.colors{i});
                ln = [nx-s, nx-s+(2*s * obj.weights(i)); ny-s-2, ny- s-2];
                line(ln(2,:), ln(1,:), 'Color', [1 1 0]);
                positions(i, :) = [nx ny];
            end;
            
        end
        
        function [] = color(obj, indices, color, factor)
            
            for i = indices
                if (i < 1 || i > obj.count)
                    continue;
                end;
                
                if (nargin > 3)
                    obj.colors{i} = color .* factor(i);
                else
                    obj.colors{i} = color;
                end;
                
            end;
        
        end;
        
        function [positions] = positions(obj, relative)
            if (nargin < 2)
                relative = [0 0];
            end;
            
            positions = zeros(obj.count, 2);
            for i = 1 : obj.count
                nx = obj.locations(i, 1) - relative(1);
                ny = obj.locations(i, 2) - relative(2);
                positions(i, :) = [nx ny];
            end;
        end;
        
        function [] = change_weights(obj, mask, modifier)
            
            obj.weights(mask) = min(max(obj.weights(mask) + modifier, 0), 1);

        end;
        
        function [] = multiply_weights(obj, mask, modifier)
            
            obj.weights(mask) = min(max(obj.weights(mask) .* modifier, 0), 1);

        end;
        
        function [aa, ma, mina, maxa] = age(obj)

            lengths = obj.trajectories.lengths();
            
            aa = mean(lengths);
            ma = median(lengths);
            mina = min(lengths);
            maxa = max(lengths);
        end;
        
        function [d] = distances(obj, origin)
            d = zeros(obj.count, 1);
            for i = 1 : obj.count

                d(i) = sqrt(sum((double(obj.locations(i, :)) - origin) .^ 2));
            end 
            
        end
        
        function [position] = merge(obj, image, indices)
            
            indices = indices(indices > 0 & indices <= obj.count);

            if (length(indices) > 1)
                
                mask = false(obj.count, 1);
                
                mask(indices) = 1;
                
                tweights = obj.weights(mask);
                tlocations = obj.locations(logical(mask), :);
                
                weight = max(tweights);
                
                position = [0 0];
            
                for i = 1:length(indices);
                    position = position + tweights(i) * double(tlocations(i, :));

                end;   
                
                position = position / sum(tweights);

                obj.remove_all(indices);
                
                obj.new(image, position, weight);
                
                obj.count = length(obj.ids);
                
            else
                position = [];
                
            end;

        end;
        
        function [summary] = summarize(obj)
            
            summary = zeros(obj.count, 4);
            
            for i = 1:obj.count
                summary(i, 1) = obj.ids(i);
                summary(i, 2:3) = double(obj.locations(i, :));
                summary(i, 4) = obj.weights(i);
            end;
   
        end;
        
        function [reg] = region(obj, mask)
            p = obj.positions();
            reg = [min(p(mask, 1)), min(p(mask, 2)), max(p(mask, 1)), max(p(mask, 2))];
            
        end;
        
        function [resp] = response(obj, index, positions, image)
            
            l = size(positions,1);
            p = int32([positions(:,1) - obj.histogram_size/2, positions(:,2) - obj.histogram_size/2, ones(l,2) * obj.histogram_size, ]);
            
            resp = histcompare(uint8(image.gray()), obj.histograms(index, :), p, obj.bins);
            
        end;
        
        function [resp] = responses(obj, indices, positions, image)
            indices = logical(indices);
            l = size(positions,1);
            p = positions - obj.histogram_size/2;
            p(:, 3:4, :) = ones(l,2,size(positions,3)) * obj.histogram_size;
            resp = histcompare(uint8(image.gray()), obj.histograms(indices, :), int32(p), obj.bins);

        end;
    end;

end