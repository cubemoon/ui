/* View.dart

	History:
		Mon Jan	9 13:01:36 TST 2012, Created by tomyeh

Copyright (C) 2012 Potix Corporation. All Rights Reserved.
*/

/** An effect for the given view, such as fade-in and slide-out.
 */
typedef void ViewEffect(View view);

/**
 * A view.
 * <p>Notice that if a view implements [IdSpace], it has to override
 * [getFellow] and [bindFellow_]. Please refer to [Section] for sample code.
 * <h3>Eventss</h3>
 * <ul>
 * <li>layout: an instance of [ViewEvent] indicates the layout of this view has been
 * handled.</li>
 * <li>enterDocument: an instanceof [ViewEvent] indicates this view has been
 * added to the document.</li>
 * <li>exitDocument: an instanceof [ViewEvent] indicates this view will be
 * removed from the document.</li>
 * </ul>
 */
class View implements Hashable {
	String _id = "";
	String _uuid;

	View _parent;
	View _nextSibling, _prevSibling;
	//Virtual ID space. Used only if this is root but not IdSpace
	IdSpace _virtIS;

	_ChildInfo _childInfo;
	_EventListenerInfo _evlInfo;
	Map<String, Object> _attrs;

	//the classes; created on demand
	Set<String> _classes;
	//the CSS style; created on demand
	CSSStyleDeclaration _style;
	String _vclass;
	Element _node;

	int _left = 0, _top = 0, _width, _height;
	Offset _innerofs; //rarely used (so saving memory)
	ProfileDeclaration _profile;
	LayoutDeclaration _layout;

	bool _hidden, _inDoc;

	/** Constructor.
	 */
	View() {
		_vclass = "v-View";
	}

	_ChildInfo _initChildInfo() {
		if (_childInfo === null)
			_childInfo = new _ChildInfo();
		return _childInfo;
	}
	_EventListenerInfo _initEventListenerInfo() {
		if (_evlInfo === null)
			_evlInfo = new _EventListenerInfo();
		return _evlInfo;
	}

	/** Returns the UUID of this component, never null.
	 */
	String get uuid() {
		if (_uuid === null)
			_uuid = StringUtil.encodeId(_uuidNext++, viewConfig.uuidPrefix);
		return _uuid;
	}
	static int _uuidNext = 0;

	/** Returns the ID of this view, or an empty string if not assigned.
	 */
	String get id() {
		return _id;
	}
	/** Sets the ID of this view.
	 */
	void set id(String id) {
		if (id === null) id = "";
		if (_id != id) {
			if (id.length > 0)
				_ViewImpl.checkIdSpaces(this, id);
			_ViewImpl.removeFromIdSpace(this);
			_id = id;
			_ViewImpl.addToIdSpace(this);
		}
	}
	/** Searches and returns the first view that matches the given selector.
	 * <p>Notice that, in additions to CSS selector, it also supports
	 * "parent" for identifying the parent, "spaceOwner" for the space owner.
	 * <p>It returns null if selector is null or empty.
	 */
	View query(String selector) {
		switch (selector) {
			case null: case "": return null;
			case "parent": return parent;
			case "spaceOwner":
			  var so = spaceOwner;
			  return so is View ? so: null;
		}
		//TODO: support CSS selector
		if (selector.startsWith('#'))
			return getFellow(selector.substring(1));
	}
	/** Searches and returns all views that matches the selector.
	 */
	Iterable<View> queryAll(String selector) {
		//TODO
	}

	/** Returns the view of the given ID in the ID space this view belongs to,
	 * or null if not found.
	 * <p>If a view implements [IdSpace] must override [getFellow] and
	 * [bindFellow_].
	 */
	View getFellow(String id) => spaceOwner.getFellow(id);
	/** Returns a readoly collection of all fellows in the ID space
	 * that this view belongs to.
	 * <p>Note: don't modify the returned list. Otherwise, the result is
	 * unpreditable.
	 */
	Collection<View> get fellows() => spaceOwner.fellows;
	/** Updates the fellow information.
	 * <p>Default: throw [UnsupportedOperationException].
	 * <p>If a view implements [IdSpace] must override [getFellow] and
	 * [bindFellow_].
	 * <p>If fellow is null, it means to remove the binding.
	 */
	void bindFellow_(String id, View fellow) {
		throw const UnsupportedOperationException ("Not IdSpace");
	}
	/** Returns the owner of the ID space that this view belongs to.
	 * <p>A virtual [IdSpace] is used if this view is a root but is not IdSpace.
	 */
	IdSpace get spaceOwner() => _ViewImpl.spaceOwner(this);

