package org.smilkit.dom.smil
{
	import org.smilkit.w3c.dom.IDocument;
	import org.smilkit.w3c.dom.INodeList;
	import org.smilkit.w3c.dom.smil.IElementTimeContainer;
	import org.smilkit.w3c.dom.smil.ITimeList;
	
	public class ElementTimeContainer extends SMILElement implements IElementTimeContainer
	{
		protected var _beginList:ITimeList;
		protected var _endList:ITimeList;
		
		public function ElementTimeContainer(owner:IDocument, name:String)
		{
			super(owner, name);
		}
		
		public function get timeChildren():INodeList
		{
			return new ElementTimeNodeList(this);
		}
		
		public function activeChildrenAt(instant:Number):INodeList
		{
			return null;
		}
		
		public function get begin():ITimeList
		{
			if (this._beginList == null)
			{
				this._beginList = ElementTime.parseTimeAttribute(this.getAttribute("begin"), this, true);
			}
			
			return this._beginList;
		}
		
		public function set begin(begin:ITimeList):void
		{
			this._beginList = begin;
		}
		
		public function get end():ITimeList
		{
			if (this._endList == null)
			{
				this._endList = ElementTime.parseTimeAttribute(this.getAttribute("end"), this, false);
			}
			
			return this._endList;
		}
		
		public function set end(end:ITimeList):void
		{
			this._endList = end;
		}
		
		public function get dur():Number
		{
			var dur:String = this.getAttribute("dur");
			
			if (dur == null)
			{
				return 0;
			}
			
			var s:String = dur.substr(0, dur.length - 1);
			
			return new Number(s);
		}
		
		public function set dur(dur:Number):void
		{
			this.setAttribute("dur", (dur as String));
		}
		
		public function get restart():uint
		{
			return (this.getAttribute("restart") as uint);
		}
		
		public function set restart(restart:uint):void
		{
			this.setAttribute("restart", (restart as String));
		}
		
		public function get fill():uint
		{
			return (this.getAttribute("fill") as uint);
		}
		
		public function set fill(fill:uint):void
		{
			this.setAttribute("fill", (fill as String));
		}
		
		public function get repeatCount():Number
		{
			return (this.getAttribute("repeatCount") as Number);
		}
		
		public function set repeatCount(repeatCount:Number):void
		{
			this.setAttribute("repeatCount", (repeatCount as String));
		}
		
		public function get repeatDur():Number
		{
			return (this.getAttribute("repeatDur") as Number);
		}
		
		public function set repeatDur(repeatDur:Number):void
		{
			this.setAttribute("repeatDur", (repeatDur as String));
		}
		
		public function beginElement():Boolean
		{
			return false;
		}
		
		public function endElement():Boolean
		{
			return false;
		}
		
		public function pauseElement():void
		{
			// pause children
		}
		
		public function resumeElement():void
		{
			// resume children
		}
		
		public function seekElement(seekTo:Number):void
		{
			// seek children 
		}
	}
}