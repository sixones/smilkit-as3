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
package org.smilkit.dom.smil
{
	import org.smilkit.dom.events.MutationEvent;
	import org.smilkit.dom.smil.events.SMILMutationEvent;
	import org.smilkit.dom.smil.expressions.SMILDocumentVariables;
	import org.smilkit.dom.smil.expressions.SMILTimeExpressionParser;
	import org.smilkit.w3c.dom.IDocument;
	import org.smilkit.w3c.dom.smil.IElementTest;
	
	public class ElementTestContainer extends ElementTimeContainer implements IElementTest
	{	
		public static const TEST_PASSED:uint = 1;
		public static const TEST_SKIPPED:uint = 2;
		public static const TEST_FAILED:uint = 0;
		
		public static const RENDER_STATE_HIDDEN:uint = 0;
		public static const RENDER_STATE_ACTIVE:uint = 1;
		public static const RENDER_STATE_DISABLED:uint = 2;
		
		protected var _renderState:uint = ElementTestContainer.RENDER_STATE_ACTIVE;
		
		public function ElementTestContainer(owner:IDocument, name:String)
		{
			super(owner, name);
			
			this.ownerSMILDocument.addEventListener(MutationEvent.DOM_SUBTREE_MODIFIED, this.onDOMSubtreeModified, false);
			
			this.ownerSMILDocument.addEventListener(SMILMutationEvent.DOM_VARIABLES_MODIFIED, this.onDOMVariablesModified, false);
			this.ownerSMILDocument.addEventListener(SMILMutationEvent.DOM_VARIABLES_INSERTED, this.onDOMVariablesModified, false);
			this.ownerSMILDocument.addEventListener(SMILMutationEvent.DOM_VARIABLES_REMOVED, this.onDOMVariablesModified, false);
		}
		
		protected function get variables():SMILDocumentVariables
		{
			return (this.ownerDocument as SMILDocument).variables;
		}
		
		public function get systemAudioDesc():uint
		{
			return this.testAttribute(SMILDocumentVariables.SYSTEM_AUDIO_DESC);
		}
		
		public function get systemBaseProfile():uint
		{
			return this.testAttribute(SMILDocumentVariables.SYSTEM_BASE_PROFILE);
		}
		
		public function get systemBitrate():uint
		{
			return this.testAttribute(SMILDocumentVariables.SYSTEM_BITRATE);
		}
		
		public function get systemCaptions():uint
		{
			return this.testAttribute(SMILDocumentVariables.SYSTEM_CAPTIONS);
		}
		
		public function get systemComponent():uint
		{
			return this.testAttribute(SMILDocumentVariables.SYSTEM_COMPONENT);
		}
		
		public function get systemContentLocation():uint
		{
			return this.testAttribute(SMILDocumentVariables.SYSTEM_CONTENT_LOCATION);
		}
		
		public function get systemCPU():uint
		{
			return this.testAttribute(SMILDocumentVariables.SYSTEM_CPU);
		}
		
		public function get systemLanguage():uint
		{
			return this.testAttribute(SMILDocumentVariables.SYSTEM_LANGUAGE);
		}
		
		public function get systemOperatingSystem():uint
		{
			return this.testAttribute(SMILDocumentVariables.SYSTEM_OPERATING_SYSTEM);
		}
		
		public function get systemOverdubOrCaption():uint
		{
			return this.testAttribute(SMILDocumentVariables.SYSTEM_OVERDUB_OR_CAPTION);
		}
		
		public function get systemOverdubOrSubtitle():uint
		{
			return this.testAttribute(SMILDocumentVariables.SYSTEM_OVERDUB_OR_SUBTITLE);
		}
		
		public function get systemRequired():uint
		{
			return this.testAttribute(SMILDocumentVariables.SYSTEM_REQUIRED);
		}
		
		public function get systemScreenDepth():uint
		{
			return this.testAttribute(SMILDocumentVariables.SYSTEM_SCREEN_DEPTH);
		}
		
		public function get systemScreenSize():uint
		{
			return this.testAttribute(SMILDocumentVariables.SYSTEM_SCREEN_SIZE);
		}
		
		public function get systemVersion():uint
		{
			return this.testAttribute(SMILDocumentVariables.SYSTEM_VERSION);
		}
		
		public function get customTest():uint
		{
			// look up the custom test and evaluate it, for SMILKit-as3 0.4
			
			return ElementTestContainer.TEST_SKIPPED;
		}
		
		public function get expression():uint
		{
			var expr:String = this.getAttribute("expr");
			
			if (expr != null && expr != "")
			{
				   var parser:SMILTimeExpressionParser = new SMILTimeExpressionParser(this);
				   var result:Number = parser.begin(expr);
				   
				   if (result >= 1)
				   {
					   return ElementTestContainer.TEST_PASSED;
				   }
				   
				   return ElementTestContainer.TEST_FAILED;
			}
			
			return ElementTestContainer.TEST_SKIPPED;
		}
		
		public function get renderState():uint
		{
			return this._renderState;
		}
		
		public function set renderState(value:uint):void
		{
			var previous:uint = this.renderState;
			
			if (value != previous)
			{
				this._renderState = value;
				
				var e:SMILMutationEvent = new SMILMutationEvent();
				e.initMutationEvent(SMILMutationEvent.DOM_NODE_RENDER_STATE_MODIFIED, false, false, this, previous.toString(), value.toString(), "renderState", 1);
				
				this.dispatchEvent(e);
			}
		}
		
		public function updateRenderState():void
		{
			if (this.test())
			{
				this.renderState = ElementTestContainer.RENDER_STATE_ACTIVE;
			}
			else
			{
				this.renderState = ElementTestContainer.RENDER_STATE_HIDDEN;
			}
		}
		
		protected function onDOMSubtreeModified(e:MutationEvent):void
		{
			this.updateRenderState();
		}
		
		protected function onDOMVariablesModified(e:SMILMutationEvent):void
		{
			this.updateRenderState();
		}
		
		public function test():Boolean
		{
			var results:Vector.<uint> = new Vector.<uint>();
			results.push(this.systemAudioDesc);
			results.push(this.systemBaseProfile);
			results.push(this.systemBitrate);
			results.push(this.systemCaptions);
			results.push(this.systemComponent);
			results.push(this.systemContentLocation);
			results.push(this.systemCPU);
			results.push(this.systemLanguage);
			results.push(this.systemOperatingSystem);
			results.push(this.systemOverdubOrCaption);
			results.push(this.systemOverdubOrSubtitle);
			results.push(this.systemRequired);
			results.push(this.systemScreenDepth);
			results.push(this.systemScreenSize);
			results.push(this.systemVersion);
			results.push(this.customTest);
			results.push(this.expression);
			
			// run the tests on the Element
			var skips:uint = 0;
			var fails:uint = 0;
			var passes:uint = 0;
			
			for (var i:uint = 0; i < results.length; i++)
			{
				var result:uint = results[i];
				
				if (result == ElementTestContainer.TEST_FAILED)
				{
					fails++;
				}
				else if (result == ElementTestContainer.TEST_SKIPPED)
				{
					skips++;
				}
			}
			
			passes = (results.length - (fails + skips));
			
			return (fails == 0);
		}
		
		public function testAttribute(attributeName:String):uint
		{
			var attributeValue:String = this.getAttribute(attributeName);
			
			if (attributeValue != null)
			{
				var documentValue:Object = (this.variables.get(attributeName) as Object);
				
				// set a null value to an empty string so we can still validate
				if (documentValue == null)
				{
					documentValue = "";
				}
				
				var documentNumber:Number = new Number(documentValue);
				
				if (!isNaN(documentNumber))
				{
					var attributeNumber:Number = new Number(attributeValue);
					
					if (attributeNumber <= documentNumber)
					{
						return ElementTestContainer.TEST_PASSED;
					}
				}
				else
				{
					if (attributeValue == documentValue)
					{
						return ElementTestContainer.TEST_PASSED;
					}
				}
			}
			else
			{
				return ElementTestContainer.TEST_SKIPPED;
			}
			
			return ElementTestContainer.TEST_FAILED;
		}
	}
}