	/** Returns if a view is a descendant of this view or
	 * it is identical to this view.
	 */
	bool isDescendantOf(View parent) {
		for (View w = this; w !== null; w = w.parent) {
			if (w === parent)
				return true;
		}
		return false;
	}
	/** Returns the nearest ancestor who is an instance of the given class,
	 * or null if not found.
	 */
/* TODO: wait until Dart supports reflection
	View getAncestorWith(Class type) {
		for (View p = this; (p = p.parent) !== null;) {
			if (p is type)
				return p;
		}
		return null;
	}
*/
	/** Returns the parent, or null if this view does not have any parent.
	 */
	View get parent() => _parent;
	/** Returns the first child, or null if this view has no child at all.
	 */
	View get firstChild() => _childInfo !== null ? _childInfo.firstChild: null;
	/** Returns the last child, or null if this view has no child at all.
	 */
	View get lastChild() => _childInfo !== null ? _childInfo.lastChild: null;
	/** Returns the next sibling, or null if this view is the last sibling.
	 */
	View get nextSibling() => _nextSibling;
	/** Returns the previous sibling, or null if this view is the previous sibling.
	 */
	View get previousSibling() => _prevSibling;
	/** Returns a list of child views.
	 */
	List<View> get children() {
		final _ChildInfo ci = _initChildInfo();
		if (ci.children === null)
			ci.children = new _SubviewList(this);
		return ci.children;
	}
	/** Returns the number of child views.
	 */
	int get childCount() => _childInfo != null ? _childInfo.nChild: 0;

	/** Callback AFTER a child has been added.
	 * <p>Default: does nothing.
	 */
	void onChildAdded_(View child) {}
	/** Callback when a child is going to be removed.
	 * <p>Default: does nothing.
	 */
	void beforeChildRemoved_(View child) {}
	/** Callback after a child has been removed.
	 * <p>Default: does nothing.
	 */
	void onChildRemoved_(View child) {}
	/** Callback after this view's parent has been changed.
	 */
	void onParentChanged_(View oldParent) {}
	/** Callback before this view's parent is going to change.
	 */
	void beforeParentChanged_(View newParent) {}
	/** Called after the layout of this view has been handled.
	 * <p>Default: does nothing but fire a [ViewEvent] to itself.
	 * The application can listen <code>layout</code> for this event.
	 */
	void onLayout() {
		sendEvent(new ViewEvent(this, "layout"));
	}

	/** Returns whether this view allows any child views.
	 * <p>Default: true.
	 * <p>The deriving class shall override this method
	 * to return false if it doesn't allow any child views.
	 */
	bool isChildable_() => true;

	/** Adds a child.
	 * If [beforeChild] is specified, the child will be inserted before it.
	 * Otherwise, it will be added to the end.
	 */
	void addChild(View child, [View beforeChild]) {
		if (isDescendantOf(child))
			throw new UIException("$child is an ancestor of $this");
		if (!isChildable_())
			throw new UIException("No child allowed in $this");
		_addChild(child, beforeChild);
	}
	void _addChild(View child, View beforeChild, [Element childNode]) {
		if (beforeChild !== null) {
			if (beforeChild.parent !== this)
				beforeChild = null;
			else if (child === beforeChild)
				return; //nothing to change
		}

		final View oldParent = child.parent;
		final bool parentChanged = oldParent !== this;
		if (!parentChanged && beforeChild === child.nextSibling)
			return; //nothing to change

		if (parentChanged)
			child.beforeParentChanged_(this);
		if (oldParent !== null)
			oldParent._removeChild(child, notifyChild:false);

		_ViewImpl.link(this, child, beforeChild);

		if (inDocument) {
			if (childNode !== null) {
				insertChildToDocument_(child, childNode, beforeChild);
			} else {
				insertChildToDocument_(child, child._asHTML(), beforeChild);
				child._enterDocument();
			}
		}

		onChildAdded_(child);
		if (parentChanged)
			child.onParentChanged_(oldParent);
	}

	/** Removes this view from its parent.
	 *
	 * <p>If this view has no parent, [UIException] will be thrown.
	 * Rather, if you'd like to remove [Activity.mainView], assign another view
	 * to [Activity.mainView]. If you'd like to remove a dialog, use [Activity.removeDialog]
	 * instead.
	 *
	 * <p>If the view is in the document ([inDocument] is true), the DOM
	 * element will be removed too. Furthermore, if the view is added back
	 * to the document, a new DOM element will be created to represent the child.
	 *
	 * <p>If you just want to move the child, you can use the so-called
	 * cut-and-paste. It won't re-create the DOM element, so the performance
	 * is better. Please refer to [cut] for more information.
	 * If it is a root view, it will be detached from the document.
	 */
	void removeFromParent() {
		if (parent === null)
			throw new UIException("Unable to remove a root view, $this");
		parent._removeChild(this);
	}
	void _removeChild(View child, [bool notifyChild=true, bool exit=true]) {
		if (child.parent !== this)
			return;

		beforeChildRemoved_(child);
		if (notifyChild)
			child.beforeParentChanged_(null);

		if (inDocument) {
			final Element childNode = child.node; //cache first since not callable after _exitDocument 
			if (exit)
				child._exitDocument();
			removeChildFromDocument_(child, childNode);
		}
		_ViewImpl.unlink(this, child);

		if (notifyChild)
			child.onParentChanged_(this);
		onChildRemoved_(child);
	}

