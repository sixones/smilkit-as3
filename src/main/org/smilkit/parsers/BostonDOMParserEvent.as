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
package org.smilkit.parsers
{
	import flash.events.Event;
	
	import org.smilkit.w3c.dom.INode;
	
	public class BostonDOMParserEvent extends Event
	{
		public static var PARSER_COMPLETE:String = "onBostonDOMParserComplete";
		
		protected var _parsedNode:INode;
		
		public function BostonDOMParserEvent(type:String, parsedNode:INode, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
			
			this._parsedNode = parsedNode;
		}
		
		public function get parsedNode():INode
		{
			return this._parsedNode;
		}
	}
}