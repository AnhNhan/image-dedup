
module image.dhash;

import image.scaling.bilinear;
import image.view;

// pure:
// @safe:
// nothrow:

enum dhash_size
{
    w = 8
  , h = 9
}

bool[downsized_w * (downsized_h - 1) - 1] generate_dhash(View, size_t downsized_w = dhash_size.w, size_t downsized_h = dhash_size.h)(View v)
    if (isView!View)
{
    typeof(return) dhash_bitfield;
    alias GreyColor = typeof(v[0, 0].r);
    GreyColor[downsized_w * (downsized_h - 1)] greyscale_field;

    auto downsized_view = v.bilinear(downsized_w, downsized_h);

    foreach (w; 1..downsized_w)
    {
        foreach (h; 0..downsized_h)
        {
            immutable pos = (w - 1) * downsized_h + h + 1;
            const pix = downsized_view[w, h];
            // TODO: For better hash performance, convert to greyscale before downscaling
            greyscale_field[pos] = (pix.r + pix.g + pix.b) / 3;
            bool _bit;
            _bit = greyscale_field[pos - 1] < greyscale_field[pos];
            dhash_bitfield[pos - 1] = _bit;
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
