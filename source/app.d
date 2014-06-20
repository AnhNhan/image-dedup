
import std.algorithm;
import std.array;
import std.datetime;
import std.file;
import std.parallelism;
import std.range;
import std.stdio;
import std.string;
import std.traits;
import std.typecons;

import image.dhash;
import image.scaling.bilinear;
import image.stb;
import image.view;

import imaged.image : Pic = Image, Img, load, IMGError, Pixel, Px;

struct ImageDToAEInterface
{
    Pic src;
    const int w, h;

    auto opIndex(size_t x, size_t y)
    {
        assert(x < w);
        assert(y < h);
        return src[x, y];
    }
}

auto load_img_as_ae(string path)
{
    IMGError err;
    Pic img = load(path, err);

    if (img is null)
    {
        throw new Exception("Could not process " ~ path);
    }
    scope(exit) delete(img);

    // This one is somehow better
    //img.resize(dhash_size.w, dhash_size.h, Pic.ResizeAlgo.BILINEAR);

    return ImageDToAEInterface(img, img.width, img.height);
}

void write_ae_image(V)(string filename, V img)
    if (isView!V)
{
    auto write_img = new Img!(Px.R8G8B8)(img.w, img.h);

    foreach (x; 0..write_img.width)
    {
        foreach (y; 0..write_img.height)
        {
            const pix = img[x, y];
            write_img.setPixel(x, y, Pixel(pix.r, pix.g, pix.b));
        }
    }
    write_img.write("ae.png");
}

auto generate_dhash_for_file(string path)
{
    assert(exists(path));
    assert(isFile(path));

    path.writeln;
    auto ae_img = stb_load_ae(path);
    auto hash = stb_load_ae(path).generate_dhash;
    return tuple(path, hash);
}

auto group(T)(T hashes)
    if (isTuple!(ElementType!T))
{
    ElementType!T[][typeof(ElementType!T.init[1])] groups;
    // Init, kinda hash uniqization
    foreach (const hash; hashes.map!"a[1]")
    {
        groups[hash] = [];
    }

    foreach (const key; groups.keys)
    {
        foreach (tup; hashes)
        {
            if (tup[1].bcmp(key))
            {
                groups[key] ~= tup;
            }
        }
    }

    return groups;
}

bool bcmp(T, U)(T lhs, U rhs, size_t diff = 2)
{
    return lhs.xor(rhs).set_bits < diff;
}

auto xor(T, U)(T lhs, U rhs)
{
    return lhs ^ rhs;
}

auto to_bit_string(ulong num)
{
    char[64] ret;
    foreach (n; 0..64)
    {
        ret[n] = (num & (1 << n)) ? '1' : '0';
    }
    return ret;
}

@property
auto set_bits(ulong num)
{
    size_t ret;
    foreach (n; 0..64)
    {
        if (num & (1 << n))
        {
            ++ret;
        }
    }
    return ret;
}

void print_dhash_of_file(string filename)
{
    stb_load_ae(filename).generate_dhash.to_bit_string.writeln;
}

void scan_for_duplicates(string dir_path)
{
    assert(exists(dir_path), dir_path ~ " does not exist!");
    assert(isDir(dir_path), dir_path ~ " is not a directory!");

    auto img_files = dirEntries(dir_path, "*.{png,jpg}", SpanMode.depth).array;

    if (img_files.empty)
    {
        "No files to be analyzed. Done.".writeln;
        return;
    }

    writeln("Analyzing ", img_files.length, " files.\n");

    auto cpu_count = totalCPUs - 1;

    writeln("Used CPUs: ", cpu_count);
    auto poolInstance = new TaskPool(cpu_count);
    scope(exit) poolInstance.stop();

    StopWatch sw;

    sw.start();

    auto hashes = poolInstance.map!generate_dhash_for_file(img_files);

    sw.stop();

    writeln("\nDone.\n\nTook me ", sw.peek.seconds, "s.");

    auto groups = hashes.group;

    ElementType!(typeof(groups.keys))[] keys_for_removal;
    foreach (key, val; groups)
    {
        if (val.empty)
        {
            keys_for_removal ~= key;
        }
    }
    foreach (key; keys_for_removal)
    {
        groups.remove(key);
    }
    //groups.writeln;
}

int main(string[] args) {
    args.popFront();

    if (args.empty)
    {
        "Error. First argument should be a path.".writeln;
        return 1;
    }

    auto cmd = args.front;
    args.popFront();

    switch (cmd)
    {
        case "dhash":
            args.front.print_dhash_of_file;
            break;
        case "scan":
            args.front.scan_for_duplicates;
            break;
        default:
            break;
    }

    return 0;
}
