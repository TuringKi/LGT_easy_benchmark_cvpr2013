function [] = TrackerInitialize(bbox, file, paramin)

DefaultParameters

for i = 1:length(paramin)/2

    val = str2double(paramin{i*2});
    if isnan(val)
        val = paramin{i*2};
        eval(sprintf('parameters.%s = ''%s'';', paramin{i*2-1}, val));
    else
        eval(sprintf('parameters.%s = %f;', paramin{i*2-1}, val));
    end;
    
end;


global tracker;
global monitor;
global profiler;

profiler = Profiler();

monitor = TrackerMonitor(2);
monitor.setEnabled(0);

tracker = LGTTracker(parameters);

image = Image(file);
tracker.init(image, double(bbox));

