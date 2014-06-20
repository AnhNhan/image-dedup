
module image.stb;

import image.view;
import stb_image;

pragma(lib, "stb_image.lib");

auto stb_load_ae(string filename)
{
    import std.string;

    int x, y, comp;
    ubyte* loaded = stbi_load(filename.toStringz(), &x, &y, &comp, 3);
    if (loaded is null)
    {
        throw new Exception("Could not read file " ~ filename);
    }
    assert(comp == 3 || comp == 4, "File " ~ filename ~ " has an unsupported color component configuration.");

    const struct StbImage
    {
        ubyte[] src;
        int w, h;
        int comp;

        auto opIndex(int x, int y) const
        {
            assert(x < w && y < h);
            const offset = y * comp * w + x * comp;
            assert(offset < src.length, std.string.format("Offset: %d, Len: %d, Dim: %d:%d, In: %d:%d", offset, src.length, w, h, x, y));
            return RGB(src[offset], src[offset + 1], src[offset + 2]);
        }
    }

    const arr = loaded[0..(x * y * comp)].idup;
    stbi_image_free(loaded);

    return StbImage(arr, x, y, comp);
}