	/** Cuts this view and the DOM elements from its parent.
	 * It is the first step of the so-called cut-and-paste.
	 * Unlike [removeFromParent], the DOM element will be kept intact (though it is
	 * removed from the document). Then, you can attach both the view and DOM
	 * element back by use of [ViewCut.pasteTo]. For example,
	 * <pre><code>view.cut().pasteTo(newParent);</code></pre>
	 *
	 * <p>Since the DOM element is kept intact, the performance is better
	 * then remove-and-add (with [removeFromParent] and [addChild]).
	 * However, unlike remove-and-add, you cannot modify the view after it
	 * is cut (until it is pasted back). Otherwise, the result is unpreditable.
	 *
	 * <p>Notice that, like [removeFromParent], it can't be called if this view
	 * is a root view (i.e., it has no parent).
	 */
	ViewCut cut() => new _ViewCut(this);

	/** Inserts the DOM element of the given [child] view before
	 * the reference view ([beforeChild]).
	 * It is called by {@link #addChild} to attach the DOM elements to the document.
	 * <p>Deriving classes might override this method to modify the HTML content,
	 * such as enclosing with TD, or to insert the HTML content to a different
	 * position.
	 * <p>Notice: if [childInfo] is either a HTML fragment (String) or
	 * a DOM element.
	 */
	void insertChildToDocument_(View child, var childInfo, View beforeChild) {
		if (beforeChild !== null) {
			if (childInfo is Element)
				beforeChild.node.insertAdjacentElement("beforeBegin", childInfo);
			else
				beforeChild.node.insertAdjacentHTML("beforeBegin", childInfo);
		} else {
			if (childInfo is Element)
				innerNode.insertAdjacentElement("beforeEnd", childInfo);
			else
				innerNode.insertAdjacentHTML("beforeEnd", childInfo);
		}
	}
	/** Removes the corresponding DOM elements of the give child from the document.
	 * It is called by [removeFromParent] to remove the DOM elements.
	 */
	void removeChildFromDocument_(View child, Element childNode) {
		childNode.remove();
	}

	/** Returns the DOM element associated with this view.
	 * This method returns null if this view is not bound the DOM, i.e.,
	 * [inDocument] is false.
	 * <p>To retrieve a child element, use the [getNode] method instead.
	 * <p>Notice that the parent view can have the same DOM element as
	 * its child. In other words, you might consider one of them is
	 * <i>virtual</i>. Furthermore, depending on your implementation,
	 * you might have to override [insertChildToDocument_] and/or
	 * [removeChildFromDocument_] if they share the same DOM element.
	 */
	Element get node()
	=> _node !== null ? _node: _inDoc ? (_node=document.query('#' + uuid)): null;
	/** Returns the child element of the given sub-ID.
	 * This method assumes the ID of the child element the concatenation of
	 * uuid, dash ('-'), and subId.
	 */
	Element getNode(String subId) =>
		_inDoc ? document.query(subId != null && subId.length > 0 ?
					 '#' + uuid + '-' + subId: '#' + uuid): null;
	/** Returns if this view has been attached to the document.
	 */
	bool get inDocument() => _inDoc;

	/** Returns the element representing the inner element.
	 * If there is no inner element, this method is the same as [node].
	 * <p>Default: [node].
	 * <p>The inner element is used to place the child views and provide a coordinate
	 * system originating at [innerLeft] and [innerTop] rather than (0, 0).
	 * <p>To support the inner element, the deriving class has to override this method.
	 * And, optionally, override [innerSpacing_] if there is some spacing at the right
	 * or at the bottom. If not all child views are in the inner element, it has to
	 * override [shallLayout_] too.
	 * Please refer to the viewport example for a sample implementation.
	 */
	Element get innerNode() => node;
	/** Adjusts the left, top, width, and/or height of the innerNode.
	 * <p>Default: adjust it based [innerWidth], [innerHeight], and [innerSpacing_].
	 * <p>If the subclass uses the static position and percentage to let the
	 * browser adjust the offset and dimensions automatically, it can
	 * override this method to do nothing (for better performance).
	 * [ScrollView] is a typical example.
	 */
	void adjustInnerNode_([bool bLeft=false, bool bTop=false, bool bWidth=false, bool bHeight=false]) {
		final Element n = node, inner = innerNode;
		if (inner !== n) {
			//sync innerNode's positon and size
			if (bLeft)
				inner.style.left = CSS.px(innerLeft);
			if (bTop)
				inner.style.top = CSS.px(innerTop);
			if (bWidth) {
				int v = new DOMQuery(n).innerWidth - innerSpacing_.width;
				inner.style.width = CSS.px(v > 0 ? v: 0);
			}
			if (bHeight) {
				int v = new DOMQuery(n).innerHeight - innerSpacing_.height;
				inner.style.height = CSS.px(v > 0 ? v: 0);
			}
		}
	}

