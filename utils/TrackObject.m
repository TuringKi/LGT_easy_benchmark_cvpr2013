function [trackerTruth, groundTruth, statusData, triesData] = TrackObject(path, tracker, varargin)

start = 0;
endFrame = 0;
out.frames = 0;
out.monitor = 1;
out.dst = [path, lower(class(tracker)), '/'];

fail.check = 0;
fail.limit = -1;
ui.verbose = 1;
ui.interactive = 1;
image = [];
skip = 1;
suffix = '';
retry = 0;
autostart = 0;
imagepattern = '%s%08d.jpg';

args = varargin;
for j=1:2:length(args)
    switch args{j}
        case 'start', start = args{j+1} - 1;
        case 'end', endFrame = args{j+1};
        case 'fail', fail.limit = args{j+1}; fail.check = 1;
        case 'interactive', ui.interactive = args{j+1} == 1;
        case 'verbose', ui.verbose = args{j+1};
        case 'suffix', suffix = args{j+1};
        case 'autostart', autostart= args{j+1};
        case 'outdir', out.dst = [path, args{j+1}, '/'];
        case 'out.frames', out.frames = args{j+1} == 1;
        case 'out.monitor', out.monitor = args{j+1} == 1;
        case 'out.remote', out.remote = args{j+1} == 1;
        case 'retry', retry = args{j+1};
        case 'skip', skip = args{j+1};
        case 'images', imagepattern = args{j+1};
        otherwise, error(['unrecognized argument ' args{j}]);
    end
end

global monitor

endFrame = endFrame - start;

tryNumber = 1;

groundTruth = zeros(1);
trackerTruth = zeros(1);
statusData = zeros(1);
triesData = zeros(1);

triesData(1) = tryNumber;

    function reset()
        i = 1;
        a = startPosition;
        file = imageName(i + start);
        image = Image(file);
        [height, width] = image.size();
        tracker.init(image, a);
    end

    function store()
        file = [path, sprintf('tracker%s.mat', suffix)];
        save(file, 'tracker', 'i');
        display(sprintf('State at frame %d stored to %s', i, file));
    end

    function [im] = imageName(id)
       im = sprintf(imagepattern, path, id);
    end

if (ui.verbose);
    disp('Reading annotations...');
end;
try
    annot = annotations([path, 'annotations.data']);
    startPosition = annot.get(1 + start, 2);
catch e
	fail.check = 0;
	if (ui.verbose);
	    disp('Unable to read annotations ...');
	end;
    try
        startPosition = csvread([path, 'bootstrap.csv']);
    catch e
        disp('Unable to load starting positon ...');
        file = imageName(start + 1);
        image = Image(file);
        fig = figure();
        hold on;
        imshow(image.rgb());
        r = getrect(fig);
        hold off;
        close(fig);
        startPosition = [r([2 1]), r([4 3])];
    end
end

% -----------------------------------------------------------------

tpref = iptgetpref('ImshowBorder');
iptsetpref('ImshowBorder','tight');

iptsetpref('ImshowBorder', tpref);

% -----------------------------------------------------------------

out.mdst = [out.dst, 'monitor/'];
if ~exist(out.dst, 'dir');
    mkdir(out.dst);
else
    out.monitor = out.monitor & out.frames;
end;

if out.monitor && ~exist(out.mdst, 'dir');
    mkdir(out.mdst);
end;

i = 1;

width = 0;
height = 0;

reset();

pause = ~autostart;
quit = 0;
haserror = 0;
zoom = 0;
% 
% if (ui.interactive);
%     hf = sfigure(1);
% end;


monitor = TrackerMonitor(2);
%monitor.setPause();
monitor.setEnabled(out.monitor);

profiler = Profiler();

frame = 0;

