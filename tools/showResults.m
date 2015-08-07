%% showResults: function description
function [out_figs] = showResults(figs, im_o, res, frame, tracker)
	%rect_position = [bb([1 2]) - bb([3 4])/2 ,bb([3 4])];
    out_figs = figs;
% 	if isempty(out_figs)
        sfigure(1);
        set(gcf,'DoubleBuffer','on','MenuBar','none');
        %tracker.paintFigure(1, frame);
       
        out_figs.im_handle = imshow(im_o, 'Border','tight','initialmagnification','fit');
        hold on;
        [positions, hull] = tracker.paintFigure();
        out_figs.tracker_handle = plot(positions(hull, 2), positions(hull, 1), 'LineWidth',2,'Color',[1 0 0]);
        out_figs.center_handle = plot(res(2), res(1), '.r', 'MarkerSize', 15);
        out_figs.regin_handle = plot(res([4 4 6 6 4]), res([3 5 5 3 3]), 'r', 'LineWidth',4);
        hold off;
        %out_figs.rect_handle = rectangle('Position',rect_position, 'EdgeColor','r', 'LineWidth',3);
        out_figs.frame_handle = text(20,20,num2str(frame),'Color','b', 'FontSize',14); 
%     else 
%          
%         set(out_figs.im_handle, 'CData', im_o);
%         %hold on;
%         [positions, hull] = tracker.paintFigure();
%         set( out_figs.tracker_handle, 'X', positions(hull, 2), 'Y', positions(hull, 1));
%         set( out_figs.center_handle, 'X', res(2), 'Y', res(1));
%         set(out_figs.regin_handle, 'X', res([4 4 6 6 4]), 'Y', res([3 5 5 3 3]));
%          %hold off;
% 		
%         set(out_figs.frame_handle,'String',num2str(frame));
% 		%set(out_figs.rect_handle, 'Position', rect_position);
% 	end
	drawnow
end