	/** Adds this view to the document (i.e., the screen that the user interacts with).
	 * All of its descendant views are added too.
	 *
	 * <p>You rarely need to invoke this method directly. In most cases,
	 * you shall invoke [addChild] instead. If you'd like to add a dialog, you shall
	 * use [Activity.addDialog] instead. To make a view as the main view, you shall
	 * set it to [Activity.mainView] instead.
	 *
	 * <p>This method is designed used to mix the use of HTML
	 * elements and views. For example, you can use it if you'd like to add
	 * a view to the content of [TextView] and its derives. For example, you want
	 * replace a portion of [TextView] with a view (, say, to provide some behavior).
	 *
	 * <p>Notice that this method can be called only if this view has no parent.
	 * If a view has a parent, whether it is attached to the document
	 * shall be controlled by its parent.
	 *
	 * <ul>
	 * <li>If [outer] is true, [node] will be replaced. Furthermore, you can specify
	 * [keepId] to whether to use node's ID as view's UUID. By default, UUID won't be
	 * changed. If you specify [keepId] to true, you have to make sure [node]'s ID
	 * is unique in the whole browser window.</li>
	 * <li>If [inner] is true, the view will be added as the last child element of [node].</li>
	 * <li>If neither [outer] nor [inner] is true, you can specify [before] to
	 * a DOM element that the view will be inserted before.</li></ul>
	 */
	void addToDocument(Element node,
	[bool outer=false, bool inner=false, Element before, bool keepId=false]) {
		if (parent !== null || inDocument)
			throw new UIException("No parent allowed, nor attached twice: $this");

		_addToDoc(node, outer, inner, before, keepId);
	}
	void _addToDoc(Element node,
	[bool outer=false, bool inner=false, Element before, bool keepId=false]) {
		if (outer && keepId && node.id)
			_uuid = node.id;

		String html = _asHTML();
		Element p, nxt;
		if (inner) {
			node.innerHTML = html;
			//done (and no need to assign p and nxt)
		} else if (outer) {
			p = node.parent;
			nxt = node.nextElementSibling;
			node.remove();
		} else {
			p = node;
			nxt = before;
		}

		if (nxt !== null)
			nxt.insertAdjacentHTML("beforeBegin", html);
		else if (p !== null)
			p.insertAdjacentHTML("beforeEnd", html);

		_enterDocument();
	}
	/** Removes this view from the document.
	 * All of its descendant views are removed too.
	 *
	 * <p>You rarely need to invoke this method directly. This method is used to undo
	 * the attachment made by [addToDocument].
	 * Like [addToDocument], this method can be called only if this view has no parent.
	 *
	 * <p>If you add a child by [addChild] or [Activity.addDialog], you shall
	 * invoke [removeFromParent] or [Activity.removeDialog] instead.
	 */
	void removeFromDocument() {
		if (parent !== null || !inDocument)
			throw new UIException("No parent allowed, nor detached twice: $this");

		final Element n = node; //store first since _node will be cleared up later
		_exitDocument();
		n.remove();
	}
	/** Binds the view.
	 */
	void _enterDocument() {
		if (_afters == null) _afters = []; //TODO: when Dart supports, initialize it directly in the declaration
		_afters.addLast([]);

		enterDocument_();
		doLayout();

		for (final AfterEnterDocument call in _afters.removeLast()) {
			call(this);
		}
	}
	/** Adds a task to be executed after all [enterDocument_] are called.
	 * <p>Notice that this method can be called only in [enterDocument_].
	 * Furthermore, all tasks scheduled with this method will be queued
	 * and executed righter [enterDocument_] of all views are called.
	 * @exception NullPointerException if this method is not called in [enterDocument_]
	 */
	static void afterEnterDocument_(AfterEnterDocument after) {
		_afters.last().add(after);
	}
	static List<List<AfterEnterDocument>> _afters;
	
	/** Unbinds the view.
	 */
	void _exitDocument() {
		if (inDocument)
			exitDocument_();
	}
	/** Callback when this view is attached to the document.
	 * <p>Default: invoke [enterDocument_] for each child.
	 * <p>Subclass shall call back this method if it overrides this method. 
	 * <p>If the deriving class would like some tasks to be executed
	 * after [enterDocument_] of all new-attached views are called, it can
	 * invoke [afterEnterDocument_] to queue the task.
	 * <p>See also [inDocument] and [invalidate].
	 */
	void enterDocument_() {
		_inDoc = true;
//		ViewUtil._views[uuid] = this;

		adjustInnerNode_(true, true, true, true);

		for (View child = firstChild; child != null; child = child.nextSibling) {
			child.enterDocument_();
		}

		//Listen the DOM element if necessary
		final Element n = node;
		if (_evlInfo !== null && _evlInfo.listeners !== null) {
			final Map<String, List<ViewEventListener>> listeners = _evlInfo.listeners;
			for (final String type in listeners.getKeys()) {
				final DOMEventDispatcher disp = getDOMEventDispatcher_(type);
				if (disp != null && !listeners[type].isEmpty())
					domListen_(n, type, disp);
			}
		}

		sendEvent(new ViewEvent(this, "enterDocument"));
	}
	/** Callback when this view is detached from the document.
	 * <p>Default: invoke [exitDocument_] for each child.
	 * <p>Subclass shall call back this method if it overrides this method. 
	 */
	void exitDocument_() {
		sendEvent(new ViewEvent(this, "exitDocument"));

		//Unlisten the DOM element if necessary
		final Element n = node;
		if (_evlInfo !== null && _evlInfo.listeners !== null) {
			final Map<String, List<ViewEventListener>> listeners = _evlInfo.listeners;
			for (final String type in listeners.getKeys()) {
				if (getDOMEventDispatcher_(type) != null && !listeners[type].isEmpty())
					domUnlisten_(n, type);
			}
		}

		for (View child = firstChild; child != null; child = child.nextSibling) {
			child.exitDocument_();
		}

//		ViewUtil._views.remove(uuid);
		_inDoc = false;
		_node = null; //as the last step since node might be called in exitDocument_
	}

