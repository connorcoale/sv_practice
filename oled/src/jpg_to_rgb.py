#!/usr/bin/python3

from PIL import Image

im = Image.open('shrek_resize.jpg')
pixels = list(im.getdata())
print(pixels)

# 8 bit color data per pixel. [RRRGGGBB]
# each pixel in array pixels has 8 bits for each color.
out = list();

for pixel in pixels:
    (r,g,b) = pixel
    r = (r >> 5) << 5
    g = (g >> 5) << 2
    b = (b >> 6)
    out.append(hex(r + g + b))

print(out)
print(len(out))

with open('test_image.hex', 'w') as f:
    for word in out:
        f.write(word + '\n')

