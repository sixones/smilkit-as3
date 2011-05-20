package org.smilkit.dom.smil
{
	import com.hurlant.util.asn1.parser.nulll;
	
	import mx.effects.easing.Back;
	
	import org.smilkit.SMILKit;
	import org.smilkit.dom.events.MutationEvent;
	import org.smilkit.dom.smil.events.SMILMutationEvent;
	import org.smilkit.dom.smil.expressions.SMILReferenceExpressionParser;
	import org.smilkit.dom.smil.expressions.SMILTimeExpressionParser;
	import org.smilkit.parsers.SMILTimeParser;
	import org.smilkit.w3c.dom.IDocument;
	import org.smilkit.w3c.dom.INode;
	import org.smilkit.w3c.dom.INodeList;
	import org.smilkit.w3c.dom.smil.IElementTimeContainer;
	import org.smilkit.w3c.dom.smil.ITimeList;
	import org.utilkit.logger.Logger;
	
	public class ElementTimeContainer extends SMILElement implements IElementTimeContainer
	{
		public static const PLAYBACK_STATE_PAUSED:uint = 0;
		public static const PLAYBACK_STATE_PLAYING:uint = 1;
		public static const PLAYBACK_STATE_SEEKING:uint = 2;
		
		protected var _implicitMediaDuration:Time = null;
		
		protected var _beginList:TimeList = null;
		protected var _endList:TimeList = null;
		
		protected var _currentBeginInterval:Time = null;
		protected var _currentEndInterval:Time = null;
		
		protected var _previousBeginInterval:Time = null;
		protected var _previousEndInterval:Time = null;
		
		protected var _isPlaying:Boolean = false;
		
		protected var _activeDuration:Time = null;
		
		protected var _activatedAt:Number = Time.UNRESOLVED;
		protected var _deactivatedAt:Number = Time.UNRESOLVED;
		
		protected var _beginDependencies:Vector.<ElementTimeContainer>;
		protected var _endDependencies:Vector.<ElementTimeContainer>;
		
		protected var _playbackState:uint = ElementTimeContainer.PLAYBACK_STATE_PLAYING;
		
		public function ElementTimeContainer(owner:IDocument, name:String)
		{
			super(owner, name);
			
			this._beginDependencies = new Vector.<ElementTimeContainer>();
			this._endDependencies = new Vector.<ElementTimeContainer>();
		}
		
		public function get currentBeginInterval():Time
		{
			return this._currentBeginInterval;
		}
		
		public function get currentEndInterval():Time
		{
			return this._currentEndInterval;
		}
		
		public function get previousBeginInterval():Time
		{
			return this._previousBeginInterval;
		}
		
		public function get previousEndInterval():Time
		{
			return this._previousEndInterval;
		}
		
		public function get timeChildren():INodeList
		{
			return new ElementTimeNodeList(this);
		}
		
		public function get timeDescendants():INodeList
		{
			return new ElementTimeDescendantNodeList(this);
		}
		
		public function activeChildrenAt(instant:Number):INodeList
		{
			return null;
		}
		
		public function get playbackState():uint
		{
			return this._playbackState;
		}
		
		public function get begin():ITimeList
		{
			return this.beginList;
		}
		
		public function get beginList():TimeList
		{
			if (this._beginList == null)
			{
				var tokenString:String = this.getAttribute("begin");
				
				if (tokenString == null || tokenString == "")
				{
					tokenString = "0ms";
				}
				
				this._beginList = new TimeList(this, true, tokenString);
			}
			
			return this._beginList;
		}
		
		public function set begin(begin:ITimeList):void
		{
			
		}
		
		public function get end():ITimeList
		{
			return this.endList;
		}
		
		public function set end(end:ITimeList):void
		{
			
		}
		
		public function get endList():TimeList
		{
			if (this._endList == null)
			{
				this._endList = new TimeList(this, false, this.getAttribute("end"));
			}
			
			return this._endList;
		}
		
		public function get dur():String
		{
			return this.getAttribute("dur");
		}
		
		// need:
		// implicitDuration -> media duration
		// simpleDuration -> defined duration
		// activeDuration -> time to keep the asset playing
		// renderedDuration -> time to keep the asset on the stage
		
		public function get duration():Number
		{		
			// we havent decided on a duration yet so we use the smil default
			return Time.MEDIA;
			
			/*if (this._durationParser == null)
			{
				this._durationParser = new SMILTimeParser(this, this.getAttribute("dur"));
			}
			
			if (this._durationParser.timeString != this.getAttribute("dur"))
			{
				this._durationParser.parse(this.getAttribute("dur"));
			}
			
			return this._durationParser.milliseconds;*/
		}
		
		/**
		* Indicates whether the current duration on this time container may be considered resolved.
		* Since SMILKit's media handlers actually write a duration to their parent nodes when resolving
		* assets with implicit durations, for most elements this simply means determining if a duration
		* has been set on the node. See ElementSequentialTimeContainer and ElementParallelTimeContainer for
		* more complex implementations.
		*
		* @see org.smilkit.dom.smil.ElementSequentialTimeContainer
		* @see org.smilkit.dom.smil.ElementParallelTimeContainer
		*/
		public function get durationResolved():Boolean
		{
            if (this.hasAttribute("dur"))
			{
				return (this.duration != Time.UNRESOLVED);
			}
			
			return false;
		}
		
		public function set dur(dur:String):void
		{
			this.setAttribute("dur", dur.toString());
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
		
		/**
		* Determine if this element has a duration based on attributes alone.
		*/
		public function hasDuration():Boolean
		{
			return (this.hasAttribute("dur") || this.hasAttribute("end") || this.hasAttribute("endsync"));
		}
		
		/**
		 * Checks up the tree of parents and determines if this element is limited by the duration.
		 */
		public function hasDurationRestriction():Boolean
		{
			if (this.hasDuration())
			{
				return true;
			}
			
			var parent:IElementTimeContainer = this.parentTimeContainer;
			
			if (parent is SMILDocument)
			{
				return false;
			}
			
			var container:ElementTimeContainer = (parent as ElementTimeContainer);
			
			return container.hasDurationRestriction();
		}
		
		public function get durationRestriction():Number
		{
			if (this.hasDurationRestriction())
			{
				if (this.hasDuration())
				{
					return this.duration;
				}
				
				var parent:IElementTimeContainer = this.parentTimeContainer;
				var container:ElementTimeContainer = (parent as ElementTimeContainer);
				
				return container.durationRestriction;
			}
			
			return Number.NaN;
		}
		
		public function get parentTimeContainer():IElementTimeContainer
		{
			// our parent time container is the body rather than the document
			if (this.nodeName == "body")
			{
				return this;
			}
			
			var parent:IElementTimeContainer = null;
			var element:INode = this;
			var i:int = 0;
			
			while (parent == null)
			{
				if (element.parentNode != null && element.parentNode is IElementTimeContainer)
				{
					parent = (element.parentNode as IElementTimeContainer);
					break;
				}
				
				element = element.parentNode;
				
				if (i == 20)
				{
					SMILKit.logger.debug("OhKnow! Tried to find a parent ElementTimeContainer but ran up 20 stacks and couldnt find anything.");
				}
				
				i++;
			}
			
			return parent;
		}
		
		public function beginElement():Boolean
		{
			// should be making a begin time at the current offset
			
			(this.ownerDocument as SMILDocument).eventStack.triggerEvent(this, SMILEventStack.SMILELEMENT_BEGIN);
			
			return true;
		}
		
		public function endElement():Boolean
		{
			(this.ownerDocument as SMILDocument).eventStack.triggerEvent(this, SMILEventStack.SMILELEMENT_END);
				
			return true;
		}
		
		public function pauseElement():void
		{
			var previousState:uint = this._playbackState;
			
			// pause children
			if (this.hasChildNodes())
			{
				for (var i:int = 0; i < this.timeDescendants.length; i++)
				{
					if (this.timeDescendants.item(i) is ElementTimeContainer)
					{
						(this.timeDescendants.item(i) as ElementTimeContainer).pauseElement();
					}
				}
			}
			
			this._playbackState = ElementTimeContainer.PLAYBACK_STATE_PAUSED;
			
			var event:SMILMutationEvent = new SMILMutationEvent();
			event.initMutationEvent(SMILMutationEvent.DOM_PLAYBACK_STATE_MODIFIED, true, false, (this as INode), previousState.toString(), this._playbackState.toString(), "playback_state", 1);
		
			this.ownerDocument.dispatchEvent(event);
		}
		
		public function resumeElement():void
		{
			var previousState:uint = this._playbackState;
			
			// resume children
			if (this.hasChildNodes())
			{
				for (var i:int = 0; i < this.timeDescendants.length; i++)
				{
					if (this.timeDescendants.item(i) is ElementTimeContainer)
					{
						(this.timeDescendants.item(i) as ElementTimeContainer).resumeElement();
					}
				}
			}
			
			this._playbackState = ElementTimeContainer.PLAYBACK_STATE_PLAYING;
			
			var event:SMILMutationEvent = new SMILMutationEvent();
			event.initMutationEvent(SMILMutationEvent.DOM_PLAYBACK_STATE_MODIFIED, true, false, (this as INode), previousState.toString(), this._playbackState.toString(), "playback_state", 1);
		
			this.ownerDocument.dispatchEvent(event);
		}
		
		public function seekElement(seekTo:Number):void
		{
			// seek children
			
			// for syncBehaviour support
			
			// set a seek flag
			// timing graph or render tree picks up on the flag and performs the seek
			// seek flag is removed
		}

		
		
		
		
		
		public function computeImplicitDuration():Time
		{
			return this._implicitMediaDuration;
		}
		
		public function set implicitMediaDuration(time:Time):void
		{
			this._implicitMediaDuration = time;
			
			this.resetElementState();
			this.startup(true);
		}
		
		public function resetElementState():void
		{
			this._currentBeginInterval = null;
			this._currentEndInterval = null;
		}
		
		/**
		 * Intermediate Active Duration Computation
		 * 
		 * @see http://www.w3.org/TR/SMIL3/smil-timing.html#q84
		 */
		public function computeSimpleDurationTime():Time
		{
			var dur:Time = new Time(this, false, this.dur);
			
			if (dur.resolvedOffset < 0)
			{
				dur = null;
			}
			
			if (dur == null && this.endList.isDefined)
			{
				return new Time(this, false, "indefinite");
			}
			
			var implicitDuration:Time = this.computeImplicitDuration();
			if (dur == null && implicitDuration != null && implicitDuration.resolved)
			{
				return implicitDuration;
			}
			
			if (dur == null)
			{
				return new Time(this, false, "unresolved");
			}
			
			if (dur.indefinite)
			{
				return new Time(this, false, "indefinite");
			}
			
			if (dur.resolved)
			{
				return dur;
			}
			
			return new Time(this, false, "unresolved");
		}
		
		/**
		 * Intermediate Active Duration Computation
		 * 
		 * @see http://www.w3.org/TR/SMIL3/smil-timing.html#q84
		 */
		public function computeIntermediateDurationTime(simpleDurationTime:Time):Time
		{
			var p0:Time = simpleDurationTime;
			var p1:Time = new Time(this, false, "indefinite"); // repeat count
			var p2:Time = new Time(this, false, "indefinite"); // repeat dur
			
			if (p0.resolvedOffset == 0)
			{
				return new Time(this, false, "0ms");
			}
			else if (p1.indefinite && p2.indefinite)
			{
				return p0;
			}
			else
			{
				return SMILTimeHelper.min(SMILTimeHelper.min(p1, new Time(this, false, "indefinite")), SMILTimeHelper.min(p2, new Time(this, false, "indefinite")));
			}
		}
		
		/**
		 * Active duration algorithm
		 * 
		 * @see http://www.w3.org/TR/SMIL3/smil-timing.html#q83
		 */
		public function computeActiveDuation(begin:Time, end:Time):Time
		{
			var dur:Time = new Time(this, false, this.dur);
			
			var d:Time = this.computeSimpleDurationTime();
			var pad:Time = new Time(this, false, "indefinite");
			var iad:Time = this.computeIntermediateDurationTime(d);
			var ad:Time = null;
			
			var min:Time = new Time(this, false, "0ms");
			var max:Time = new Time(this, false, "indefinite");
			
			if (end != null && end.indefinite && d.indefinite)
			{
				if (end.resolved)
				{
					pad = SMILTimeHelper.subtract(end, begin);
				}
				else if (end.indefinite)
				{
					pad = new Time(this, false, "indefinite");
				}
				else
				{
					pad = new Time(this, false, "unresolved");
				}
			}
			else if (end == null || end.indefinite)
			{
				pad = iad;
			}
			else
			{
				pad = SMILTimeHelper.min(iad, SMILTimeHelper.subtract(end, begin));
			}
			
			ad = SMILTimeHelper.min(max, SMILTimeHelper.max(min, pad));
			
			this._activeDuration = ad;
			
			return ad;
		}
		
		public function gatherFirstInterval():void
		{
			var beginAfter:Time = new Time(this, true, Time.NEGATIVE_INDEFINITE.toString() + "ms");
			
			var tempBegin:Time = null;
			var tempEnd:Time = null;
			
			// calculate the first current interval
			while (true)
			{
				tempBegin = this.beginList.getTimeGreaterThan(beginAfter);
				
				if (tempBegin == null)
				{
					this.setCurrentInterval(null, null);
					
					return;
				}
				
				if (!this.endList.isDefined)
				{
					tempEnd = SMILTimeHelper.add(tempBegin, this.computeActiveDuation(tempBegin, null));
				}
				else
				{
					tempEnd = this.endList.getTimeGreaterThan(tempBegin);
					
					if (tempEnd == null)
					{
						tempEnd = new Time(this, false, "unresolved");
					}
					
					tempEnd = this.computeActiveDuation(tempBegin, tempEnd);
				}
				
				if (tempEnd.isGreaterThan(new Time(this, false, "0ms")))
				{
					this.setCurrentInterval(tempBegin, tempEnd);
					
					return;
				}
				else
				{
					beginAfter = tempEnd;
				}
			}
		}
		
		public function setCurrentInterval(begin:Time, end:Time):void
		{
			this._previousBeginInterval = this._currentBeginInterval;
			this._previousEndInterval = this._currentEndInterval;
			
			this._currentBeginInterval = begin;
			this._currentEndInterval = end;

			// notify the parent we changed
			(this.parentTimeContainer as ElementTimeContainer).childIntervalChanged(this);
			
			// notify dependencies that we changed
			var event:SMILMutationEvent = new SMILMutationEvent();
			event.initMutationEvent(SMILMutationEvent.DOM_CURRENT_INTERVAL_MODIFIED, true, false, this, null, null, null, 1);
			
			this.dispatchEvent(event);
		}
		
		protected function childIntervalChanged(child:ElementTimeContainer):void
		{
			if (child == this)
			{
				return;
			}
			
			if (this.id == "holder")
			{
				trace("heyyy");
			}

			// a child changed so we need to re-calculate another end interval, we keep using our existing begin
			this.gatherNextInterval(this.currentBeginInterval);
		}
		
		public function gatherNextInterval(usingBegin:Time = null):void
		{
			var tempBegin:Time = usingBegin;
			var tempEnd:Time = null;
			
			if (usingBegin == null)
			{
				var beginAfter:Time = this._currentBeginInterval;
				
				tempBegin = this.beginList.getTimeGreaterThan(beginAfter)
			}
			
			if (tempBegin == null)
			{
				this.setCurrentInterval(null, null);
				
				return;
			}
			
			if (!this.endList.isDefined)
			{
				tempEnd = SMILTimeHelper.add(tempBegin, this.computeActiveDuation(tempBegin, null));
			}
			else
			{
				tempEnd = this.endList.getTimeGreaterThan(tempBegin);
				
				if (tempEnd != null && tempEnd.isEqualTo(this._currentEndInterval))
				{
					tempEnd = this.endList.getTimeGreaterThan(tempEnd);
				}
				
				if (tempEnd == null)
				{
					// events are open ended ..
				}
				
				tempEnd = this.computeActiveDuation(tempBegin, tempEnd);
			}
			
			this.setCurrentInterval(tempBegin, tempEnd);
		}
		
		public function startChildren():void
		{
			// loop time children and call startup()
			var children:INodeList = this.timeChildren;
			
			for (var i:uint = 0; i < children.length; i++)
			{
				(children.item(i) as ElementTimeContainer).startup();
			}
		}
		
		public function offsetForChild(child:ElementTimeContainer):Number
		{
			return 0;
		}
		
		public function get isPlaying():Boolean
		{
			return this._isPlaying;
		}
		
		public function startup(skipChildren:Boolean = false):void
		{
			this._isPlaying = false;
			
			this._activatedAt = Time.UNRESOLVED;
			this._deactivatedAt = Time.UNRESOLVED;
			
			(this.ownerDocument as SMILDocument).timeGraph.removeWaiting(this.deactivate);
			
			if (!skipChildren)
			{
				this.startChildren();
			}
			
			this.setupFirstInterval();
			
			this.addEventListener(MutationEvent.DOM_ATTR_MODIFIED, this.onDOMTreeModified, false);
		}
		
		protected function onDOMTreeModified(e:MutationEvent):void
		{
			this.resetElementState();
			this.startup();
		}
		
		protected function setupFirstInterval():void
		{
			this.gatherFirstInterval();
			
			if (this.currentBeginInterval != null && this.currentBeginInterval.resolved)
			{
				var waitTime:Number = this.currentBeginInterval.implicitSyncbaseOffset - (this.ownerDocument as SMILDocument).offset;
				var waiting:Boolean = (this.ownerDocument as SMILDocument).timeGraph.waitUntil(waitTime, this.deactivate);
				
				// setup timer if we need to wait (and were not meant to play)
				if (!waiting && (this.parentTimeContainer as ElementTimeContainer).isPlaying)
				{
					this.activate();
				}
			}
		}
		
		/**
		 * Activates the element for playback, called after the begin has been
		 * resolved, sets the element into a playing state.
		 */
		// TODO: MOVE TO beginElement()
		public function activate():void
		{
			if (!(this.parentTimeContainer as ElementTimeContainer).isPlaying || this.currentBeginInterval.resolved)
			{
				return;
			}
			
			this._activatedAt = (this._ownerDocument as SMILDocument).offset;
			this._isPlaying = true;
			
			// trigger a display
			// this.startChildren();
			
			var waitTime:Number = 0;
			
			if (this._activeDuration != null && this._activeDuration.resolved && !this._activeDuration.indefinite)
			{
				waitTime = this._activeDuration.resolvedOffset + (this.ownerDocument as SMILDocument).offset;
				
				(this.ownerDocument as SMILDocument).timeGraph.waitUntil(waitTime, this.deactivate);
			}
			
			var simpleDurationTime:Time = this.computeSimpleDurationTime();
			
			if (simpleDurationTime.resolved && !simpleDurationTime.indefinite)
			{
				if (this._activeDuration == null || this._activeDuration.indefinite || !this._activeDuration.resolved || this._activeDuration.isGreaterThan(simpleDurationTime))
				{
					waitTime = simpleDurationTime.resolvedOffset + (this.ownerDocument as SMILDocument).offset;
					
					(this.ownerDocument as SMILDocument).timeGraph.waitUntil(waitTime, this.deactivate);
				}
			}
			
			// dispatch beginEvent on DOM
		}
		
		/**
		 * Deactivates the element from playback, called after the end has been
		 * resolved, sets the element into a paused state.
		 */
		// TODO: MOVE TO pauseElement()
		public function deactivate():void
		{
			if (!this._isPlaying)
			{
				return;
			}
			
			// deactivate time
			this._deactivatedAt = (this._ownerDocument as SMILDocument).offset;
			
			// trigger either a remove display or freeze
			
			this._isPlaying = false;
			
			(this.ownerDocument as SMILDocument).timeGraph.removeWaiting(this.deactivate);
			
			// dispatch endEvent on DOM
			
			// notify parent that the element has stopped but we might go again
			
			// try and build the nextInternal
			this.gatherNextInterval();
			
			if (this.currentBeginInterval != null && this.currentBeginInterval.resolved)
			{
				var waitTime:Number = this.currentBeginInterval.resolvedOffset - (this.ownerDocument as SMILDocument).offset;
				var waiting:Boolean = (this.ownerDocument as SMILDocument).timeGraph.waitUntil(waitTime, this.deactivate);
				
				// setup timer if we need to wait (and were not meant to play)
				if (!waiting && (this.parentTimeContainer as ElementTimeContainer).isPlaying)
				{
					this.activate();
				}
			}
		}
	}
}