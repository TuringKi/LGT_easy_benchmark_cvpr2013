function results = run_LGT(seq, res_path, bSaveImage)
    close all;
	
	VISUAL_CHACKING = 1;
    rand(0);randn(0);
	%%for evaluation:
	duration = 0;
	fps =0;
	res = [];
    
    if VISUAL_CHACKING
        VISUAL_FIG = [];
    end
    
	img_files = seq.s_frames;
	rect=seq.init_rect;
	pos = [rect(2)+rect(4)/2,rect(1)+rect(3)/2];
	target_sz = [rect(4),rect(3)];


	init_bb = [rect([2 1]),rect([4 3])];
	bb = init_bb;
    
	end_frame = length(img_files);
    %end_frame = 20;
    
    
    DefaultParameters;
    
    %construct the tracker
    tracker = LGTTracker(parameters);
    profiler = Profiler();
    monitor = TrackerMonitor(2);
    monitor.setEnabled(1);
    
	for K = 1:end_frame
        file = seq.s_frames{K};
        if ~exist(file, 'file')
            display( sprintf('Can not find the file: %s', file));
        end
        image = Image(file);
		
        tic;
    
        %%tracking code here
        
        
        if K == 1
            tracker.init(image, init_bb);
        end
        
        %profiler.frame();

        state = double(tracker.frame(image, monitor, profiler));

        
        
        
        if VISUAL_CHACKING
            VISUAL_FIG = showResults(VISUAL_FIG,image.rgb(),state, K, tracker);
        end

		duration = duration + toc;
		ev_bb = init_bb;
		res = [res;ev_bb(1,1:2) - ev_bb(1,3:4)/2,ev_bb(1,3:4)];
 
		if(bSaveImage)
			frame_img = frame2im(getframe(VISUAL_FIG.fig_handle));
            
			savedPath = sprintf('%s%04d.jpg',res_path,frame);
			imwrite(frame_img, savedPath);	
		end
    end
	results.res=res;
	results.type='rect';
	results.fps=seq.len/duration;
	disp(['fps: ' num2str(results.fps)])

end

