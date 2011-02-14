package org.smilkit.handler
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import flash.events.AsyncErrorEvent;
	import flash.events.IOErrorEvent;
	import flash.events.NetStatusEvent;
	import flash.events.SecurityErrorEvent;
	import flash.events.TimerEvent;
	import flash.media.SoundTransform;
	import flash.media.Video;
	import flash.net.NetConnection;
	import flash.net.NetStream;
	
	import org.smilkit.SMILKit;
	import org.smilkit.events.HandlerEvent;
	import org.smilkit.handler.state.HandlerState;
	import org.smilkit.handler.state.VideoHandlerState;
	import org.smilkit.util.Metadata;
	import org.smilkit.w3c.dom.IElement;
	import org.utilkit.logger.Logger;
	
	public class HTTPVideoHandler extends SMILKitHandler
	{
		protected var _netConnection:NetConnection;
		protected var _netStream:NetStream;
		protected var _video:Video;
		protected var _soundTransformer:SoundTransform;
		protected var _metadata:Metadata;
		protected var _canvas:Sprite;
		
		protected var _resumed:Boolean = false;
		
		protected var _loadReady:Boolean = false;
		
		protected var _volume:uint;
		
		/**
		* If a seek is issued when the handler is not ready to perform it (either before load or when not enough bytes are loaded to perform the seek)
		* the seek offset will be stored here until the seek is available. Once the seek has completed the value will be nulled.
		*/
		protected var _queuedSeek:Boolean = false;
		protected var _queuedSeekTarget:uint;
		
		public function HTTPVideoHandler(element:IElement)
		{
			super(element);
			
			this._canvas = new Sprite();
		}

		public override function get width():uint
		{
			if (this._metadata == null)
			{
				return super.width;
			}
			
			return this._metadata.width;
		}
		
		public override function get height():uint
		{
			if (this._metadata == null)
			{
				return super.height;
			}
			
			return this._metadata.height;
		}
		
		public override function get resolvable():Boolean
		{
			return true;
		}
		
		public override function get seekable():Boolean
		{
			return true;
		}
		
		public override function get syncPoints():Vector.<int>
		{
			if (this._metadata == null)
			{
				return super.syncPoints;
			}
			
			return this._metadata.syncPoints;
		}

		public override function get spatial():Boolean
		{
			return true;
		}
		
		public override function get temporal():Boolean
		{
			return true;
		}
		
		public override function get displayObject():DisplayObject
		{
			return (this._canvas as DisplayObject);
		}

		public override function get innerDisplayObject():DisplayObject
		{
			return (this._video as DisplayObject);
		}
		
		public override function get currentOffset():int
		{
			if (this._netStream == null)
			{
				return super.currentOffset;
			}
			
			return (this._netStream.time * 1000);
		}
		
		public override function get handlerState():HandlerState
		{
			return new VideoHandlerState(this.element.src, 0, this._netConnection, this._netStream, this._video, this._canvas);	
		}
		
		public override function load():void
		{
			this._resumed = false;
			
			this._netConnection = new NetConnection();
			this._netConnection.connect(null);
			
			this._soundTransformer = new SoundTransform(0.2, 0);
			
			if(this._volume)
			{
				this.setVolume(this._volume);
			}
			
			this._netStream = new NetStream(this._netConnection);
			
			this._netStream.addEventListener(NetStatusEvent.NET_STATUS, this.onNetStatusEvent);
			this._netStream.addEventListener(AsyncErrorEvent.ASYNC_ERROR, this.onAsyncErrorEvent);
			this._netStream.addEventListener(IOErrorEvent.IO_ERROR, this.onIOErrorEvent);
			
			this._netStream.checkPolicyFile = true;
			this._netStream.client = this;
			this._netStream.bufferTime = 10;
			this._netStream.soundTransform = this._soundTransformer;
			
			this._netStream.play(this.element.src);
			
			this._video = new Video();
			this._video.smoothing = true;
			this._video.deblocking = 1;
			
			this._video.attachNetStream(this._netStream as NetStream);
			
			// dont want to actually play it back right now
			
			this._canvas.addChild(this._video);
			
			this._startedLoading = true;
			
			if (this.viewportObjectPool != null)
			{
				this.viewportObjectPool.viewport.heartbeat.addEventListener(TimerEvent.TIMER, this.onHeartbeatTick);
			}
			
			this.drawClickShield(this._video);
			
			this.dispatchEvent(new HandlerEvent(HandlerEvent.LOAD_WAITING, this));
		}
		
		public override function setVolume(volume:uint):void
		{
			this._volume = volume;
			if(this._soundTransformer != null && this._netStream != null)
			{
				SMILKit.logger.debug("Handler volume set to "+volume+".", this);
				this._soundTransformer.volume = volume/100;
				this._netStream.soundTransform = this._soundTransformer;
			}
		}
		
		public override function resume():void
		{
			if (this._netStream != null)
			{
				SMILKit.logger.debug("Resuming playback.", this);
				this._resumed = true;
				this._netStream.resume();
			}
		}
		
		public override function pause():void
		{
			if (this._netStream != null)
			{
				SMILKit.logger.debug("Pausing playback.", this);
				this._resumed = false;
				this._netStream.pause();
			}
		}
		
		/** 
		* Executes or queues a seek operation on this handler. Since seek availability within a progressive HTTP video is 
		* limited by the amount of data currently loaded, the handler first checks the readiness of the requested seek offset
		* and queues the seek operation if the handler is not ready to meet that demand.
		*
		* In the event of a seek being queued, the heartbeat subscriber method will start to check for the availability of
		* the queued seek offset and execute the seek when it becomes available.
		* 
		* Issuing a new seek call to an offset that is available will clear any queued seek operations. Issuing a new seek call
		* to an offset that is not available will overwrite any previously-queued seek operation.
		* 
		* @see org.smilkit.handler.HTTPVideoHandler.onHeartbeatTick
		*/
		public override function seek(seekTo:Number):void
		{
			if(this.readyToPlayAt(seekTo))
			{
				// We're able to seek to that point. Execute the seek right away.
				this.execSeek(seekTo);
			}
			else
			{
				// Stash the seek until we're able to do it.
				SMILKit.logger.debug("Seek to "+seekTo+"ms requested, but not able to seek to that offset. Queueing seek until offset becomes available.");
				this._queuedSeek = true;
				this._queuedSeekTarget = seekTo;
			}
		}
		
		/*
		* Executes a seek operation on an offset that is available within this handler, clearing any queued seek operations in the process.
		*/
		protected function execSeek(seekTo:Number):void
		{
			// Cancel queued seek
			this._queuedSeek = false;
			
			// Execute seek
			// this._netStream.resume();
			var seconds:Number = (seekTo / 1000);
			SMILKit.logger.debug("Executing internal seek to "+seekTo+"ms ("+seconds+"s)", this);
			this._netStream.seek(seconds);
		}
		
		/*
		* Executes a queued seek operation, if one has been queued. If the seek is executed, the queued seek will be cleared.
		*/
		protected function execQueuedSeek():void
		{
			if(this._queuedSeek)
			{
				SMILKit.logger.debug("About to execute a deferred seek operation to "+this._queuedSeekTarget+"ms.", this);
				this.execSeek(this._queuedSeekTarget);
			}
			else
			{
				SMILKit.logger.debug("Asked to execute any queued seek operation, but no seek operation is queued.", this);
			}
		}

		
		public override function merge(handlerState:HandlerState):Boolean
		{
			// cant merge anything with a http video!
			
			return false;
		}
		
		public override function cancel():void
		{
			if (this.viewportObjectPool != null)
			{
				this.viewportObjectPool.viewport.heartbeat.removeEventListener(TimerEvent.TIMER, this.onHeartbeatTick);
			}
			
			this._resumed = false;
			
			this._netStream.close();
			this._netConnection.close();
			
			this._netConnection = null;
			this._netStream = null;
			
			// Note that the cancel operation does NOT clear the metadata, if any has been loaded. This is to allow resolve jobs to
			// retain their data payload. If the file is reloaded with new metadata, then the metadata object will be updated at that time.
			
			for (var i:int = 0; i < this._canvas.numChildren; i++)
			{
				this._canvas.removeChildAt(i);
			}
			
			this._shield = null;
			
			super.cancel();
		}
		
		protected function readyToPlayAt(offset:int):Boolean
		{
			if (this._netStream != null && this._startedLoading)
			{
				var percentageLoaded:Number = (this._netStream.bytesLoaded / this._netStream.bytesTotal) * 100;
				var durationLoaded:Number = ((percentageLoaded / 100) * this.duration);
				
				SMILKit.logger.debug("readyToPlayAt: Loaded "+percentageLoaded+"% of file, equating to "+durationLoaded+"ms of playtime. Desired offset is "+offset+"ms.", this);
				
				if (offset == 0)
				{
					if (percentageLoaded < 6)
					{
						return false;
					}
				}
				
				if (offset <= durationLoaded)
				{
					return true;
				}
			}
			
			return false;
		}
		
		/**
		* Executed each time the heartbeat timer ticks, regardless of it's paused/resumed state.
		* Checks the load status of this handler and emits LOAD_READY or LOAD_WAIT events on any state change.
		*/
		protected function onHeartbeatTick(e:TimerEvent):void
		{
			if (this._netStream == null)
			{
				return;
			}
			
			if(this._queuedSeek)
			{
				this.checkQueuedSeekLoadState();
			}
			else
			{
				this.checkPlaybackLoadState();
			}
		}
		
		/**
		* Checks the handler's readiness to perform a deferred seek operation and executes the seek when enough data is available.
		* Acts as a load state checker, and therefore emits LOAD_READY and LOAD_WAIT events.
		*/
		protected function checkQueuedSeekLoadState():void
		{
			if(this.readyToPlayAt(this._queuedSeekTarget))
			{
				SMILKit.logger.debug("checkQueuedSeekLoadState: now ready to seek. About to execute deferred seek.", this);
				
				this.execQueuedSeek();
				
				if(!this._loadReady)
				{
					this._loadReady = true;
					this.dispatchEvent(new HandlerEvent(HandlerEvent.LOAD_READY, this));
				}
			}
			else
			{
				SMILKit.logger.debug("checkQueuedSeekLoadState: Not yet ready to seek to target "+this._queuedSeekTarget+"ms.", this);
				
				if(this._loadReady)
				{
					this._loadReady = false;
					this.dispatchEvent(new HandlerEvent(HandlerEvent.LOAD_WAITING, this));
				}
			}
		}
		
		/**
		* Checks the loaded bytes against the known file byte size and determines whether enough data has loaded for playback to continue at the current offset.
		* Called on each heartbeat tick unless a seek operation is queued.
		*/ 
		protected function checkPlaybackLoadState():void
		{
			var percentageLoaded:Number = (this._netStream.bytesLoaded / this._netStream.bytesTotal) * 100;
			var durationLoaded:Number = ((percentageLoaded / 100) * this.duration);
			
			// if were not already ready, check if we are
			if (!this._loadReady)
			{
				if ((durationLoaded - this.currentOffset) >= (this._netStream.bufferTime * 1000))
				{
					// increase the buffer so we have more ready
					//this._netStream.bufferTime = 30;
					
					this._loadReady = true;
					
					this.dispatchEvent(new HandlerEvent(HandlerEvent.LOAD_READY, this));
				}
			}
			// if were ready, check if we need more
			else
			{
				if (!this._completedLoading && ((this.currentOffset + 5) >= durationLoaded))
				{
					// reduce the buffer so we get ready quicker
					//this._netStream.bufferTime = 15;
					
					this._loadReady = false;
					
					this.dispatchEvent(new HandlerEvent(HandlerEvent.LOAD_WAITING, this));
				}
			}
			
			if (percentageLoaded >= 100 && !this._completedLoading)
			{
				this._completedLoading = true;
				
				SMILKit.logger.debug("Handler has completed loading ("+this._netStream.bytesLoaded+"/"+this._netStream.bytesTotal+" bytes)", this);
				
				this.dispatchEvent(new HandlerEvent(HandlerEvent.LOAD_COMPLETED, this));
			}
		}
		
		public override function resize():void
		{
			super.resize();
		
			this.drawClickShield(this._video);
		}
		
		protected function onNetStatusEvent(e:NetStatusEvent):void
		{
			SMILKit.logger.debug("NetStatus Event on video at internal offset "+this._netStream.time+"s: "+e.info.level+" "+e.info.code);
			
			switch (e.info.code)
			{
				case "NetStream.Buffer.Full":
					//this._netStream.bufferTime = 30; // expand buffer
					
					//this.dispatchEvent(new HandlerEvent(HandlerEvent.LOAD_READY, this));
					break;
				case "NetStream.Buffer.Empty":
					//this._netStream.bufferTime = 8; // reduce buffer
					
					//this.dispatchEvent(new HandlerEvent(HandlerEvent.LOAD_WAITING, this));
					break;
				case "NetStream.Play.Failed":
				case "NetStream.Play.NoSupportedTrackFound":
				case "NetStream.Play.FileStructureInvalid":
					this.dispatchEvent(new HandlerEvent(HandlerEvent.LOAD_FAILED, this));
					break;
				case "NetStream.Unpublish.Success":
				case "NetStream.Play.Stop":
					// playback has finished, important for live events (so we can continue)
					this.dispatchEvent(new HandlerEvent(HandlerEvent.STOP_NOTIFY, this));
					break;
				case "NetStream.Pause.Notify":
					this.dispatchEvent(new HandlerEvent(HandlerEvent.PAUSE_NOTIFY, this));
					break;
				case "NetStream.Unpause.Notify":
					this.dispatchEvent(new HandlerEvent(HandlerEvent.RESUME_NOTIFY, this));
					break;
				case "NetStream.Seek.Failed":
					this.dispatchEvent(new HandlerEvent(HandlerEvent.SEEK_FAILED, this));
					break;
				case "NetStream.Seek.InvalidTime":
					this.dispatchEvent(new HandlerEvent(HandlerEvent.SEEK_INVALID, this));
					break;
				case "NetStream.Seek.Notify":
					if (!this._resumed)
					{
						this._netStream.pause();
					}
					
					this.dispatchEvent(new HandlerEvent(HandlerEvent.SEEK_NOTIFY, this));
					break;
			}
		}
		
		protected function onIOErrorEvent(e:IOErrorEvent):void
		{
			SMILKit.logger.debug("Handler encountered an IO error during load.", this);
			this.cancel();
			this.dispatchEvent(new HandlerEvent(HandlerEvent.LOAD_FAILED, this));
		}
		
		protected function onSecurityErrorEvent(e:SecurityErrorEvent):void
		{
			SMILKit.logger.debug("Handler encountered a security error during load.", this);
			this.cancel();			
			this.dispatchEvent(new HandlerEvent(HandlerEvent.LOAD_UNAUTHORISED, this));
			this.dispatchEvent(new HandlerEvent(HandlerEvent.LOAD_FAILED, this));
		}
		
		protected function onAsyncErrorEvent(e:AsyncErrorEvent):void
		{
			SMILKit.logger.debug("Handler encountered an async error during load: "+e.error.name+", "+e.error.message, this);
			this.cancel();			
			this.dispatchEvent(new HandlerEvent(HandlerEvent.LOAD_FAILED, this));
		}
		
		public function onMetaData(info:Object):void
		{	
			if (this._metadata == null)
			{
				this._metadata = new Metadata(info);
			}
			else
			{
				this._metadata.update(info);
			}

			if(!this._resumed)
			{
				SMILKit.logger.debug("Encountered metadata while loading or paused. About to pause netstream object.", this);
				
				this.seek(0);
				this.pause();
			}
			
			SMILKit.logger.info("Metadata received (with "+this.syncPoints.length+" syncPoints): "+this._metadata.toString());
			
			this.resolved(this._metadata.duration);
		}
		
		public static function toHandlerMap():HandlerMap
		{
			return new HandlerMap(['http'], { 'video/flv': [ '.flv', '.f4v' ], 'video/mpeg': [ '.mp4', '.f4v' ] });
		}
	}
}