function [r] = TrackerFrame(file)

image = Image(file);

global tracker;
global monitor;
global profiler;

state = tracker.frame(image, monitor, profiler);

r = [state(3:4), state(5:6) - state(3:4)];