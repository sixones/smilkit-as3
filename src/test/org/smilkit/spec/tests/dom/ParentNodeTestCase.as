package org.smilkit.spec.tests.dom
{
	import flexunit.framework.Assert;
	
	import org.smilkit.SMILKit;
	import org.smilkit.dom.Document;
	import org.smilkit.dom.DocumentType;
	import org.smilkit.dom.Element;
	import org.smilkit.dom.ParentNode;
	import org.smilkit.dom.ChildNode;
	import org.smilkit.dom.smil.SMILDocument;
	import org.smilkit.parsers.BostonDOMParser;
	import org.smilkit.spec.Fixtures;
	import org.smilkit.w3c.dom.IDocument;
	import org.smilkit.w3c.dom.IElement;
	import org.smilkit.w3c.dom.INode;
	import org.smilkit.w3c.dom.INodeList;

	//import org.smilkit.w3c.dom.INodeList;
	
	public class ParentNodeTestCase
	{	
		protected var _document:SMILDocument;
	
		public function ParentNodeTestCase()
		{
			
		}
		
		[Before]
		public function setUp():void
		{
			SMILKit.defaults();
			
			var parser:BostonDOMParser = new BostonDOMParser();
			this._document = (parser.parse(Fixtures.MULTIPLE_CHILDREN_SMIL_XML) as SMILDocument);
		}
		
		[Test(description="Ensures that all nodes in a parsed document are in an attached state")]
		public function documentParserAttachesNodes():void
		{
			Assert.assertFalse(this._document.orphaned);
			Assert.assertFalse((this._document.firstChild as ParentNode).orphaned);
		}
		
		[Test(description="Ensures that all nodes in an orphaned tree are unorphaned when the root gets a parent")]
		public function orphanedTreeUnorphanedOnParentSet():void
		{
			var orphanGrandParent:ParentNode = new ParentNode(this._document);
			var orphanParent:ParentNode = new ParentNode(this._document);
			var orphanChild:ParentNode = new ParentNode(this._document);
			
			Assert.assertTrue(orphanGrandParent.orphaned);
			Assert.assertTrue(orphanParent.orphaned);
			Assert.assertTrue(orphanChild.orphaned);
			
			orphanGrandParent.appendChild(orphanParent);
			orphanParent.appendChild(orphanChild);
			
			Assert.assertTrue(orphanGrandParent.orphaned);
			Assert.assertTrue(orphanParent.orphaned);
			Assert.assertTrue(orphanChild.orphaned);
			
			this._document.appendChild(orphanGrandParent);
			
			Assert.assertFalse(orphanGrandParent.orphaned);
			Assert.assertFalse(orphanParent.orphaned);
			Assert.assertFalse(orphanChild.orphaned);
		}
		
		[Test(description="Ensures that all nodes in a tree are orphaned when the tree's root is removed from its parent")]
		public function attachedTreeOrphanedOnParentRemoved():void
		{
			var orphanGrandParent:ParentNode = new ParentNode(this._document);
			var orphanParent:ParentNode = new ParentNode(this._document);
			var orphanChild:ParentNode = new ParentNode(this._document);
			
			orphanGrandParent.appendChild(orphanParent);
			orphanParent.appendChild(orphanChild);
			this._document.appendChild(orphanGrandParent);
			
			Assert.assertFalse(orphanGrandParent.orphaned);
			Assert.assertFalse(orphanParent.orphaned);
			Assert.assertFalse(orphanChild.orphaned);
			
			orphanParent.removeChild(orphanChild);
			Assert.assertTrue(orphanChild.orphaned);
			Assert.assertFalse(orphanParent.orphaned);
			Assert.assertFalse(orphanGrandParent.orphaned);
			
			orphanGrandParent.removeChild(orphanParent);
			Assert.assertTrue(orphanChild.orphaned);
			Assert.assertTrue(orphanParent.orphaned);
			Assert.assertFalse(orphanGrandParent.orphaned);
			
			// Now re-add and try orphaning the tree in one go
			orphanGrandParent.appendChild(orphanParent);
			orphanParent.appendChild(orphanChild);
			
			Assert.assertFalse(orphanChild.orphaned);
			Assert.assertFalse(orphanParent.orphaned);
			Assert.assertFalse(orphanGrandParent.orphaned);
			
			this._document.removeChild(orphanGrandParent);
			
			Assert.assertTrue(orphanChild.orphaned);
			Assert.assertTrue(orphanParent.orphaned);
			Assert.assertTrue(orphanGrandParent.orphaned);
		}
		
	}
}