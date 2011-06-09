package it.ht.rcs.console.model
{
  
  import flash.utils.getQualifiedClassName;
  
  import it.ht.rcs.console.events.AccountEvent;
  import it.ht.rcs.console.events.RefreshEvent;
  
  import mx.collections.ArrayList;
  import mx.collections.ISort;
  import mx.collections.ListCollectionView;
  import mx.collections.Sort;
  import mx.collections.SortField;
  import mx.core.FlexGlobals;
  import mx.events.CollectionEvent;
  import mx.events.CollectionEventKind;
  
  public class Manager
  {
    
    [Bindable]
    protected var _items:ArrayList = new ArrayList();
    
    protected var _classname:String;
    
    public function Manager()
    {
      _classname = flash.utils.getQualifiedClassName(this).split('::')[1];
      trace(_classname + ' -- Init');
      
      FlexGlobals.topLevelApplication.addEventListener(AccountEvent.LOGGING_IN, onLoggingIn);
      FlexGlobals.topLevelApplication.addEventListener(AccountEvent.LOGGING_OUT, onLoggingOut);
      FlexGlobals.topLevelApplication.addEventListener(AccountEvent.FORCE_LOG_OUT, onForceLogOut);
      
      /* detect changes on the list */
      _items.addEventListener(CollectionEvent.COLLECTION_CHANGE, onItemsChange);
    }
    
    protected function onLoggingIn(e:AccountEvent):void
    {
      trace(_classname + ' (super) -- Logging In');
    }
    
    protected function onLoggingOut(e:AccountEvent):void
    {
      trace(_classname + ' (super) -- Logging Out');
    }
    
    protected function onForceLogOut(e:AccountEvent):void
    {
      trace(_classname + ' (super) -- Force Log Out');
      _items.removeAll();
    }
    
    public function start():void
    {
      trace(_classname + ' (super) -- Start');
      /* react to the global refresh event */
      FlexGlobals.topLevelApplication.addEventListener(RefreshEvent.REFRESH, onRefresh);
      /* always get new data upon startup */
      onRefresh(null);
    }
    
    public function stop():void
    {
      trace(_classname + ' (super) -- Stop');
      /* after stop, we don't want to refresh anymore */
      FlexGlobals.topLevelApplication.removeEventListener(RefreshEvent.REFRESH, onRefresh);
    }

    protected function onRefresh(e:RefreshEvent):void
    {
      trace(_classname + ' (super) -- Refresh');
      /* get the new items from the DB, override this function */
    }
    
    protected function onItemsChange(event:CollectionEvent):void
    {
      
      /* all the logic to the db is here, override this method */
      switch (event.kind) {
        case CollectionEventKind.ADD:
          event.items.forEach(function _(element:*, index:int, arr:Array):void {
            onItemAdd(element);
          });
          break;
        
        case CollectionEventKind.REMOVE:
          event.items.forEach(function _(element:*, index:int, arr:Array):void {
            onItemRemove(element);
          });
          break;
        
        case CollectionEventKind.UPDATE:
          event.items.forEach(function _(element:*, index:int, arr:Array):void {
            onItemUpdate(element);
          });
          break;
        
        case CollectionEventKind.RESET:
          onReset();
          break;
      }
      
    }
    
    /* SPECIALIZE THIS: to specialize the type of object returned  */
    public function newItem():Object
    {
      var obj:Object = new Object();
      _items.addItem(obj);
      return obj;
    }
    
    public function addItem(o:Object):void
    {
      _items.addItem(o);
    }
    
    protected function onItemAdd(o:*):void
    {
    }
    
    public function removeItem(o:Object):void
    {
      _items.removeItem(o);
    }

    protected function onItemRemove(o:*):void
    { 
    }

    protected function onItemUpdate(event:*):void
    { 
    }
    
    protected function onReset():void
    {
    }
    
    public function getItem(_id:String):*
    {
      var idx:int;
      /* search for the item with _id and return it */
      for (idx = 0; idx < _items.length; idx++) {
        var elem:* = _items.getItemAt(idx);
        if (elem._id == _id)
          return elem;
      }
      return null;
    }
    
    public function getView(sortCriteria:ISort=null, filterFunction:Function=null):ListCollectionView
    {
      /* always return updated content when something requests a view */
      onRefresh(null);
      
      /* create the view for the caller */
      var lcv:ListCollectionView = new ListCollectionView();
      lcv.list = _items;
      
      if (sortCriteria == null) {
        /* default sorting is alphabetical */
        var sort:Sort = new Sort();
        sort.fields = [new SortField('name', true, false, false)];
        lcv.sort = sort;
      } else {
        lcv.sort = sortCriteria;
      }
      
      lcv.filterFunction = filterFunction;
      lcv.refresh();
      
      return lcv;
    }
    
  }
  
}