while 1;

    i = i + 1;
    frame = frame + 1;
    
    if (ui.verbose)
        display(sprintf('Frame %d', i));
    end;

    if (exist('annot', 'var'))
	    if (i * skip + start >= annot.size)
		break;
	    end;
	    
	    a = annot.get(i * skip + start, 2);
    else
	a = [0, 0, 0, 0];
    end;
    
    file = imageName(i * skip + start);
    if ~exist(file, 'file');
        break;
    end;
    image = Image(file);

    try
        profiler.frame();

        state = double(tracker.frame(image, monitor, profiler));

        if (isempty(state))
            if (ui.verbose)
                display('Tracker failed: no position returned');
            end;
            if (retry > 0) 
                tryNumber = tryNumber + 1;
                if (ui.verbose)
                    display(sprintf('Restarting: %d', tryNumber));
                end;
                tracker.init(image, a);
            else
            
                quit = 1;
            
            end;
            
        else

            if (ui.verbose)
                profiler.summary();
            end;

            posX = state(2);
            posY = state(1);

            if (exist('annot', 'var') && annot.annotation_count() > 2)
                center = annot.get(i * skip + start, 3);
            else
                center = a(1:2) + a(3:4) ./2;
            end;

            region = rectangle_shrink([a(1:2) (a(1:2) + a(3:4))], 0.75);
            region = rectangle_relocate(region, center);
            %region = [a(1:2) (a(1:2) + a(3:4))];
            %distance = sqrt(sum((state(1:2) - center) .^ 2));

            overlap = rectangle_overlap(region, state(3:6));

            groundTruth(i, 1:6) = [center region];
            trackerTruth(i, 1:6) = state(1:6);
            statusData(i, 1:(length(state)-2)) = state(3:end);

            if (ui.verbose)
                fprintf('Tracker position: (%d,%d)\nGround truth: (%d, %d)\n------\nOverlap: %.2f\n\n', ...
                    int32(trackerTruth(i, 1)), int32(trackerTruth(i, 2)), groundTruth(i, 1), groundTruth(i, 2), overlap);
            end;
            if (fail.check && fail.limit > overlap)
                if (ui.verbose)
                    display(sprintf('Tracker failed: %f < %f', fail.limit, overlap));
                end;
                if (retry > 0) 
                    tryNumber = tryNumber + 1;
                    if (ui.verbose)
                        display(sprintf('Restarting: %d', tryNumber));
                    end;
                    tracker.init(image, a);
                else

                    quit = 1;

                end;
            end;
        end;
        
        triesData(i) = tryNumber;
    catch e
        if (ui.verbose)
            display(sprintf('Failed because of an error: %s in %s:%d \n', e.message, e.stack(1).name, e.stack(1).line));

            for s = 1:length(e.stack);
                display(sprintf('\t %s:%d \n', e.stack(s).name, e.stack(s).line));
            end;

        end;
        
        if (retry > 1) 
                tryNumber = tryNumber + 1;
                if (ui.verbose)
                    display(sprintf('Restarting: %d', tryNumber));
                end;
                tracker.init(image, a);
        else
            quit = 1;
            haserror = 1;
        end;
        
    end;

    if (endFrame == i)
        quit = 1;
        if (ui.verbose)
            display('End frame reached, quitting.');
        end;
    end;
    % -----------------------------------------------------------------

    if ((ui.interactive || out.frames) && ~quit)

        magnify = 1;
        
        hf = sfigure(1);

        if (ui.interactive);
            %set(hf, 'Visible', 'true');
        else
            %set(hf, 'Visible', 'false');
        end;

        tpref = iptgetpref('ImshowBorder');
        iptsetpref('ImshowBorder','tight');

        set(hf, 'Name', sprintf('Tracker (%d)', frame), 'NumberTitle', 'off');

        windowPosition = get(hf, 'Position');
        
        set(hf, 'PaperPositionMode', 'auto', 'Toolbar', 'none', 'Position', [windowPosition(1), windowPosition(2), width * magnify, height * magnify]);

        hold off;
        imshow(image.rgb());
        hold on;

        try
            
            tracker.paintFigure(1, frame);

            plot(trackerTruth(i,2), trackerTruth(i, 1), '.g', 'MarkerSize', 15);
            
            plot(center(2), center(1), '.w', 'MarkerSize', 15);
            
            plot(trackerTruth(i, [4 4 6 6 4]), trackerTruth(i, [3 5 5 3 3]), 'g');
            plot(groundTruth(i, [4 4 6 6 4]), groundTruth(i, [3 5 5 3 3]), 'w');

