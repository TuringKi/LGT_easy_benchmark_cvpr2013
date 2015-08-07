classdef LGTTracker < handle

    properties
        
        parameters;
        pool;
        capacity;
        modalities;
        position;
        covariance;
        velocity;

        motion;
        
        scaling;
        
        kalman_F;
        kalman_H;
        kalman_Q;
        kalman_R;
        kalman_state;
        kalman_covariance;
    end

    methods
        function [obj] = LGTTracker(parameters)
             obj.pool = HistogramPool(6, 16);
             obj.parameters = parameters;
             obj.modalities = Modalities(obj.parameters.modalities);
             obj.kalman_F = [1 0 1 0; 0 1 0 1; 0 0 1 0; 0 0 0 1];
             obj.kalman_H = [1 0 0 0; 0 1 0 0];
        end

        function [] = init(obj, image, region)
            
            obj.scaling = 1 / mean(region(3:4) / 60);

            image = image.scale(obj.scaling);
            region = region .* obj.scaling;

            obj.pool.flush();
            obj.modalities.flush();
            
            count = round( (region(4) * region(3)) / ( (4 * obj.parameters.merge) .^ 2));
            %count = min(obj.parameters.pool.init, count);
            count = min(max(obj.parameters.pool.min, count), obj.parameters.pool.max);

            sx = floor(sqrt(count)) + 1;
            sy = ceil(sqrt(count)) + 1;

            count = sx * sy;
            
            if (region(4) < region(3))
                t = sx;
                sx = sy;
                sy = t;
            end;
            
            dx = region(3) / (sx);
            dy = region(4) / (sy);

            positions = zeros(sx * sy, 2);

            obj.kalman_R = obj.parameters.motion.measurement_noise * eye(2);
            obj.kalman_Q = obj.parameters.motion.system_noise * eye(4);

            for i = 1:sx
                for j = 1:sy
                    ox = region(1) + dx*(i-0.5);
                    oy = region(2) + dy*(j-0.5);

                    positions((i-1) * sy + j, 1:2) = [ox oy];
                end
            end

            for j = 1:count
                obj.pool.new(image, positions(j,:), 0.5);
            end;
            
            obj.velocity = [0, 0];
            obj.covariance = cov(positions(:, :));
            obj.position = mean(positions(:, :));
            obj.kalman_state = [obj.position 0 0]';
            obj.kalman_covariance = eye(4);
            
            obj.motion = obj.position;
            
            obj.capacity = obj.pool.count;
            
