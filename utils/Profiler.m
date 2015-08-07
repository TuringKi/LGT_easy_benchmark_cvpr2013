classdef Profiler < handle
    
    properties
        
        currentTime;
        
        sections;
        
        history;
        
        currentframe;
        
    end;
    
    methods
        
        function [obj] = Profiler()
            obj.currentTime = cputime();
            obj.sections = {};
            obj.history = [];
            obj.currentframe = 0;
        end;
        
        function [] = summary(obj)
            
            len = length(obj.sections);
            
            if (len > 0)
                total = 0;
                display(sprintf('\n *** Profiling summary *** \n'));
                for i = 1:2:len
                    total = total + obj.sections{i+1};
                    if (isempty(obj.sections{i}))
                        continue;
                    end;
                    display(sprintf('\t%s - %.3fs (%.3fs)',obj.sections{i}, total, obj.sections{i+1}));
                end;
                display(sprintf('\n *** Total time: %.3fs *** \n', total));
            end;
            
            
        end;
        
        function [] = reset(obj)
            obj.currentTime = cputime();
            obj.sections = {};
            obj.history = [];
            obj.currentframe = 0;
        end;

        function [] = frame(obj)
            
            obj.currentframe = obj.currentframe + 1;
            len = length(obj.sections);
            for i = 1:2:len
                obj.history(obj.currentframe, (i+1)/2) = obj.sections{i+1};
            end;
            
            obj.currentTime = cputime();
            obj.sections = {};
            
            
            
        end;
        
        function [] = section(obj, name)
            
             obj.sections{end+1} = name;
             t = cputime();
             obj.sections{end+1} = t - obj.currentTime;
             obj.currentTime = t;
        end;
        
        function [] = skip(obj)
            
             obj.sections{end+1} = '';
             t = cputime();
             obj.sections{end+1} = t - obj.currentTime;
             obj.currentTime = t;
        end;
    end;
    
    
end