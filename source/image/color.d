
module image.color;

import std.traits : isIntegral;

pure:
@safe:

struct RGB(T)
    if (isIntegral!T)
{
    T r, g, b;

    alias self_t = typeof(this);

    this(in T x, in T y, in T z) const
    {
        r = x;
        g = y;
        b = z;
    }

    this(in T c) const
    {
        r = g = b = c;
    }

    @property
    T greyscale_single_channel() const
    {
        return (r + g + b) / 3;;
    }

    @property
    self_t to_greyscale() const
    {
        return self_t(this.greyscale_single_channel);
    }

    @property
    bool is_greyscale() const
    {
        return r == g && g == b;
    }
}

struct HSL(T)
    if (isIntegral!T)
{
    T h, s, l;

    this(in T x, in T y, in T z)
    {
        h = x;
        s = y;
        l = y;
    }
}

alias RGB_8 = RGB!ubyte;
alias RGB_32 = RGB!uint;

alias HSL_8 = HSL!ubyte;
alias HSL_32 = HSL!uint;

unittest {
    // We can discern between these type, yay!
    static assert(!is(RGB_8 : HSL_8));
    static assert(!is(HSL_8 : RGB_8));
    static assert(!is(HSL_8 == RGB_8));
}
