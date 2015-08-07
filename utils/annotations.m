classdef annotations
%ANNOTATIONS - Read only access to General Annotations format files.
%  The class parses annotations file and provides data in a more
%  object oriented manner. 
%  
%  Usage samples:
%   a = annotations('...')
% 
%   a.get(1, 1) 
%   a.get('image.jpg', 1)
%   a.get('image.jpg', 'car_position')
%
%   Provided under the terms of GNU General Public License 2.0
%   The development of this class is still in early phases so
%   it is probably not that user friendly. The supported version
%   of GAf is 1.0. 
%   Check http://vicos.fri.uni-lj.si/lukacu/software/annotator for
%   more details.
    properties (SetAccess='private')
        template;
        data;
        uids;
        size;
    end
    methods

        % todo: fix exploding of string for one character numbers
        
        function [a] = annotations(filename)

            fid = fopen(filename, 'r');

            version = 1;
            
            a.data = cell(0,0);
            a.uids = java.util.Hashtable();
            
            a.size = 0;
            
            a.template = cell(0);
            
            while 1
                tline = fgetl(fid);

                if (tline == -1), break, end
                
                if strcmp(tline,'ADATA') == 1, continue, end
                
                if tline(1) == '#', continue, end

                if tline(1) == '?'
                    [head, body] = decapitate(tline, ':');

                    if strcmp(head, '?version')
                        version = str2num(body);
                        continue
                    end;

                    if strcmp(head, '?template')
                        continue
                    end;

                    continue;
                end;

                [parts, num] = explode(tline, ';');

                uid = parts{1};

                if (a.findItem(uid) ~= -1)
                    continue
                end
                
                a.size = a.size + 1;
                a.uids.put(uid, a.size);
                
                a.data(a.size, 1) = {uid};
                
                for i = 2 : num-1

                    [head, body] = decapitate(parts{i}, '=');

                    if (strcmp(head, 'rect'))
                        a.data(a.size, i) = {parseRect(body)};
                        continue
                    end;
                    if (strcmp(head, 'point'))
                        a.data(a.size, i) = {parsePoint(body)};
                        continue
                    end;
                end;

            end
            fclose(fid);
        end

        function ann = get(obj, id, ida)
 
            if (isa(id, 'numeric'))
                ann = obj.data{id, ida};
            else
                idx = obj.findItem(id);
                
                if (idx == -1)
                    error('UID does not exist');
                end
                
                ann = obj.data{idx, ida};
                
            end

        end
        
        function idx = findItem(obj, uid)
           
            idx = obj.uids.get(uid);
            if (isempty(idx))
                idx = -1;
            end;
        end
        
        function count = annotation_count(obj)
            count = size(obj.data, 2);
        end;
        
        function count = item_count(obj)
            count = size(obj.data, 1);
        end;
    end

end

function [rect] = parseRect(raw)
    [parts, num] = explode(raw, ',');
    if (num < 4)
        rect = 0;
        return
    end

    rect = [str2num(parts{2}), str2num(parts{1}), str2num(parts{4}), str2num(parts{3})];

end

function [rect] = parsePoint(raw)
    [parts, num] = explode(raw, ',');
    if (num < 2)
        rect = 0;
        return
    end

    rect = [str2num(parts{2}), str2num(parts{1})];

end

function [parts, num] = explode(str, delim)
    delim = delim(1);

    m = strfind(str, delim);
    
    [a, num] = size(m);
    
    parts = cell(1);
    
    start = 1;
    count = 1;

    for i = 1 : num
        ending = m(i) - 1;

        if (start > ending)
            continue
        end;
        
        if (ending > 0 && str(ending) == '\')
            if (ending <= 1 || str(ending-1) ~= '\')
                continue;
            end;
        end;
        parts(count) = {str(start : ending)};
    
        start = m(i) + 1; 
        count = count + 1;
    end;
    
    parts(count) = {str(start : end)};
    num = count+1;

end
    
function [head, body] = decapitate(str, delim)
    delim = delim(1);

    m = strfind(str, delim);

    [a, num] = size(m);
    
    start = 1;
    
    head = '';
    
    for i = 1 : num
        ending = m(i) - 1;
                
        if (start >= ending)
            continue
        end;
        
        if (ending > 0 && str(ending) == '\')
            if (ending <= 1 || str(ending-1) ~= '\')
                continue;
            end;
        end;
        
        head = str(start : ending);
        start = m(i) + 1; 
        break;
    end;
    
    body = str(start : end);

end
