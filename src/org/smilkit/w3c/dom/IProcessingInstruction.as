package org.smilkit.w3c.dom
{
	public interface IProcessingInstruction extends INode
	{
		function get target():String;
		function get data():String;
		function set data(data:String):void;
	}
}