package org.smilkit.view.extensions
{
	import flash.events.ProgressEvent;
	import flash.geom.Rectangle;
	
	import org.osmf.containers.MediaContainer;
	import org.osmf.events.BufferEvent;
	import org.osmf.events.DisplayObjectEvent;
	import org.osmf.events.LoadEvent;
	import org.osmf.events.MediaError;
	import org.osmf.events.MediaErrorCodes;
	import org.osmf.events.MediaErrorEvent;
	import org.osmf.events.MediaPlayerCapabilityChangeEvent;
	import org.osmf.events.PlayEvent;
	import org.osmf.events.SeekEvent;
	import org.osmf.events.TimeEvent;
	import org.osmf.layout.LayoutMetadata;
	import org.osmf.layout.ScaleMode;
	import org.osmf.media.DefaultMediaFactory;
	import org.osmf.media.MediaElement;
	import org.osmf.media.MediaFactory;
	import org.osmf.media.MediaPlayer;
	import org.osmf.media.PluginInfoResource;
	import org.osmf.media.URLResource;
	import org.osmf.metadata.Metadata;
	import org.osmf.smil.SMILPluginInfo;
	import org.osmf.traits.LoadState;
	import org.osmf.traits.PlayState;
	import org.smilkit.SMILKit;
	import org.smilkit.events.ViewportEvent;
	import org.smilkit.view.BaseViewport;

	public class OSMFViewport extends BaseViewport
	{
		private var _mediaPlayer:MediaPlayer = null;
		private var _mediaFactory:MediaFactory = null;
		private var _mediaElement:MediaElement = null;
	
		private var _uiMetadata:LayoutMetadata = null;
		private var _uiComponent:MediaContainer = null;
		private var _uiSize:Rectangle = null;
		
		private var _waitingForRefresh:Boolean = false;
		
		public function OSMFViewport()
		{
			super();
			
			this._uiMetadata = new LayoutMetadata();
			this._uiMetadata.scaleMode = ScaleMode.LETTERBOX;
			
			this._uiComponent = new MediaContainer(null, this._uiMetadata);
			this._uiComponent.backgroundColor = 0xFFFFFFF;
			this._uiComponent.backgroundAlpha = 0;
			
			this._mediaPlayer = new MediaPlayer();
			
			this._mediaPlayer.autoPlay = false;
			
			this._mediaPlayer.addEventListener(MediaErrorEvent.MEDIA_ERROR, this.onMediaError);
			
			this._mediaPlayer.addEventListener(DisplayObjectEvent.DISPLAY_OBJECT_CHANGE, this.onDisplayObjectChanged);
			this._mediaPlayer.addEventListener(DisplayObjectEvent.MEDIA_SIZE_CHANGE, this.onMediaSizeChanged);
			
			this._mediaPlayer.addEventListener(MediaPlayerCapabilityChangeEvent.CAN_PLAY_CHANGE, this.onPlayChanged);
			this._mediaPlayer.addEventListener(MediaPlayerCapabilityChangeEvent.CAN_LOAD_CHANGE, this.onLoadChanged);
			
			this._mediaPlayer.addEventListener(PlayEvent.PLAY_STATE_CHANGE, this.onPlayStateChanged);
			this._mediaPlayer.addEventListener(SeekEvent.SEEKING_CHANGE, this.onSeekChanged);
			
			this._mediaPlayer.addEventListener(TimeEvent.CURRENT_TIME_CHANGE, this.onTimeChanged);
			this._mediaPlayer.addEventListener(TimeEvent.DURATION_CHANGE, this.onDurationChanged);
			this._mediaPlayer.addEventListener(TimeEvent.COMPLETE, this.onTimeComplete);
			
			this._mediaPlayer.addEventListener(LoadEvent.BYTES_LOADED_CHANGE, this.onBytesLoadedChanged);
			this._mediaPlayer.addEventListener(LoadEvent.BYTES_TOTAL_CHANGE, this.onBytesTotalChanged);
			this._mediaPlayer.addEventListener(LoadEvent.LOAD_STATE_CHANGE, this.onLoadStateChanged);
			
			this._mediaPlayer.addEventListener(BufferEvent.BUFFER_TIME_CHANGE, this.onBufferTimeChanged);
			this._mediaPlayer.addEventListener(BufferEvent.BUFFERING_CHANGE, this.onBufferingChanged);
			
			this._mediaPlayer.currentTimeUpdateInterval = 500;
			
			this._mediaFactory = new DefaultMediaFactory();
			this._mediaFactory.loadPlugin(new PluginInfoResource(new SMILPluginInfo()));
			
			this.addChild(this._uiComponent);
		}
		
		public override function get boundingRect():Rectangle
		{
			return new Rectangle(0, 0, this._uiComponent.width, this._uiComponent.height);
		}
		
		public override function set boundingRect(rect:Rectangle):void
		{
			if (this._uiSize == null || !this._uiSize.equals(rect))
			{
				this._uiSize = rect;
				
				this.updateUISize();
			}
		}
		
		public override function get offset():Number
		{
			return this._mediaPlayer.currentTime;
		}
		
		public override function get duration():Number
		{
			return this._mediaPlayer.duration * 1000;
		}
		
		public override function get type():String
		{
			return SMILKit.VIEWPORT_OSMF;
		}
		
		public override function getDocumentMeta(key:String):String
		{
			var metadata:Metadata = this._mediaElement.resource.getMetadataValue("org.smilkit") as Metadata;
			
			if (metadata != null)
			{
				return metadata.getValue(key);
			}
			
			return null;
		}
		
		public override function refresh():void
		{
			if (this._mediaPlayer.media != null)
			{
				this._uiComponent.removeMediaElement(this._mediaPlayer.media);
			}
			
			var resource:URLResource = new URLResource(this.location);
			this._mediaElement = this._mediaFactory.createMediaElement(resource);
			
			this._mediaElement.addEventListener(MediaErrorEvent.MEDIA_ERROR, this.onMediaError);
			
			this._mediaPlayer.media = this._mediaElement;
			this._uiComponent.addMediaElement(this._mediaElement);
			
			this.updateUISize();
			
			this._waitingForRefresh = true;
			
			// send a playback offset changed event so that addons can reset their UIs
			this.dispatchEvent(new ViewportEvent(ViewportEvent.PLAYBACK_OFFSET_CHANGED));
		}
		
		public override function setVolume(volume:uint, setRestorePoint:Boolean = false):Boolean
		{
			volume = Math.max(0, Math.min(BaseViewport.VOLUME_MAX, volume));
			
			if (this.volume != volume)
			{
				if (setRestorePoint)
				{
					this._unmuteRestoreVolume = this.volume;
				}
				
				var mutedBefore:Boolean = this.muted;
				
				this._volume = volume;
				
				this._mediaPlayer.volume = (this._volume / 100);
				
				this.dispatchEvent(new ViewportEvent(ViewportEvent.AUDIO_VOLUME_CHANGED));
				
				if (volume == 0 && !mutedBefore)
				{
					SMILKit.logger.info("Audio muted.", this);
					
					this.dispatchEvent(new ViewportEvent(ViewportEvent.AUDIO_MUTED));
				}
				
				if (volume > 0 && mutedBefore)
				{
					SMILKit.logger.info("Audio unmuted.", this);
					
					this.dispatchEvent(new ViewportEvent(ViewportEvent.AUDIO_UNMUTED));
				}
			}
			
			return false;
		}
		
		protected function updateUISize():void
		{
			if (this._uiSize != null)
			{
				this._uiComponent.graphics.clear();
				
				this._uiComponent.layoutMetadata.width = this._uiSize.width;
				this._uiComponent.layoutMetadata.height = this._uiSize.height;
				
				this._uiComponent.layout(this._uiSize.width, this._uiSize.height, true);
			}
		}
		
		protected override function onPlaybackStateChangedToPlaying():void
		{
			if (this._mediaPlayer.canPlay && !this._mediaPlayer.playing)
			{
				this._mediaPlayer.play();
			}
		}
		
		protected override function onPlaybackStateChangedToPaused():void
		{
			if (this._mediaPlayer != null && this._mediaPlayer.canPause && this._mediaPlayer.playing)
			{
				this._mediaPlayer.pause();
			}
		}
		
		protected override function onPlaybackStateChangedToStopped():void
		{
			this._mediaPlayer.stop();
		}
		
		protected override function onPlaybackStateChangedToSeekingWithOffset(offset:uint):void
		{
			this._mediaPlayer.pause();
			this._mediaPlayer.seek((offset / 1000));
		}
		
		public override function commitSeek():Boolean
		{
			if (this._playbackState == BaseViewport.PLAYBACK_SEEKING)
			{
				return super.commitSeek();
			}
			
			return false;
		}
		
		protected function onMediaError(e:MediaErrorEvent):void
		{
			SMILKit.logger.error("onMediaError: "+e.error.errorID+" -> " +e.error.detail+" "+e.error.message);
			
			switch (e.error.errorID)
			{
				case MediaErrorCodes.NETCONNECTION_REJECTED:
				case MediaErrorCodes.SECURITY_ERROR:
					this.dispatchEvent(new ViewportEvent(ViewportEvent.HANDLER_LOAD_UNAUTHORISED));
					break;
				case MediaErrorCodes.NETCONNECTION_TIMEOUT:
					this.dispatchEvent(new ViewportEvent(ViewportEvent.HANDLER_LOAD_TIMEOUT));
					break;
				case MediaErrorCodes.NETSTREAM_STREAM_NOT_FOUND:
				default:
					this.dispatchEvent(new ViewportEvent(ViewportEvent.HANDLER_LOAD_FAILED));
					break;
			}
		}
		
		protected function onDisplayObjectChanged(e:DisplayObjectEvent):void
		{
			SMILKit.logger.error("onDisplayObjectChanged: ");
			
			this.updateUISize();
		}
		
		protected function onMediaSizeChanged(e:DisplayObjectEvent):void
		{
			SMILKit.logger.error("onMediaSizeChanged: ");
			
			this.updateUISize();
		}
		
		protected function onPlayChanged(e:MediaPlayerCapabilityChangeEvent):void
		{
			SMILKit.logger.error("onPlayChanged: "+e.type);
			
			if (this._waitingForRefresh)
			{
				this._waitingForRefresh = false;
				
				this.dispatchEvent(new ViewportEvent(ViewportEvent.REFRESH_COMPLETE));
			}
			
			this.updateUISize();
		}
		
		protected function onLoadChanged(e:MediaPlayerCapabilityChangeEvent):void
		{
			SMILKit.logger.error("onLoadChanged: "+e.type);
		}
		
		protected function onPlayStateChanged(e:PlayEvent):void
		{
			// nothing
		}
		
		protected function onSeekChanged(e:SeekEvent):void
		{
			
		}
		
		protected function onTimeChanged(e:TimeEvent):void
		{
			this.dispatchEvent(new ViewportEvent(ViewportEvent.PLAYBACK_OFFSET_CHANGED));
		}
		
		protected function onDurationChanged(e:TimeEvent):void
		{
			this.dispatchEvent(new ViewportEvent(ViewportEvent.DOCUMENT_MUTATED));
		}
		
		protected function onTimeComplete(e:TimeEvent):void
		{
			this.pause();
			
			this.dispatchEvent(new ViewportEvent(ViewportEvent.PLAYBACK_COMPLETE));
		}
		
		protected function onBytesLoadedChanged(e:LoadEvent):void
		{
			this._bytesLoaded = e.bytes;
			
			this.dispatchEvent(new ProgressEvent(ProgressEvent.PROGRESS, false, false, this._bytesLoaded, this._bytesTotal));
		}
		
		protected function onBytesTotalChanged(e:LoadEvent):void
		{
			var bytes:Number = e.bytes;
			
			// retrieve bytesTotal from the SMILDocument
			var metadata:Metadata = this._mediaElement.resource.getMetadataValue("org.smilkit.sizes") as Metadata;
			
			if (metadata != null)
			{
				bytes = 0;
				
				for (var i:uint = 0; i < metadata.keys.length; i++)
				{
					var key:String = metadata.keys[i];
					var size:Number = parseFloat(metadata.getValue(key));
					
					bytes += size;
				}
			}
			
			this._bytesTotal = bytes;
			
			this.dispatchEvent(new ProgressEvent(ProgressEvent.PROGRESS, false, false, this._bytesLoaded, this._bytesTotal));
		}
		
		protected function onLoadStateChanged(e:LoadEvent):void
		{
			switch (e.loadState)
			{
				case LoadState.LOAD_ERROR:
					this.dispatchEvent(new ViewportEvent(ViewportEvent.LOADER_IOERROR));
					break;
				case LoadState.LOADING:
					this.dispatchEvent(new ViewportEvent(ViewportEvent.WAITING));
					break;
				case LoadState.READY:
					this.dispatchEvent(new ViewportEvent(ViewportEvent.READY));
					break;
				case LoadState.UNINITIALIZED:
					break;
				case LoadState.UNLOADING:
					break;
			}
		}
		
		protected function onBufferTimeChanged(e:BufferEvent):void
		{
			SMILKit.logger.error("onBufferTimeChanged: "+e.bufferTime);
		}
		
		protected function onBufferingChanged(e:BufferEvent):void
		{
			if (e.buffering)
			{
				this.dispatchEvent(new ViewportEvent(ViewportEvent.WAITING));
			}
			else
			{
				this.dispatchEvent(new ViewportEvent(ViewportEvent.READY));
			}
		}
	}
}