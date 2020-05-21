# S H A D O   M A N U A L

This file will eventually be a manual; for now, it's a working
overview of the shado architecture and components, with some fragments
of Python code which show how it works. Read in conjunction with the
Python examples and the javadocs, it should be enough information to
start writing shado-based applications.

## THE RENDERING MODEL

shado is a compositing and sprite library for the monome, written in
Java. It is designed to be driven from a lightweight scripting
language such as Python, and it uses a Java OSC library to talk to the
monome via the SerialOSC driver.

(The Java OSC library is not yet used for input in these examples, for
hysterical reasons; this will change in due course. Our more recent
`fireflash` application (q.v.) does OSC input with this library.)

An application which uses shado will build structures of "frames",
"blocks" and "view ports". These objects know how to present
themselves to a rendering object, which generates the OSC messages for
SerialOSC. The renderer is smart enough to send incremental updates
for a display, to minimise network traffic and load.

The shado library doesn't have things called sprites per se, but any
structure of blocks, frames and view ports can be manipulated and
altered dynamically, in Python (say). If components are moved around
relative to one another, or if their layering order or visibility are
changed, the result is sprite-like animation.

## BLOCKS

A block is a two-dimensional matrix of data values representing monome
lights, or pixels. Each block pixel value (a type we refer to as a
"lamp") can have the obvious value ON or OFF; a lamp can also have the
value THRU (which means "transparent": show whatever is beneath) or
FLIP (invert whatever is beneath). It is possible to render a block
directly to a monome - the block is considered to be sitting on a
black base, so ON and FLIP cause the lamp to light, and OFF and THRU
turn it off.

Here's a simple 4 x 4 square of lights (see the example code for all
the details of the required import statements):

	outputter = SerialOSCBinaryOutputter('localhost', 8080, 8, '/m64')
	renderer = BinaryRenderer(8, 8, outputter)
	block = Block(4, 4).fill(LampState.ON)
	renderer.render(block)

(Aside: we're using the binary (on/off) renderer together with an
outputter which knows the SerialOSC protocol. Other renderers and
outputters support the arc (with variable brightness), and the old
MonomeSerial OSC driver. See the Javadocs for details.)

Block(...).fill(...) sets all pixels in the block. Alternatively,
single pixels can be set (via setLamp()). Block also has a
constructor which takes an ASCII string representing pixel
values (useful for quickly initialising those digital clock
demos):

	block = Block('111 101 101 101 111')

'0' means OFF, '1' means ON, '.' means THRU and '/' means FLIP.  Each
token is a row; the tokens are separated by white space.

## FRAMES

A frame is a stack of blocks, where items at the "top" obscure, or
modify, items lower down. In fact, more generally, a frame is a stack
of "renderables", which may be blocks, view ports (described later),
or other frames. This recursive structure allows a complex animation
(say) to be constructed in a frame, and then for this frame to be
moved around inside an enclosing frame. (This is how the "UFO"
animation sequence works.)

Unlike blocks and view ports, frames do not have dimensions; a frame's
"size" can be considered to be defined by the extents of any blocks or
view ports it, or its sub-frames, contain. The renderer does not care
about the size of frames (or of blocks or view ports, for that
matter): it knows the size of the monome it's addressing, and scans an
area corresponding to the monome's width and height, asking
renderables to deliver their data. (So, an obvious way to hide a block
is to move it beyond the monome's coordinates; there are better ways,
outlined below.)

A frame renders its pixel values from the bottom to the top of its
list; higher items modify what is below. Lamp values of OFF and ON
obscure underlying pixels; THRU passes pixels through unchanged, FLIP
inverts them. The resulting pixel values in a frame still have these
four lamp values, which are then interpreted by any parent frame as
part of its stack of renderables, and so on to the actual frame which
is rendered. The renderer asks this outermost frame or block to "fold"
lamp values to ON or OFF (i.e., render them against black) prior to
transmitting them.

The frame constructor has no arguments, so:

	f = Frame()
	renderer.render(f)

is an easy way to clear a monome (an empty frame renders to black).

Renderables are added using add():

	block = Block(.....)
	Frame.add(block, 2, 3)

This adds a renderable to the *top* of a frame, in this case
offset horizontally by two pixels and vertically by three.

Frame.add() returns the frame itself, allowing cascading:

	Frame.add(b1).add(b2)

A renderable can only be added to any frame once - this is because the
renderable value is used in subsequent operations like show(), hide()
and top(). It is possible to get replicated tiling effects by
creating multiple unique sub-frames (or view ports) over a single
block, and adding these to the main frame. (There's a simple demo
in "Animate.py" which does this.)

A frame allows a few operations on its stack of renderables:

	frame.top(item):	bring a renderable to the top
	frame.bottom(item):	send a renderable to the bottom
	frame.hide(item):	hide a renderable (make it transparent)
	frame.show(item):	show a renderable
	frame.remove(item):	remove a renderable from a frame

And finally, some sprite action:

	frame.moveBy(item, dx, dy):
				move a renderable by this distance
	frame.moveTo(item, x, y):
			    	move a renderable to this location
				relative to the frame's origin

Since the renderables might themselves be frames, all sorts of nested
movement and animation is possible. In addition, hide() and show()
(or, depending on style, bottom() and top()) can be used for
animation: if you want to invert an entire monome, use a frame with
a large

	Block(...).fill(LampState.FLIP)

