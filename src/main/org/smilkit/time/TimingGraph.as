package org.smilkit.time
{
	import flash.events.EventDispatcher;
	
	import org.smilkit.dom.events.EventListener;
	import org.smilkit.dom.events.MutationEvent;
	import org.smilkit.dom.smil.SMILDocument;
	import org.smilkit.dom.smil.SMILMediaElement;
	import org.smilkit.dom.smil.Time;
	import org.smilkit.dom.smil.TimeList;
	import org.smilkit.events.TimingGraphEvent;
	import org.smilkit.w3c.dom.INode;
	import org.smilkit.w3c.dom.INodeList;
	import org.smilkit.w3c.dom.smil.ISMILDocument;
	import org.smilkit.w3c.dom.smil.ISMILMediaElement;

	/**
	 * An instance of TimingGraph is used to store the timings of the elements that are to be displayed
	 * 
	 * The TimingGraph listens for changes in the ISMILDocument that is past to it and rebuilds itself should the ISMILdocument change
	 * 
	 */	
	public class TimingGraph extends EventDispatcher
	{
		protected var _elements:Vector.<TimingNode>;
		protected var _document:SMILDocument;
		
		protected var _eventListener:EventListener;
		
		/**
		 * Create the instance of the _element, and stores the reference to ISMILdocument in _document
		 * Adds listeners to _document to listener for MutationEvents.
		 * 
		 * @param document
		 * @constructor
		 */		
		public function TimingGraph(document:ISMILDocument)
		{
			this._elements = new Vector.<TimingNode>();
			this._document = document as SMILDocument;
			
			this._eventListener = new EventListener(this.onMutationEvent);
			
			this._document.addEventListener(MutationEvent.DOM_ATTR_MODIFIED, this._eventListener, false);
			this._document.addEventListener(MutationEvent.DOM_CHARACTER_DATA_MODIFIED, this._eventListener, false);
			this._document.addEventListener(MutationEvent.DOM_NODE_INSERTED, this._eventListener, false);
			this._document.addEventListener(MutationEvent.DOM_NODE_INSERTED_INTO_DOCUMENT, this._eventListener, false);
			this._document.addEventListener(MutationEvent.DOM_NODE_REMOVED, this._eventListener, false);
			this._document.addEventListener(MutationEvent.DOM_NODE_REMOVED_FROM_DOCUMENT, this._eventListener, false);
			this._document.addEventListener(MutationEvent.DOM_SUBTREE_MODIFIED, this._eventListener, false);
		}
		
		public function get elements():Vector.<TimingNode>
		{
			return this._elements;
		}
		
		public function get document():ISMILDocument
		{
			return this._document;
		}
		
		/**
		 * Public function used to rebuild the list of ResolvedTimeElements 
		 */		
		public function rebuild():void
		{
			// only go from the body, no point running through the other parts of a smil document
			this.iterateTree(this._document.getElementsByTagName("body").item(0) as INode);
			this.dispatchEvent(new TimingGraphEvent(TimingGraphEvent.REBUILD));
		}
		
		/**
		 * Recursive function used to parse ISMILdocument creating a list of value objects of ResolvedTimeElements 
		 * @param node
		 * 
		 */		
		protected function iterateTree(node:INode):void
		{
			var nodes:INodeList = node.childNodes;
			
			for (var i:int = 0; i < nodes.length; i++)
			{
				var child:INode = nodes.item(i);
				
				if (child is ISMILMediaElement)
				{
					var el:SMILMediaElement = (child as SMILMediaElement);
					
					// or maybe we resolve everytime incase it needs to change?
					if (!el.resolved)
					{
						el.resolve();
					}
					
					var begin:int = Time.UNRESOLVED;
					var end:int = Time.UNRESOLVED;
					
					if ((el.begin as TimeList).resolved)
					{
						begin = el.begin.first.resolvedOffset;
					}
					
					if ((el.end as TimeList).resolved)
					{
						end = el.end.first.resolvedOffset;
					}
					
					var timeElement:TimingNode = new TimingNode(el, begin, end);
					
					this._elements.push(timeElement);
					
					this.dispatchEvent(new TimingGraphEvent(TimingGraphEvent.ELEMENT_ADDED));
				}
				
				if (child.hasChildNodes())
				{
					this.iterateTree(child);
				}
			}
		}
		
		/**
		 * Called when the document dispatches the MutationEvents for which the listeners are added in the contructor
		 * @param e
		 * 
		 */		
		protected function onMutationEvent(e:MutationEvent):void
		{
			this.rebuild();
		}
	}
}