package org.smilkit.view
{
	import org.smilkit.dom.smil.SMILDocument;
	import org.smilkit.render.RenderTree;
	import org.smilkit.time.TimingGraph;

	public dynamic class ViewportObjectPool
	{
		protected var _viewport:Viewport;
		
		/**
		 * Holds the DOM - data Representation of the loaded SMIL XML 
		 */		
		protected var _document:SMILDocument;
		
		/**
		 * An instance of TimingGraph is used to store the timings of the elements that are to be displayed 
		 */
		protected var _timingGraph:TimingGraph;
		
		/**
		 *  An instance of RenderTree responsible for checking the viewports play position and for controlling the display 
		 */	
		protected var _renderTree:RenderTree;
		
		public function ViewportObjectPool(viewport:Viewport, document:SMILDocument)
		{
			this._viewport = viewport;
			this._document = document;
			
			this.reset();
		}
		
		public function get viewport():Viewport
		{
			return this._viewport;
		}

		public function get document():SMILDocument
		{
			return this._document;
		}
		
		public function get timingGraph():TimingGraph
		{
			return this._timingGraph;
		}
		
		public function get renderTree():RenderTree
		{
			return this._renderTree;
		}
		
		public function reset():void
		{
			this._timingGraph = new TimingGraph(this);
			
			// do an initial build of the timing graph
			this._timingGraph.rebuild();
			
			// make the first render tree!
			this._renderTree = new RenderTree(this);
			
			// create render tree to drawingboard
			// drawingboard is always around, and renderTree is constantly destroyed
			// and recreated, so we have to make the link.
			this.viewport.drawingBoard.renderTree = this.renderTree;
		}
	}
}