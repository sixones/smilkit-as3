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
	import org.smilkit.dom.smil.Time;
	import org.smilkit.time.Times;
	import org.smilkit.w3c.dom.INode;

	/**
	 * Parses a SMIL time string into a millisecond integer value and clock type.  
	 */
	public class SMILTimeParser
	{
		protected var _parentNode:INode;
		
		protected var _milliseconds:int = 0;
		protected var _type:int = Time.SMIL_TIME_OFFSET;
		protected var _timeString:String = null;
		
		public function SMILTimeParser(parentNode:INode = null, timeString:String = null)
		{
			this._parentNode = parentNode;
			
			if (timeString != null)
			{
				this.parse(timeString);
			}
		}
		
		/**
		 * The millisecond value of the parsed SMIL time.
		 */
		public function get milliseconds():int
		{
			return this._milliseconds;
		}
		
		/**
		 * The type of the parsed SMIL time string, either SMIL_TIME_WALLCLOCK or SMIL_TIME_OFFSET.
		 */
		public function get type():int
		{
			return this._type;
		}
		
		/**
		 * The original SMIL time string that was used to generate the current instance.
		 */
		public function get timeString():String
		{
			return this._timeString;
		}
		
		public function reset():void
		{
			this.parse(null);
		}
		
		public static function identifies(timeString:Object):Boolean
		{
			if (!(timeString is String) && !(timeString is Number))
			{
				return false;
			}
				
			if (timeString.indexOf(":") != -1)
			{
				return true;
			}
			
			return (timeString.search(/^(-?)(\d+(\.\d+)?)(h|ms|s|min)$/i) != -1);
		}
		
		public function identifies(timeString:Object):Boolean
		{
			return SMILTimeParser.identifies(timeString);
		}
		
		/**
		 * Parses the specified SMIL time string into the current <code>SMILTimeParser</code>
		 * instance.
		 * 
		 * @param timeString The SMIL time string to parse into milliseconds.
		 */
		public function parse(timeString:String):SMILTimeParser
		{
			this._timeString = timeString;
			
			if (this._timeString == null || this._timeString == "")
			{
				this._milliseconds = Times.UNRESOLVED;
				this._type = Time.SMIL_TIME_OFFSET;
			}
			// parse clock values
			else if (this._timeString.indexOf(":") != -1)
			{
				var split:Array = this._timeString.split(":");
				
				var hours:uint = 0;
				var minutes:uint = 0;
				var seconds:uint = 0;
				
				// half clock
				if (split.length < 3)
				{
					minutes = uint(split[0]);
					seconds = uint(split[1]);
				}
				// full wall clock
				else
				{
					hours = uint(split[0]);
					minutes = uint(split[1]);
					seconds = uint(split[2]);
				}
				
				this._milliseconds = ((hours * 60 * 60 * 1000) + (minutes * 60 * 1000) + (seconds * 1000));
				
				this._type = Time.SMIL_TIME_WALLCLOCK;
			}
			else
			{
				// hours
				if (this._timeString.indexOf("h") != -1)
				{
					this._milliseconds = parseFloat(this._timeString.substring(0, this._timeString.indexOf("h"))) * 60 * 60 * 1000; 
				}
				// minutes
				else if (this._timeString.indexOf("min") != -1)
				{
					this._milliseconds = parseFloat(this._timeString.substring(0, this._timeString.indexOf("min"))) * 60 * 1000; 
				}
				// milliseconds value
				else if (this._timeString.indexOf("ms") != -1)
				{
					this._milliseconds = parseFloat(this._timeString.substring(0, this._timeString.indexOf("ms")));
				}				
				// seconds
				else if (this._timeString.indexOf("s") != -1)
				{
					this._milliseconds = parseFloat(this._timeString.substring(0, this._timeString.indexOf("s"))) * 1000; 
				}
				// assume the time is declared in seconds
				else
				{
					this._milliseconds = parseFloat(this._timeString) * 1000;
				}
				
				this._type = Time.SMIL_TIME_OFFSET;
			}
			
			return this;
		}
	}
}