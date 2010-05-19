package org.smilkit.collections
{

	public class Hashtable extends List
	{
		protected var _keys:List = new List();
		
		public function Hashtable()
		{
			super(null);
		}
		
		public function get isEmpty():Boolean
		{
			return (this._keys.length == 0);
		}
		
		public function getItem(key:Object):Object
		{
			var i:int = this.getNamedIndex(key);
			
			if (i == -1)
			{
				return null;
			}
			else
			{
				return this.getItemAt(i);
			}
		}
		
		public function getKeyAt(index:int):Object
		{
			if (index > this.length || index < 0)
			{
				return null;
			}
			
			return this._keys.getItemAt(index);
		}
		
		public function getNamedIndex(key:Object):int
		{
			if (this.hasItem(key))
			{
				for (var i:int = this._keys.length; i > 0; i--)
				{
					if (key == this._keys.getItemAt(i))
					{
						return i;
					}
				}
			}
			
			return -1;
		}
		
		public function setItem(key:Object, value:Object):void
		{
			var i:int = this.getNamedIndex(key);
			
			if (i == -1)
			{
				var n:int = this.length;
				
				this._keys.setItemAt(key, n);
				this.setItemAt(value, n);
			}
			else
			{
				this.setItemAt(value, i);
			}
		}
		
		public function removeItem(key:Object):void
		{
			var i:int = this.getNamedIndex(key);
			
			if (i != -1)
			{
				this._keys.removeItemAt(i);
				this.removeItemAt(i);
			}
		}
		
		public function hasItem(key:Object):Boolean
		{
			for (var i:int = this._keys.length; i > 0; i--)
			{
				if (key == this._keys.getItemAt(i))
				{
					return true;
				}
			}
			
			return false;
		}
	}
}