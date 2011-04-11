package org.smilkit.dom.smil
{
	import org.smilkit.w3c.dom.IDocument;
	import org.smilkit.w3c.dom.INodeList;
	import org.smilkit.w3c.dom.smil.IElementParallelTimeContainer;
	import org.smilkit.w3c.dom.smil.ITimeList;
	
	public class ElementParallelTimeContainer extends ElementTestContainer implements IElementParallelTimeContainer
	{
		public function ElementParallelTimeContainer(owner:IDocument, name:String)
		{
			super(owner, name);
		}
		
		public function get endSync():String
		{
			return null;
		}
		
		public function set endSync(endSync:String):void
		{
		}
		
		public function get implicitDuration():Number
		{
			return 0;
		}
		
		public override function get durationResolved():Boolean
		{
		    if(super.durationResolved)
		    {
		       return true;
		    }
		
            for (var i:int = (this.timeDescendants.length-1); i >= 0; i--)
            {
                if (this.timeDescendants.item(i) is ElementTimeContainer)
                {
                    if(!(this.timeDescendants.item(i) as ElementTimeContainer).durationResolved)
                    {
                          return false;
                    }
                }
            }
            return true;
		}
		
		public override function get duration():Number
		{
			var duration:Number = super.duration;
			
			if (this.hasChildNodes() && (duration == 0 && !this.hasDuration()))
			{
				var childDuration:Number = 0;
				
				for (var i:int = 0; i < this.timeDescendants.length; i++)
				{
					if (this.timeDescendants.item(i) is ElementTimeContainer)
					{
						var container:ElementTimeContainer = (this.timeDescendants.item(i) as ElementTimeContainer);
						container.resolve();
						
						if (!(container.end as TimeList).resolved)
						{
							return Time.UNRESOLVED;
						}
						
						if (container.end.first.resolvedOffset > childDuration)
						{
							childDuration = container.end.first.resolvedOffset;
						}
					}
				}
				
				if (childDuration != 0)
				{
					childDuration = (childDuration - this.begin.first.resolvedOffset);
					
					return childDuration;
				}
			}
			
			return duration;
		}
	}
}