	/** Called when something has changed and caused that the display of this
	 * view has to draw.
	 * It has no effect if it is not attached (i.e., [inDocument] is true).
	 * <p>Notice that, for better performance, the view won't be redrawn immediately.
	 * Rather, it is queued and all queued invalidation will be drawn together later.
	 * If you'd like to rerender it immediately, you can specify [immediate] to true.
	 *
	 * <p>See also [ViewUtil.flushInvalidated], which forces all queued invalidation
	 * to be handle immediately (but you rarely need to call it).
	 */
	void invalidate([bool immediate=false]) {
		if (!immediate) {
			_invalidator.queue(this);
		} else if (inDocument) {
			final Element n = node; //cache it since _exitDocument will clean _node
			_exitDocument();
			_addToDoc(n, outer: true);
		}
	}

	/** Called when something has changed and caused that the layout of this
	 * view is changed.
	 *<p>Notice that, for better performance, the layout will be taken place
	 *immediately. Rather, it is queued and all queued views are handled
	 * together later.
	 * If you'd like to handle all queued layouts, you can invoke
	 * [ViewUtil.flushRequestedLayouts].
	 */
	void requestLayout() {
		layoutManager.queue(this);
	}
	/** Hanldes the layout of this view.
	 * <p>Default: have [Layout] to handle it.
	 * [onLayout] will be called after the layout of the view has been handled.
	 */
	void doLayout([MeasureContext mctx=null]) {
		layoutManager.layout(mctx, this);
	}
	/** Measures the width of this view.
	 * It is called by [doLayout].
	 */
	int measureWidth(MeasureContext mctx)
	=> layoutManager.measureWidth(mctx, this);
	/** Measures the height of this view.
	 * It is called by [doLayout].
	 */
	int measureHeight(MeasureContext mctx)
	=> layoutManager.measureHeight(mctx, this);
	/** Returns whether the given child shall be handled by the layout manager.
	 * <p>Default: return true if the position is absolute.
	 * Notice that, for better performance, it checks only [View.style], and
	 * assumes the position defined in
	 * CSS rules (aka., classes) is <code>absolute</code>.
	 * <p>The deriving class shall override this method if
	 * the deriving class supports an inner element and not all child
	 * elements in the inner element, it shall override this method to skip
	 * the child views <i>not</i> in the inner element.
	 * Please refer to the viewport example for a sample implementation.
	 * <p>Note that, if this method returns false for a child, the layout
	 * manager won't adjust its position and dimension. However, the child's [doLayout]
	 * will be still called to arrange the layout of the child's child views.
	 */
	bool shallLayout_(View child) {
		final String v = child.style.position;
		return v.isEmpty() || v == "absolute";
	}

	/** Generates the HTML fragment for this view and its descendants
	 * to the given string buffer.
	 * <p>See also [invalidate].
	 */
	void draw(StringBuffer out) {
		final String tag = domTag_;
		out.add('<').add(tag);
		domAttrs_(out);
		out.add('>');
		domInner_(out);
		out.add('</').add(tag).add('>');
	}
	/** Returns the HTML tag's name representing this widget.
	 * It is called by [draw]. If you override draw and don't call
	 * back super.draw, this method has no effect.
	 * <p>Default: <code>div</code>.
	 */
	String get domTag_() => "div";

	/**Shortcut of [draw].*/
	String _asHTML() {
		StringBuffer out = new StringBuffer();
		draw(out);
		return out.toString();
	}

	/** Returns if this view is hidden.
	 */
	bool get hidden() => _hidden;
	/** Sets if this view is hidden.
	 */
	void set hidden(bool hidden) {
		_hidden = hidden;

		final Element n = node;
		if (n !== null)
			n.hidden = hidden;
	}

	/** Returns the left position of this view relative to its parent.
	 * <p>Default: 0
	 */
	int get left() => _left;
	/** Sets the left position of this view relative to its parent.
	 */
	void set left(int left) {
		_left = left;

		final Element n = node;
		if (n !== null)
			n.style.left = CSS.px(left);
	}
	/** Returns the top position of this view relative to its parent.
	 * <p>Default: 0
	 */
	int get top() => _top;
	/** Sets the top position of this view relative to its parent.
	 */
	void set top(int top) {
		_top = top;

		final Element n = node;
		if (n !== null)
			n.style.top = CSS.px(top);
	}