at the top; hide() and show() calls on it will invert everything. If
you want to switch between a number of different patterns, create them
all in advance, making sure they are all the same size and are opaque
(ON or OFF values only, no THRU or FLIP) and them call frame.top() on
them in sequence. (See Counter.py for an example.)

## VIEW PORTS

ViewPorts provide a simple way to crop blocks or (more likely) frames,
useful if animated sub-frames are being tiled into a larger
system. When a view port is built around a renderable (a block or
frame), the result is a port onto that renderable; anything outside
the port is rendered as LampState.THRU (transparent). There is no
change to the coordinate system of the contents of the port.

ViewPorts are also renderables, and so may be incorporated into
frames, cropped in other ports, and so on.

After:

       p = ViewPort(renderable, x, y, width, height)

the renderable "p" will be the same as `renderable' for pixels whose
column is between x and x+width-1, and whose row is between y and
y+height-1. Outside those coordinates, the pixels of "p" will be
LampState.THRU.

ViewPort objects also expose properties "x", "y", "width" and "height",
so that the cropping dimensions can be changed dynamically:

        p.x = 3
        p.height = p.height - 1

## BUTTON INPUT

The machinery for dealing with button presses works with the same
structures as those used to drive the LEDs. Once a structure of
blocks, frames and view ports has been built to generate output,
button presses can be routed into those same blocks, frames and view
ports. The assumption is that an application which draws some kind of
animated widget with a bit of scripting code will also want to capture
button presses locally in that same portion of code, with sensible
local coordinates, regardless of what else might be going on in the
system at the time.

Here's how it works: the Block and ViewPort classes both implement an
interface called IPressable in the Java world. This means they contain
a method as follows:

	public boolean press(int x, int y, int how);

The Block and ViewPort classes provide a method which does nothing; in
order to respond to button presses, a Block or ViewPort must be
sub-classed and this method overridden. This can obviously be done in
Java, but it can also be done in Python.

When a button is pressed, shado searches a tree of renderables in
order, until it finds one which handles the press; once the press is
handled, the search stops. If the renderable returns true from the
call to press(), then it is considered to have handled the event.

A Block or ViewPort can only handle a button press which falls within
its coordinates; if the button press is outside the renderable's
dimensions then the renderable never sees it.

(This, by the way, is why Frames cannot directly intercept button
presses (they are not IPressables): a Frame does not have an obvious
coordinate range.)

If a Block measuring (width * height) is within range of a press, it
will be passed X and Y coordinates within (0, 0) and (width-1,
height-1). If a ViewPort receives a press, the coordinate (0, 0)
coincides with the top-left corner of the port, rather than (0, 0) in
the port's coordinate system.

A button press can be routed into any renderable: Block, Frame or
ViewPort. (Even though a Frame cannot handle presses directly, it will
pass them on to its children.) There's a class called PressManager
which does this (and which also tracks on and off presses, as we
describe later):

	f = Frame()
	...
	manager = PressManager(f)
	...
	manager.press(x, y, how)

(A PressManager can be built over a completely different structure to
the one being displayed - but in most cases you probably don't want to
do that.)

If the PressManager is constructed around a Block, the routing is
simple: Block.press() gets called with the same coordinates that are
passed in to PressManager.press() - these are presumably coming
directly from the monome.

Sending a press to a ViewPort is slightly more complicated. The
ViewPort might accept the event (by returning true from its press()
method) in which case the event is considered finished. If the
ViewPort returns false, the event is routed into the ViewPort's
*content* - another renderable - with the original coordinates - and
the result is whatever the content renderable returns.

When a press is routed to a Frame, the Frame starts calling into its
stack of children in order, from top to bottom, mapping the
coordinates so that each child sees (0, 0) as top-left. As soon as a
child returns true, the event is over. If any child returns false, the
Frame tries the next, and so on. If all children return false (or if
the Frame is empty), the result is false.

Objects which are hidden in a frame (via frame.hide(...)) will not
receive button presses. (This is a change from the original shado
behaviour.) A Block which is completely transparent (all cell values
are LampState.THRU) *will* receive press() events. There are situations
where this is useful: to capture the raw coordinates of a monome's
buttons regardless of the objects in a frame, just add a monome-sized
transparent layer to the top and use this to deal with the press()
events.

Finally: a note about button presses and releases. If a button press
is routed to an object deep within a visual heirarchy, then that
structure can change dramatically before the button is released. For
example, suppose that a Block receives a button press, and its press()
method actually moves the Block within its enclosing Frame. The button
release could have coordinates different to those of the press; or the
release might be completely out of range of the new location of the
Block.

We have implemented some machinery which guarantees a fundamental
property of button handling: if a renderable receives - and handles -
a button press at coordinates (x, y), then it will always receive the
corresponding release at the same coordinates. It does not matter if
the renderable has been moved out of range of the button - or even if
the renderable has been completely removed from the object heirarchy -
the PressManager keeps hold of it, purely so that the press(x, y, 0)
can be sent to the original recipient of press(x, y, 1).

A side-effect of this is that, if an object chooses to ignore a press
(by returning false from a press(x, y, 1) call) then it will never see
the release call - that call will always go to the actual object which
dealt with the press (if any).

Another side-effect is that an object might receive multiple button-on
presses at the same coordinates. If a press(0, 0, 1) event to a Block
causes it to move, another button on the monome might now map to the
Block's top-left, and might send a second press(0, 0, 1). In other
words, it's quite possible for button-on events to be duplicated in
the same location - and the release events will also be
duplicated. This makes perfect sense to the PressManager so it had
better make sense to your Python scripts.
