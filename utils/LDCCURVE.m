%This datastructure holds the load duration curve.

classdef LDCCURVE
    properties
       xbegin %below begin, it will always evaluate to 1 for all inputs
       xend %above xend, it will always evaluate to 0
       poly %it stores the fitted polynomial (MATLAB cfit object)
    end
    methods
        function obj = LDCCURVE(x,y)
            obj.xbegin = min(x);
            obj.xend = max(x);
            obj.poly = fit(x(:), y(:), 'linearinterp');
        end
        
        function y = raweval(obj,x) %raw evaluation using the stored polynomial
            y = obj.poly(x);
        end
        
        function y = eval(obj,x) %intelligent evaluation based on x. For x less then xbegin, evaluate to 1
            y = x;
            y(x < obj.xbegin) = 1; %x less then xbegin, evaluate to 1
            y(x > obj.xend) = 0; %for ex greater than xend, force it to be 0
            
            %for x between xbegin and xend, evaluate using the stored
            %polynomial
            y(x>=obj.xbegin & x <= obj.xend) = obj.raweval(x(x>=obj.xbegin & x <= obj.xend));
            y(y<0) = 0;
            y(y>1) = 1;
        end
        
        function a = area(obj,intg_start,intg_end)
            a = integrate(obj.poly,intg_end,intg_start);
        end

        function obj = process(obj,capacity, prob, STEP)
            %modifies the LDC curve by calculating weighted summation
            %between its current value, and its shifted values (multiple
            %shifting possible)
            
            %The shifting levels are defined by capacity vector
            %The weights are defined by prob vector
            %The STEP is the granularity. Smaller value gives better
            %accuracy but takes longer time
            
            if length(capacity) == 1
                return
            end
            obj.xend = obj.xend+max(capacity);
            xrange = obj.xbegin:STEP:obj.xend;  
            ys = obj.eval(xrange - capacity');
            weighted_ys = ys.*prob(:);
            final_y = sum(weighted_ys);
            obj.poly = fit(xrange(:), final_y(:), 'linearinterp');
        end
        
        function plot(obj)
           x =  0:0.005:obj.xend;
           y = obj.eval(x);
           plot(x,y);
        end
    end
end