	/** Returns the width of this view.
	 * <p>Default: null (up to the system).
	 * <p>To get the real width on the document, use [outerWidth].
	 */
	int get width() => _width;
	/** Sets the width of this view.
	 */
	void set width(int width) {
		_width = width;

		final Element n = node;
		if (n !== null) {
			n.style.width = CSS.px(width);

			adjustInnerNode_(bWidth: true);
		}
	}
	/** Returns the height of this view.
	 * <p>Default: null (up to the system)
	 * <p>To get the real height on the document, use [outerWidth].
	 */
	int get height() => _height;
	/** Sets the height of this view.
	 */
	void set height(int height) {
		_height = height;

		final Element n = node;
		if (n !== null) {
			n.style.height = CSS.px(height);

			adjustInnerNode_(bHeight: true);
		}
	}

	/** Returns the left offset of the origin of the child's coordinate system.
	 * <p>Default: 0.
	 */
	int get innerLeft() => _innerofs !== null ? _innerofs.left: 0;
	/** Returns the top offset of the origin of the child's coordinate system.
	 * <p>Default: 0.
	 */
	int get innerTop() => _innerofs !== null ? _innerofs.top: 0;
	/** Returns the left offset of the origin of the child's coordinate system.
	 * <p>Default: 0.
	 * <p>Whether a view allows the developer to change the origin is up to the view's
	 * spec. By default, it is not supported.
	 * To support it, the view usually introduces an additional DIV to provide
	 * the origin for the child views, and overrides [innerNode] to return it.
	 * Please refer to the viewport example for a sample implementation.
	 */
	void set innerLeft(int left)  {
		if (_innerofs !== null) _innerofs.left = left;
		else _innerofs = new Offset(left, 0);

		adjustInnerNode_(bLeft: true);
	}
	/** Returns the top offset of the origin of the child's coordinate system.
	 * <p>Default: throws [UIException].
	 * <p>Whether a view allows the developer to change the origin is up to the view's
	 * spec. By default, it is not supported.
	 * To support it, the view usually introduces an additional DIV to provide
	 * the origin for the child views, and overrides [innerNode] to return it.
	 * Please refer to the viewport example for a sample implementation.
	 */
	void set innerTop(int top) {
		if (_innerofs !== null) _innerofs.top = top;
		else _innerofs = new Offset(0, top);

		adjustInnerNode_(bTop: true);
	}
	/** Returns the spacing between the inner element and the border.
	 * <p>Default: <code>new Size(innerLeft, innerTop)</code>
	 * <p>Notice: instead of overriding [width] and [height], you
	 * shall override this method if the spacing is more than
	 * [innerLeft] and [innerTop].
	 */
	Size get innerSpacing_() => new Size(innerLeft, innerTop);

	/** Returns the real width of this view shown on the document (never null).
	 * <p>Notice that the performance of this method is not good, if
	 * [width] is null.
	 */
	int get outerWidth()
	=> _width !== null ? _width: inDocument ? new DOMQuery(node).outerWidth: 0;
		//for better performance, we don't need to get the outer width if _width is
		//assigned (because we use box-sizing: border-box)
	/** Returns the real height of this view shown on the document (never null).
	 * <p>Notice that the performance of this method is not good, if
	 * [height] is null.
	 */
	int get outerHeight()
	=> _height !== null ? _height: inDocument ? new DOMQuery(node).outerHeight: 0;
		//for better performance, we don't need to get the outer height if _height is
		//assigned (because we use box-sizing: border-box)
	/** Returns the viewable width of this view, excluding the borders, margins
	 * and scrollbars.
	 * <p>Note: this method returns [width] if [inDocument] is false and [width] is not null.
	 * In other words, it doesn't exclude the border's width if not attached to the document
	 * (for performance reason). However, we might change it in the future, so it is better
	 * not to call this method if the view is not attached.
	 */
	int get innerWidth() {
		final int v = inDocument ? new DOMQuery(innerNode).innerWidth:
			(_width !== null ? _width - innerSpacing_.width: 0);
		return v > 0 ? v: 0;
	}
	/** Returns the viewable height of this view, excluding the borders, margins
	 * and scrollbars.
	 * <p>Note: this method returns [height] if [inDocument] is false and [height] is not null.
	 * In other words, it doesn't exclude the border's height if not attached to the document
	 * (for performance reason). However, we might change it in the future, so it is better
	 * not to call this method if the view is not attached.
	 */
	int get innerHeight() {
		final int v = inDocument ? new DOMQuery(innerNode).innerHeight:
			(_height !== null ? _height - innerSpacing_.height: 0);
		return v > 0 ? v: 0;
	}

