
module image.dhash;

import image.scaling.bilinear;
import image.view;

enum dhash_size
{
    w = 9
  , h = 8
}

ulong generate_dhash(View)(in View v)
    if (isView!View)
{
    typeof(return) dhash_bitfield;
    auto downsized_view = v.greyscale.bilinear(dhash_size.w, dhash_size.h);

    foreach (w; 1..dhash_size.w)
    {
        foreach (h; 0..dhash_size.h)
        {
            immutable pos = (w - 1) * dhash_size.h + h + 1;
            bool _bit;
            _bit = downsized_view[w - 1, h].r < downsized_view[w, h].r;
            dhash_bitfield |= (cast(ulong) _bit) << pos;
        }
    }

    return dhash_bitfield;
}

unittest {
    import image.color;
    import image.dummy;

    auto grey(ubyte b)()
    {
        return RGB_8(b, b, b);
    }

    auto img_2x2 = Img!RGB_8([
        [grey!1, grey!2],
        [grey!3, grey!4],
    ]);

    auto img_4x4 = Img!RGB_8([
        [grey!1, grey!1, grey!2, grey!2],
        [grey!1, grey!1, grey!2, grey!2],
        [grey!3, grey!3, grey!4, grey!4],
        [grey!3, grey!3, grey!4, grey!4],
    ]);

    auto dhash1 = img_2x2.generate_dhash();
    auto dhash2 = img_4x4.generate_dhash();

    /*
    import std.stdio;
    import std.conv;

    dhash1.writeln;
    dhash2.writeln;
    assert(dhash1 == dhash2);
    */
}
