package org.smilkit.spec
{
	import flash.media.Video;
	
	import org.smilkit.handler.HTTPVideoHandler;
	import org.smilkit.render.DrawingBoard;
	import org.smilkit.render.HandlerController;
	import org.smilkit.spec.tests.dom.BostonDOMParserTestCase;
	import org.smilkit.spec.tests.dom.DocumentTestCase;
	import org.smilkit.spec.tests.dom.ElementTestCase;
	import org.smilkit.spec.tests.dom.ElementTimeDescendantNodeListTestCase;
	import org.smilkit.spec.tests.dom.EventTestCase;
	import org.smilkit.spec.tests.dom.ParentNodeTestCase;
	import org.smilkit.spec.tests.dom.TimeTestCase;
	import org.smilkit.spec.tests.dom.smil.ElementTestContainerTestCase;
	import org.smilkit.spec.tests.dom.smil.ElementTimeContainerTestCase;
	import org.smilkit.spec.tests.dom.smil.ElementLoadableContainerTestCase;
	import org.smilkit.spec.tests.dom.smil.SMILDocumentVariablesTestCase;
	import org.smilkit.spec.tests.dom.smil.SMILMediaElementTestCase;
	import org.smilkit.spec.tests.dom.smil.SMILSwitchElementTestCase;
	import org.smilkit.spec.tests.dom.smil.SMILTimeHelperTestCase;
	import org.smilkit.spec.tests.handler.HTTPVideoHandlerTestCase;
	import org.smilkit.spec.tests.handler.HandlerTestCase;
	import org.smilkit.spec.tests.handler.RTMPVideoHandlerTestCase;
	import org.smilkit.spec.tests.handler.SMILReferenceHandlerTestCase;
	import org.smilkit.spec.tests.load.LoadSchedulerTestCase;
	import org.smilkit.spec.tests.load.WorkerTestCase;
	import org.smilkit.spec.tests.parsers.SMILTimeParserTestCase;
	import org.smilkit.spec.tests.render.DrawingBoardTestClass;
	import org.smilkit.spec.tests.render.RenderTreeTestCase;
	import org.smilkit.spec.tests.time.HeartbeatTestCase;
	import org.smilkit.spec.tests.dom.smil.SMILTimeGraphTestCase;
	import org.smilkit.spec.tests.view.ViewportTestCase;
	
	/**
	 * DOM test suite, contains <code>TestCases</code> for testing SMILKits implemented DOM.
	 */
	[Suite]
	[RunWith("org.flexunit.runners.Suite")]
	public class SMILKitSuite
	{
		// DOM Tests
		public var documentTest:DocumentTestCase;
		public var elementTest:ElementTestCase;
		public var bostonDOMParserTest:BostonDOMParserTestCase;
		public var eventTest:EventTestCase;
		public var timeTest:TimeTestCase;
		public var elementTimeDescendantNodeList:ElementTimeDescendantNodeListTestCase;
		public var smilMediaElementTest:SMILMediaElementTestCase;
		public var parentNodeTest:ParentNodeTestCase;
		
		// SMIL Tests
		public var elementTimeContainerTest:ElementTimeContainerTestCase;
		public var elementTestContainerTest:ElementTestContainerTestCase;
		public var elementLoadableContainerTest:ElementLoadableContainerTestCase;
		public var smilDocumentVariablesTest:SMILDocumentVariablesTestCase;
		public var smilSwitchElementTest:SMILSwitchElementTestCase;
		public var smilTimeParserTest:SMILTimeParserTestCase;
		public var smilTimeHelperTest:SMILTimeHelperTestCase;
		
		// Asset Handler Tests
		public var handlerTest:HandlerTestCase;
		public var httpVideoHandlerTest:HTTPVideoHandlerTestCase;
		public var smilReferenceHandlerTest:SMILReferenceHandlerTestCase;
		
		// TODO: need a testable rtmp stream (not highwinds because of the url signing)
		//public var rtmpVideoHandlerTest:RTMPVideoHandlerTestCase;
		
		// View Tests
		public var viewportTest:ViewportTestCase;
		public var drawingBoardTest:DrawingBoardTestClass;
		public var heartbeatTest:HeartbeatTestCase;
		public var renderTreeTest:RenderTreeTestCase;
		public var timingGraph:SMILTimeGraphTestCase;
		public var loadSchedulerTest:LoadSchedulerTestCase;
		public var workerTest:WorkerTestCase;
	}
}