	/** Returns the offset of this view relative to the left-top corner
	 * of the document.
	 */
	Offset get documentOffset() {
		final Offset ofs = new Offset(0, 0);
		for (View view = this;;) {
			ofs.left += view.left;
			ofs.top += view.top;
			if (view.style.position == "fixed")
				break; //done (no need to add innerX/innerY since mainView is full screen)

			final View p = view.parent;
			if (p == null) {
				final Offset nofs = new DOMQuery(view.node).documentOffset;
				ofs.left += nofs.left;
				ofs.top += nofs.top;
				break;
			} else {
				view = p;
			}
		}
		return ofs;
	}
	/** Returns the layout instruction of this view.
	 * <p>[layout] intructs how a view shall layout the child views.
	 * In additions, you can specify addition information in individual child
	 * view's [profile].
	 */
	LayoutDeclaration get layout() {
		if (_layout == null)
			_layout = new LayoutDeclarationImpl(this);
		return _layout;
	}
	/** Returns the profile, i.e., the layouot requirement, of this view.
	 * It provides additional information for the parent view to
	 * layout this view.
	 * <p>See also [layout].
	 */
	ProfileDeclaration get profile() {
		if (_profile == null)
			_profile = new ProfileDeclarationImpl(this);
		return _profile;
	}

	/** Retuns the CSS style.
	 */
	CSSStyleDeclaration get style() {
		if (_style === null)
			_style =  new CSSStyleDeclarationImpl(this);
		return _style;
	}

	/** Retuns the view class.
	 */
	String get vclass() => _vclass;
	/** Sets the view class.
	 * <p>Default: empty, but an implementation usually provides a default
	 * class, such as <code>v-TextView</code>. It is used to provide
	 * the default look for this view. If vclass is changed, all the default
	 * styles are gone.
	 */
	void set vclass(String newwc) {
		final String oldwc = _vclass;
		if (oldwc == newwc)
			return; //nothing to do

		_vclass = newwc;

		Element n = node;
		if (n != null) {
			if (!oldwc.isEmpty())
				n.classes.remove(oldwc);
			if (!newwc.isEmpty())
				n.classes.add(newwc);
		}
	}
	/** Returns a readonly list of the additional style classes.
	 */
	Set<String> get classes() {
		if (_classes === null)
			_classes = new Set();
		return _classes;
	}
	/** Adds the give style class.
	 */
	void addClass(String className) {
		classes.add(className);
		Element n = node;
		if (n != null)
			n.classes.add(className);
	}
	/** Removes the give style class.
	 */
	void removeClass(String className) {
		if (_classes != null) {
			_classes.remove(className);
			Element n = node;
			if (n != null)
				n.classes.remove(className);
		}
	}

	/** Ouptuts all HTML attributes used for the DOM element of this view
	 * to the given output.
	 * It is called by [draw], and the deriving class can override it
	 * to provide more attributes. Of course, if you override [draw]
	 * directly, you can decide whether to call this method.
	 */
	void domAttrs_(StringBuffer out,
	[bool noId=false, bool noStyle=false, bool noClass=false]) {
		String s;
		if (!noId && !(s = uuid).isEmpty())
			out.add(' id="').add(s).add('"');
		if (!noStyle) {
			final StringBuffer stylesb = new StringBuffer();
			domStyle_(stylesb);
			if (!stylesb.isEmpty())
					out.add(' style="').add(stylesb).add('"');
		}
		if (!noClass) {
			final StringBuffer classsb = new StringBuffer();
			domClass_(classsb);
			if (!classsb.isEmpty())
				out.add(' class="').add(classsb).add('"');
		}
	}
	/** Outputs the inner content of this widget. It is everything
	 * other than the enclosing tag.
	 * It is called by [draw], and the deriving class can override it to
	 * provide the content it wants. Of course, if you override [draw]
	 * directly, you can decide whether to call this method.
	 * <p>Default: invoke each child view's [draw] sequentially.
	 */
	void domInner_(StringBuffer out) {
		for (View child = firstChild; child !== null; child = child.nextSibling) {
			child.draw(out);
		}
	}
	/** Outputs a list of the CSS classes for the DOM element of this view
	 * to the given output. If there are multiple CSS classes, seperate them
	 * with a space.
	 */
	void domClass_(StringBuffer out, [bool noVclass=false, bool noClass=false]) {
		out.add("v-");
		if (!noVclass)
			out.add(' ').add(vclass);
		if (!noClass && _classes != null) {
			for (final String cls in _classes) {
				out.add(' ').add(cls);
			}
		}
	}
	/** Output the CSS style for the DOM element of this view to the given outout.
	 */
	void domStyle_(StringBuffer out, [bool noLeft=false, bool noTop=false,
	bool noWidth=false, bool noHeight=false, bool noHidden=false,
	bool noStyle=false]) {
		if (!noLeft && left != 0)
			out.add("left:").add(left).add("px;");
		if (!noTop && top != 0)
			out.add("top:").add(top).add("px;");
		if (!noWidth && _width !== null) //don't use width since it has special handling
			out.add("width:").add(_width).add("px;");
		if (!noHeight && _height !== null) //don't use height since it has special handling
			out.add("height:").add(_height).add("px;");
		if (!noHidden && hidden)
			out.add("display:none;");
		String s;
		if (!noStyle && _style !== null && !(s = _style.cssText).isEmpty())
			out.add(s);
	}

