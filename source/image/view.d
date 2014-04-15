
module image.view;

// Copy-pasta from http://blog.thecybershadow.net/2014/03/21/functional-image-processing-in-d/
// That's some genius stuff there.

/// A view is any type which provides a width, height,
/// and can be indexed to get the color at a specific
/// coordinate.
enum isView(T) =
            is(typeof(T.init.w) : size_t) && // Width
            is(typeof(T.init.h) : size_t) && // Height
            is(typeof(T.init[0, 0])     )    // Color information
        ;

/// Returns the color type of the specified view.
alias ViewColor(T) = typeof(T.init[0, 0]);

/// Views can be read-only or writable.
enum isWritableView(T) =
    isView!T &&
    is(typeof(T.init[0, 0] = ViewColor!T.init));

/// Optionally, a view can also provide direct pixel
/// access. We call these "direct views".
enum isDirectView(T) =
    isView!T &&
    is(typeof(T.init.scanline(0)) : ViewColor!T[]);

/// Mixin which implements view primitives on top of
/// existing direct view primitives.
mixin template DirectView()
{
    alias COLOR = typeof(scanline(0)[0]);

    /// Implements the view[x, y] operator.
    ref COLOR opIndex(int x, int y)
    {
        return scanline(y)[x];
    }

    /// Implements the view[x, y] = c operator.
    COLOR opIndexAssign(COLOR value, int x, int y)
    {
        return scanline(y)[x] = value;
    }
}

/// An in-memory image.
/// Pixels are stored in a flat array.
struct Image(COLOR)
{
    int w, h;
    COLOR[] pixels;

    /// Returns an array for the pixels at row y.
    COLOR[] scanline(int y)
    {
        assert(y>=0 && y<h);
        return pixels[w*y..w*(y+1)];
    }

    mixin DirectView;

    this(int w, int h)
    {
        size(w, h);
    }

    /// Does not scale image
    void size(int w, int h)
    {
        this.w = w;
        this.h = h;
        if (pixels.length < w*h)
            pixels.length = w*h;
    }
}

unittest
{
    static assert(isDirectView!(Image!ubyte));
}