%             profiler = Profiler();
%             for i = 1:5 
%                 profiler.frame();
%                 obj.frame(image, 0, 0, 0, 0, profiler);
%                 
%             end
             
        end;

        
        
        % This function performs tracking every frame.
        % The parameter image represents a new image
        % The return value is a new position and velocity
        function [state] = frame(obj, image, monitor, profiler, varargin)
            % STATE VECTOR DESCRIPTION   
            % 
            % 1-2 : position
            % 3-6 : region
            % 7-8 : velocity
            % 

            image = image.scale(obj.scaling);
            
            obj.pool.move(obj.velocity);

            obj.pool.color(1:obj.pool.count, c('blue'));
            
            positions = obj.pool.positions(obj.position);

            % optimization (searching for optimal position)
            gM = obj.parameters.optimization.global_move;
            gR = obj.parameters.optimization.global_rotate;
            gS = obj.parameters.optimization.global_scale;
            iterations = obj.parameters.optimization.iterations;

            samples_min = obj.parameters.optimization.global_samples_min;
            samples_max = obj.parameters.optimization.global_samples_max;
            elite = obj.parameters.optimization.global_elite;
            
            G = [gM gM gR gS gS]' * ones(1, 5) .* eye(5);
            M = [0 0 0 1 1];

            gamma_low = 0;
            gamma_high = 0;
            
            average_samples = 0;
            
            response = zeros(samples_max, 1);
            P = zeros(samples_max, 5);
            
            for i = 1:iterations
            
                samples = samples_min;
                
                [tresponse, tP] = global_sample(image, M, G, samples, positions, obj.position, obj.pool); 

                response(1:samples, :) = tresponse;
                P(1:samples, :) = tP;
                
                while 1
                    [s, important] = sort(response(1:samples, :), 'descend');

                    if (gamma_low < s(elite) || gamma_high < s(1))
                        gamma_low = s(elite);
                        gamma_high = s(1);
                        break;

                    end;
                    
                    [tresponse, tP] = global_sample(image, M, G, 10, positions, obj.position, obj.pool); 
                    
                    response(samples+1:samples+10, :) = tresponse;
                    P(samples+1:samples+10, :) = tP;
                    samples = samples + 10;
                                        
                    
                    if (samples > 300)
                        break;
                    end;
                    
                end;
                
                average_samples = average_samples + samples;
                G = wcov(P(important(1:elite), :), response(important(1:elite)));
                M = wmean(P(important(1:elite), :), response(important(1:elite)));
                
            end;
            A = [cos(M(3)) * M(4) -sin(M(3)), M(1) + obj.position(1);
                sin(M(3)) cos(M(3)) * M(4), M(2) + obj.position(2);
                0 0 1];
            
            profiler.section('Global matching');

            positions = obj.pool.absolute(applyTransformation(positions, A));
            aprioriPositions = positions;

           % responses = obj.pool.responses(ones(obj.pool.count, 1), shiftdim(positions', -1), image);              
  
            tweights = obj.pool.weights;
            covariance = zeros(2, 2, obj.pool.count); %#ok<*PROP>
            done = false(obj.pool.count, 1);
            
            for k = 1:obj.pool.count
                covariance(:,:,k) = eye(2) .* obj.parameters.optimization.local_radius;
            end;
            if (obj.pool.count > 3)

            neighbours = cell(obj.pool.count, 1);
        
            tri = delaunay(positions(:, 2), positions(:, 1));
            edges = zeros(length(positions));

            for i = 1:size(tri, 1)

                for e = [tri(i, 1) tri(i, 2); tri(i, 2) tri(i, 3); tri(i, 3) tri(i, 1)]'
                    edges(e(1), e(2)) = i;
                    edges(e(2), e(1)) = i;
                end;

            end;

            for i = 1:obj.pool.count
                a = find(edges(i, :) ~= 0);
                if (length(a) < 3)
                   neighbours{i} = [a i];
                else
                    neighbours{i} = a;
                end
            end;
                    
            new_positions = positions;
            
            samples = obj.parameters.optimization.local_samples;

            rigidity = obj.parameters.optimization.rigidity;
            visual = obj.parameters.optimization.visual;
            
            pick = obj.parameters.optimization.local_elite;
            
            for m = 1:iterations
                
                for k = 1:obj.pool.count
                    if (done(k))
                        continue;
                    end;
                    
                    include = neighbours{i};

                    P = sample_gaussian(positions(k, 1:2), covariance(:,:, k), samples);

                    r = obj.pool.response(k, P, image);
                    values = exp( (r-1) * visual );
                    
                    
                    
                    P = P(~isinf(values), :);
                    values = values(~isinf(values));
                    
                    
                    A = waffine(aprioriPositions(include, :), positions(include, :), tweights(include)');
                  
                    tr = A * [aprioriPositions(k, :), 1]';

                    importance = values' .* exp(-point_distance(P, tr(1:2)')*rigidity) ;
                    [s, important] = sort(importance, 'descend');

                    if (s(1) == 0) % all the elite samples have importance 0
                        tweights(k) = 0.000001;
                        done(k) = 1;
                        pos = positions(k, 1:2);
                    else
                        covariance(:, :, k) = wcov(P(important(1:pick), :), importance(important(1:pick)));
                        pos = wmean(P(important(1:pick), :), importance(important(1:pick)));
                    end;

                    if (m == 1)
                        %importance(important(1:pick));
                        %covariance(:, :, k);
                    end;
                    
                    new_positions(k, :) = pos;  
                    
                end;

                positions = new_positions;

                for i = 1:obj.pool.count
                    if (det(covariance(:,:,i)) < 0.0001)
                        done(i) = 1;
                    end;
                end;

                if (done)
                    break;
                end;                         
            end;

            end;

            profiler.section('Local matching');

            responses = zeros(obj.pool.count, 1);

            for k = 1:obj.pool.count
                obj.pool.locations(k, :) = int32(positions(k, :));
                responses(k) = obj.pool.response(k, obj.pool.locations(k, :), image);           
            end;
      
            responses(isinf(responses)) = 0;
            
            newweight = exp((responses - 1) * obj.parameters.reweight.similarity);

            
            obj.pool.push();
            
            position = wmean(positions, obj.pool.weights');

            [obj.kalman_state, obj.kalman_covariance] = kalman_update(obj.kalman_F, obj.kalman_H, obj.kalman_Q, obj.kalman_R, position', obj.kalman_state, obj.kalman_covariance);

            position = obj.kalman_state(1:2)';

            obj.velocity = obj.kalman_state(3:4)';

            obj.position = position;

            obj.covariance = wcov(positions, obj.pool.weights');

            obj.motion(end+1, 1:2) = position;
                      
            profiler.skip();

            newweight = newweight .* (1 ./ (1 + exp(( median(distances(positions)) - obj.parameters.size) * obj.parameters.reweight.distance)))';

            obj.pool.weights = (obj.pool.weights + newweight') / 2;

            merge = 0;
            while (1)
                d = distances(obj.pool.positions());
                for k = 1:obj.pool.count
                    overlap = d(:, k) < obj.parameters.merge;
                    if sum(overlap) > 1
                        obj.pool.merge(image, find(overlap));
                        merge = merge + sum(overlap) - 1;
                        obj.pool.colors{end} = c('violet');
                        break;

                    end;
                end;
                if k == obj.pool.count
                    break;
                end;
            end;
            
            display(sprintf('Merging %d features', merge));
            
            profiler.section('Overlaping');
            
            % the actual removing
            
            if obj.pool.count > 3
            
                remove1 = obj.pool.weights < obj.parameters.weight.remove;

                [~, order] = sort(obj.pool.weights); 
                remove2 = zeros(size(remove1));
                remove2(order(1:3)) = 1;

                remove = remove1 & remove2;

                obj.pool.remove_all(find(remove)');

                display(sprintf('Removing %d features', sum(remove)));

            end;
            
            obj.modalities.update(image, obj.position, obj.pool, find(obj.pool.weights >= 0.5));

            profiler.section('Global update');
            
            % Reinitialization
            
            obj.modalities.mask(obj.pool.positions());

            new = min(round(obj.capacity) - obj.pool.count + 1, obj.parameters.pool.max - obj.pool.count);
            
            if (new > 0)

                npositions = obj.modalities.candidates(new);

                if (~isempty(npositions))
                    for i = 1:size(npositions, 1)
                        if (any(obj.pool.distances(npositions(i, :)) < 2))
                            continue;
                        end
                        
                        obj.pool.new(image, npositions(i, :), 0.5, 'aqua');

                    end;

                end;
                                
            end;
            
            obj.capacity = obj.parameters.pool.persistence * obj.capacity + (1-obj.parameters.pool.persistence) * obj.pool.count;
            
            profiler.section('Reinitialization');
            
            obj.modalities.debug();
       
            region = obj.pool.region(obj.pool.weights > 0);

            if (isempty(region))
                region = [0 0 0 0];
            end;
            
            state = [obj.position ./ obj.scaling, region ./ obj.scaling, obj.velocity ./ obj.scaling];
  
            profiler.skip();
            
        end

        function [positions, hull] = paintFigure(obj, ~, ~)
            
            hd = [];
            
            obj.pool.paint_figure(1 / obj.scaling);

            positions = obj.pool.positions() ./ obj.scaling;
            
            hull = convhull(positions(:, 1), positions(:, 2));


        end

        function [] = key(obj, char, frame, varargin)
   
        end;
        
        function [summary] = summarize(obj)
            
            summary = obj.pool.summarize();
            
        end;
        
    end

end

function [m] = distances(points)
    n = size(points);

    m = zeros(n(1), n(1));

    for i = 1:n
        for j = 1:i

            d = sqrt(((points(i, 1) - points(j, 1)) ^ 2) +  ((points(i, 2) - points(j, 2)) ^ 2));

            m(i, j) = d;
            m(j, i) = d;
        end;
    end;
end

function [response, P] = global_sample(image, M, G, samples, positions, position, pool)

    count = pool.count;

    P = sample_gaussian(M, G, samples);
    sampled_positions = zeros(samples, 2, count);
    
    for k = 1:samples
        A = [cos(P(k, 3)) * P(k, 4) -sin(P(k, 3)), P(k, 1) + position(1);
            sin(P(k, 3)) cos(P(k, 3)) * P(k, 4), P(k, 2) + position(2);
            0 0 1];

        sampled_positions(k, :, :) = applyTransformation(positions, A)';

    end;

    values = pool.responses(ones(count, 1), sampled_positions, image);

    response = zeros(samples, 1);

    for k = 1:samples
        response(k) = wmean(values(:, k), pool.weights');
    end;

end