	/** Returns [ViewEvents] for adding or removing event listeners.
	 */
	ViewEvents get on() {
		final _EventListenerInfo ei = _initEventListenerInfo();
		if (ei.on === null)
			ei.on = new ViewEvents(this);
		return ei.on;
	}
	/** Adds an event listener.
	 * <code>addEventListener("click", listener)</code> is the same as
	 * <code>on.click.add(listener)</code>.
	 */
	void addEventListener(String type, ViewEventListener listener) {
		if (listener == null)
			throw const UIException("listener required");

		final _EventListenerInfo ei = _initEventListenerInfo();
		if (ei.listeners == null)
			ei.listeners = {};

		bool first;
		ei.listeners.putIfAbsent(type, () {
			first = true;
			return [];
		}).add(listener);

		Element n;
		DOMEventDispatcher disp;
		if (first && (n = node) != null
		&& (disp = getDOMEventDispatcher_(type)) != null)
			domListen_(n, type, disp);
	}

	/** Removes an event listener.
	 * <code>addEventListener("click", listener)</code> is the same as
	 * <code>on.click.remove(listener)</code>.
	 */
	bool removeEventListener(String type, ViewEventListener listener) {
		List<ViewEventListener> ls;
		bool found = false;
		if (_evlInfo !== null && _evlInfo.listeners !== null
		&& (ls = _evlInfo.listeners[type]) != null) {
			int j = ls.indexOf(listener);
			Element n;
			if (j >= 0) {
				found = true;

				ls.removeRange(j, 1);
				if (ls.isEmpty() && (n = node) != null
				&& getDOMEventDispatcher_(type) != null)
					domUnlisten_(n, type);
			}
		}
		return found;
	}
	/** Sends an event to this view.
	 * <p>Example: <code>view.sendEvent(new ViewEvent(target, "click"))</code>.
	 * If the type parameter is not specified, it is assumed to be [ViewEvent.type].
	 * <p>To broadcast an event, please use [broadcaster] instead.
	 */
	bool sendEvent(ViewEvent event, [String type]) {
		if (type == null)
			type = event.type;

		List<ViewEventListener> ls;
		bool dispatched = false;
		if (_evlInfo !== null && _evlInfo.listeners != null
		&& (ls = _evlInfo.listeners[type]) != null) {
			event.currentTarget = this;
			//Note: we make a copy of ls since listener might remove other listeners
			//It means the removing and adding of listeners won't take effect until next event
			for (final ViewEventListener listener in new List.from(ls)) {
				dispatched = true;
				listener(event);
				if (event.propagationStopped)
					return true; //done
			}
		}
		return dispatched;
	}
	/** Posts an event to this view.
	 * Unlike [sendEvent], [postEvent] puts the event in a queue and returns
	 * immediately. The event will be handled later.
	 */
	void postEvent(ViewEvent event, [String type]) {
		window.setTimeout(() {sendEvent(event, type);}, 0);
			//note: the order of messages is preserved across all views (and message queues)
			//CONSIDER if it is better to have a queue shared by views/message queues/broadcaster
	}

	/** Returns if there is any event listener registered to the given type.
	 */
	bool isEventListened(String type) {
		List<ViewEventListener> ls;
		return _evlInfo !== null && _evlInfo.listeners != null
			&& (ls = _evlInfo.listeners[type]) != null && !ls.isEmpty();
	}
	/** Returns if the given event type is a DOM event.
	 * If true, [domListen_] will be invoked to register the DOM event.
	 */
	DOMEventDispatcher getDOMEventDispatcher_(String type)
	=> _ViewImpl.getDOMEventDispatcher(type);

	/** Listen the given event type.
	 */
	void domListen_(Element n, String type, DOMEventDispatcher disp) {
		final EventListener ln = disp(this); //must be non-null
		final _EventListenerInfo ei = _initEventListenerInfo();
		if (ei.domListeners === null)
			ei.domListeners = {};
		ei.domListeners[type] = ln;
		n.on[type].add(ln);
	}
	/** Unlisten the given event type.
	 */
	void domUnlisten_(Element n, String	type) {
		if (_evlInfo !== null) {
			final EventListener ln = _evlInfo.domListeners.remove(type);
			if (ln !== null)
				n.on[type].remove(ln);
		}
	}

	/** Returns the value of the given attribute, or null if not assigned.
	 */
	Object getAttribute(String name) {
		return _attrs !== null ? _attrs[name]: null;
	}
	/** Returns if the given attribute has been assigned with a value
	 * (including null).
	 */
	bool hasAttribute(String name) {
		return _attrs !== null && _attrs.containsKey(name);
	}
	/** Sets the value to the given attribute.
	 */
	void setAttribute(String name, Object value) {
		if (_attrs == null)
			_attrs = new Map();
		_attrs[name] = value;
	}
	/** Remove the given attribute.
	 */
	void removeAttribute(String name) {
		if (_attrs !== null) _attrs.remove(name);
	}

	int hashCode() => uuid.hashCode(); //uuid is immutiable once assigned
	String toString() => "View(${id.isEmpty() ? uuid: id})";
}
