/* ***** BEGIN LICENSE BLOCK *****
 * Version: MPL 1.1
 *
 * The contents of this file are subject to the Mozilla Public License Version 1.1
 * (the "License"); you may not use this file except in compliance with the
 * License. You may obtain a copy of the License at http://www.mozilla.org/MPL/
 *
 * Software distributed under the License is distributed on an "AS IS" basis,
 * WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License for
 * the specific language governing rights and limitations under the License.
 *
 * The Original Code is the SMILKit library.
 *
 * The Initial Developer of the Original Code is
 * Videojuicer Ltd. (UK Registered Company Number: 05816253).
 * Portions created by the Initial Developer are Copyright (C) 2010
 * the Initial Developer. All Rights Reserved.
 *
 * Contributor(s):
 * 	Dan Glegg
 * 	Adam Livesley
 *
 * ***** END LICENSE BLOCK ***** */
package org.smilkit.handler
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.LoaderInfo;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.net.URLRequest;
	import flash.system.LoaderContext;
	
	import org.smilkit.SMILKit;
	import org.smilkit.events.HandlerEvent;
	import org.smilkit.w3c.dom.IElement;
	import org.utilkit.net.RedirectLoader;
	
	public class ImageHandler extends SMILKitHandler
	{
		protected var _bitmap:Bitmap;
		protected var _loader:RedirectLoader;
		protected var _canvas:Sprite;
		
		protected var _intrinsicWidth:Number = 0;
		protected var _intrinsicHeight:Number = 0;
		
		public function ImageHandler(element:IElement)
		{
			super(element);
			
			this._canvas = new Sprite();
		}
		
		public override function get width():uint
		{
			return this._intrinsicWidth;
		}
		
		public override function get height():uint
		{
			return this._intrinsicHeight;
		}
		
		public override function get spatial():Boolean
		{
			return true;
		}
		
		public override function get resolvable():Boolean
		{
			return false;
		}
		
		public override function get displayObject():DisplayObject
		{
			return (this._canvas as DisplayObject);
		}
		
		public override function load():void
		{
			SMILKit.logger.debug("Starting image loader for "+this.element.src, this);
		
			this.dispatchEvent(new HandlerEvent(HandlerEvent.LOAD_WAITING, this));
			
			this._loader = new RedirectLoader();
			
			this._loader.addEventListener(Event.COMPLETE, this.onLoaderComplete);
			this._loader.addEventListener(IOErrorEvent.IO_ERROR, this.onLoaderError);
			this._loader.addEventListener(ProgressEvent.PROGRESS, this.onLoaderProgress);
			
			this._loader.load(new URLRequest(this.element.src), new LoaderContext(true));
			
			this._startedLoading = true;
		}
		
		public override function resize():void
		{
			super.resize();
			
			// catches a rare bug where the stage is resized before the content has been loaded
			if (this._bitmap != null)
			{
				this.drawClickShield(this._bitmap);
			}
		}
		
		public override function cancel():void
		{
			// only cancel the image if we havent completed loading
			// theres no point throwing away something that is ready for use!
			if (!this.completedLoading)
			{
				if (this._loader != null)
				{
					this._loader.close();
					this._loader = null;
				}
				
				for (var i:int = 0; i < this._canvas.numChildren; i++)
				{
					this._canvas.removeChildAt(i);
				}
				
				super.cancel();
			}
		}
		
		protected function onLoaderProgress(e:ProgressEvent):void
		{
			if(this._mediaElement != null)
			{
				this._mediaElement.intrinsicBytesLoaded = e.bytesLoaded;
				this._mediaElement.intrinsicBytesTotal = e.bytesTotal;
			}
		}
		
		protected function onLoaderComplete(e:Event):void
		{
			var loaderInfo:LoaderInfo = this._loader.currentLoader.contentLoaderInfo;
			
			this._intrinsicWidth = loaderInfo.width;
			this._intrinsicHeight = loaderInfo.height;
			
			var bitmapData:BitmapData = (loaderInfo.content as Bitmap).bitmapData;
			this._bitmap = new Bitmap(bitmapData, "auto", true);
			//this._bitmap.width = this.width;
			//this._bitmap.height = this.height;
			
			this._completedLoading = true;
			
			this._canvas.addChild(this._bitmap);
			
			//this.drawClickShield(this._bitmap);
			
			SMILKit.logger.debug("Finished loading image ("+this.element.src+")", this);
			
			this.resize();
			
			this.dispatchEvent(new HandlerEvent(HandlerEvent.LOAD_READY, this));
			this.dispatchEvent(new HandlerEvent(HandlerEvent.LOAD_COMPLETED, this));
		}
		
		protected function onLoaderError(e:IOErrorEvent):void
		{
			SMILKit.logger.debug("Failed to load image ("+this.element.src+")", this);
			this.cancel();			
			this.dispatchEvent(new HandlerEvent(HandlerEvent.LOAD_FAILED, this));
		}
		
		public static function toHandlerMap():HandlerMap
		{
			return new HandlerMap(['http', 'https'], { 'image/jpeg': [ '.jpg', '.jpeg' ], 'image/gif': [ '.gif' ], 'image/png': [ '.png' ], 'image/bmp': [ '.bmp' ] });
		}
	}
}