classdef ConfigurationTree < handle
    properties
        pStore % 2-d matrix. Row = configurations. Row 1= root. Columns = Number of candidate gerators for that configuration
        indexMap %Keys = string representation of configuraton + year, values = index of that configuration in pStore
        yearlyConfigurationsMap %Keys = year, values = list of indices of configurations in pStore for that year
        connections %sparse matrix to represent parent-to-child relationship. Row = parent, column = child
        
        lolpStore % 2-d matrix. Row = configuration index (corresponding to pStore). Columns = different periods. Values are LOLP
        eensStore % similar to lolpStore, but stores the equivalent energy not served
        
        totalYears %int 
        totalCandiGenerators %int
        startingYear %
        endingYear
    end
    methods (Access = public)
        function obj = ConfigurationTree(studyYear,totalCandiGenerators)         
            totalYears = length(studyYear);
            obj.pStore = [];
            obj.lolpStore = [];
            obj.eensStore = [];
            
            obj.indexMap = containers.Map();
            obj.yearlyConfigurationsMap = containers.Map();
            obj.connections = sparse(100,100); % initialize
            obj.totalYears = totalYears;
            obj.startingYear = studyYear(1);
            obj.endingYear = studyYear(end);
            obj.totalCandiGenerators = totalCandiGenerators;
            
            %initialize pStore with all zeros as the root for the
            %firstYear-1
            obj.pStore = zeros(1,totalCandiGenerators);
            obj.yearlyConfigurationsMap(num2str(studyYear(1)-1)) = 1;
        end
        
        function obj = addConfiguration(obj,year,parentIndex,configuration)
            configurationWithYear = [configuration year]; %add the year to make configuration unique among different years
            configstr = num2str(configurationWithYear);
            
            if obj.indexMap.isKey(configstr)
                indexOfConfiguration = obj.indexMap(configstr);
            else
                obj.pStore = [obj.pStore; configuration];
                indexOfConfiguration = size(obj.pStore,1); %get the total row i.e. index of last entry
                obj.indexMap(configstr) = indexOfConfiguration;
                if obj.yearlyConfigurationsMap.isKey(num2str(year))
                    obj.yearlyConfigurationsMap(num2str(year)) = [obj.yearlyConfigurationsMap(num2str(year)),indexOfConfiguration];
                else
                    obj.yearlyConfigurationsMap(num2str(year)) = indexOfConfiguration;
                end
            end
            
            obj.addChild(parentIndex,indexOfConfiguration)      
        end
        
        function obj = addConfigurationList(obj,year,parentIndex,configurationList)           
            for row = 1:size(configurationList, 1)
                obj.addConfiguration(year, parentIndex, configurationList(row,:));
            end        
        end
        
        function obj = trimTree(obj)
            %remove nodes that are unreachable from the bottom
            fprintf('Total edges before trimming: %d \n', full(sum(sum(obj.connections))));
            for year = (obj.endingYear-1):-1:obj.startingYear
               nodes = obj.yearlyConfigurationsMap(num2str(year));
               %A node is childless if it doesn't have any connections,
               %i.e. sum of all connections is zero
               childless_nodes_index = sum(obj.connections(nodes,:),2) == 0;
               childless_nodes = nodes(childless_nodes_index);
               %remove incoming connections to childless nodes
               obj.connections(:,childless_nodes) = 0;             
            end
            fprintf('Total edges after trimming: %d \n', full(sum(sum(obj.connections))));
        end
        
        function obj = calculateAllLOLP(obj,system_info)
            tic
            for year = obj.endingYear:-1:obj.startingYear
                fprintf('Calculating LOLP for year: %d\n',year);
                nodes = obj.yearlyConfigurationsMap(num2str(year));
                fprintf('There are %d nodes in this year\n',length(nodes));
                h = waitbar(0,sprintf('Year %d',year));
                for i = 1:length(nodes)
                   waitbar(i/length(nodes));
                   index = nodes(i);
                   configuration = obj.pStore(index,:);
                   [lolp,eens] = calculateLOLP(system_info,year,configuration);
                    obj.lolpStore(index,:) = lolp;
                    obj.eensStore(index,:) = eens;
                end
                try
                    close(h)
                catch
                    fprintf('Thank you for closing!')
                end
            end
            toc
        end
        
        function disp(obj)
            %function used by matlab to print out the data structure in the
            %console
            fprintf('pStore size: %d, %d\n',size(obj.pStore));
            display('Indexmap');
            obj.displayMap(obj.indexMap);
            display('yearlyConfigurationsMap')
            obj.displayMap(obj.yearlyConfigurationsMap);
            fprintf('connections size: %d, %d \n', size(obj.connections));
            fprintf('Number of connections: %d \n', full(sum(sum(obj.connections))));

        end
        
    end
    methods (Access = protected)
        function addChild(obj,parentIndex,childIndex)
            current_size = size(obj.connections,1);
            if childIndex > current_size %matrix needs expanding
                new_size = current_size*2;
                fprintf('Expanding sparse connection matrix to %d size', new_size);
                temp_connections = sparse(new_size,new_size);
                temp_connections(1:current_size,1:current_size) = obj.connections;
                obj.connections = temp_connections;
            end
            obj.connections(parentIndex,childIndex)=1;
        end
        
        function displayMap(obj,map)
            keys = map.keys;
            for i = 1:map.Count
                fprintf(' |%s: %s| ',keys{i},mat2str(map(keys{i})));
            end
            fprintf('\n')
        end
    end
end
        