%             plot(region([2, 4]), region([1 3]), 'w');
%             
%             plot(trackerTruth(i,[4, 6]), trackerTruth(i,[3 5]), 'w');
%             
        catch e
            if (ui.verbose)
                display(sprintf('Failed because of an error: %s in %s:%d \n', e.message, e.stack(1).name, e.stack(1).line));

                for s = 1:length(e.stack);
                    display(sprintf('\t %s:%d \n', e.stack(s).name, e.stack(s).line));
                end;

            end;
            %haserror = 1;
            %quit = 1;
        end;
        
        if zoom
            axis([posX - 50, posX + 50, posY - 50, posY + 50]);
        end;

        drawnow;

        if (ui.interactive && ~pause)
            c = get(hf, 'CurrentCharacter');
            if (c == 'p')
                pause = 1;
            end;
            if (c == 'q')
                quit = 1;
            end;
        end;
        if (pause)
            collectkeys = 1;
            while collectkeys
                
                try
                    k = waitforbuttonpress;
                    
                    if (k == 1)
                        c = get(hf, 'CurrentCharacter');
                        if c == 'p'
                            pause = ~pause;
                            display(sprintf('Pause is: %d', pause));
                            collectkeys = 0;
                        elseif c == 'q'
                            quit = 1;
                            collectkeys = 0;
                        elseif c == 'r'
                            reset();
                        elseif c == 'z'
                            zoom = ~zoom;
                        elseif c == 's'
                            store();
                            collectkeys = 1;
                        elseif c == 'd'
                            monitor.setEnabled(~monitor.isEnabled());
                        elseif c == 'v'
                            ui.verbose = ui.verbose + 1;
                            if (ui.verbose > 2)
                                ui.verbose = 0;
                            end;
                            fprintf('Verbosity: %d', ui.verbose);
                        elseif c == ' '
                            collectkeys = 0;
                        else
                            tracker.key(c, i, out.dst);
                        end
                        
                        
                        set(hf, 'CurrentCharacter', '?');
                    else
                        collectkeys = 0;
                    end;
                    
                catch e
                    display(e.message);
                    quit = 1;
                end;
            end;
        end

        if (out.frames)
            print( hf, '-djpeg95', '-r130', [out.dst, sprintf('%08d.jpg', frame)]);
        end;

        if (out.monitor)
            hfm = monitor.window(1);
            print(hfm, '-djpeg95', '-r90', [out.mdst, sprintf('%08d.jpg', frame)]);
        end;
        
    end;

    if (quit)
        break;
    end;

end;

if (haserror)
    error('Error. Stopping.');
end;


parameters = tracker.parameters;
parameters.skip = skip;
parameters.start = start;
parameters.fail = fail.limit;

profilerHistory = profiler.history;

statusfile = [out.dst, sprintf('status%s.mat', suffix)];
save(statusfile, 'groundTruth', 'trackerTruth', 'statusData', 'triesData', 'parameters', 'profilerHistory');


if ((ui.interactive || out.frames) && ~quit)
    iptsetpref('ImshowBorder', tpref);
end;

try

catch e
    if (ui.verbose)
        display(sprintf('Failed because of an error: %s in %s:%d \n', e.message, e.stack(1).name, e.stack(1).line));
    end;
end

if (haserror)
   error('Error encountered during execution');
end

end

function [o] = rectangle_overlap(r1, r2)

    intersection = max(0, min(r1(3), r2(3)) - max(r1(1), r2(1))) ...
        * max(0, min(r1(4), r2(4)) - max(r1(2), r2(2)));

    union = (r1(3) - r1(1)) * (r1(4) - r1(2)) + (r2(3) - r2(1)) * (r2(4) - r2(2));
    
    o = intersection / (union - intersection);

end

function [o] = rectangle_shrink(r, f)

    cx = (r(3) + r(1)) * 0.5;
    cy = (r(4) + r(2)) * 0.5;
    
    o = [ cx + (r(1) - cx) * f, cy + (r(2) - cy) * f, ...
        cx + (r(3) - cx) * f, cy + (r(4) - cy) * f];
    
end

function [o] = rectangle_relocate(r, of)

    cx = (r(3) + r(1)) * 0.5;
    cy = (r(4) + r(2)) * 0.5;
    
    o = [ of(1) + (r(1) - cx), of(2) + (r(2) - cy) , ...
        of(1) + (r(3) - cx) , of(2) + (r(4) - cy) ];
    
end
