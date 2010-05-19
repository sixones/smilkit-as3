package
{
	import flash.display.Sprite;
	
	import org.smilkit.view.Viewport;
	
	public class SMILKitPlayer extends Sprite
	{
		protected var _viewport:Viewport;
		
		public function SMILKitPlayer()
		{
			super();
			
			this._viewport = new Viewport();
			this._viewport.location = "http://sixty.im/demo.smil";
		
			this.addChild(this._viewport.drawingBoard.canvas);
			
			this._viewport.document.resumeElement();
		}
	}
}