# Zig itertools

![Zig Tools](https://img.shields.io/static/v1?label=zigtools&message=for%20all%20of%20ziguanity&color=F7A41D&logo=data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAADIAAAAyCAIAAACRXR/mAAAEDklEQVR4nOzYbUwbZRwA8Oe53vXuSltaa2lxc+KKBGcyBhLDgH3SiSMZ++TQRT8uJH4x8S0myL6YmUjUbIkfZvZtX3TJlAwjiYImxuBwa1hEtxAcQ8GFQrtBWXvXu17vTH1ux1lv99IeLcn6//Rw9/D0l+ft/28xsC2jyrISVZaV2KYsfCsGxSDYs5OIhPCAB0tlpFt3hF//yqYyUsVYrQ3Eaz2ew0/Tta7/rENOlCZnuTMTqZHLrJlxoF2ggAf7+FVff2eNfrf+U/HRaMZwNHtmqzGMf/NucNfDxqNFQqY+0QZWYxifGKoL1TrQnzlRGrvKXphio/M8ANLEUKjeL7+aW86e+5EpB4vEwRevBxTTtSX++Gd3rv6ZBQCEfdi3g3VqU8/J1dspsRysd454n3rUidq//MH1Dcc3WEkxNdUTalNsXTYFPNgr3TULcWE0qn0CStryXhoufPqIi8wfusWE0DEYW0sbm9Rvj52Oj1zROAElXacvd7mQCQAwdH4dmdwUNGkCAAwc9GiOXBKrp4VGjcWEcGFKXo6B59wmTQCA7mbSTWmsWEmstsflXfXdTEa8d4e375YfMpx46AM9EwDAgcGWXYSdLAyCkE8+Zdf/5pXnqxs51HCR2Pv9PgxqmJbXckr/HQGHnSx1cNnN9tnvU5msPHXHumvODjy0w194AvqGV5X+bkrDUDxLlPI3J2rXujb3x+9LwoufxNWymY/qC3Ybw22m7cTdnJ0sAMD8ioAaHU+Q6ucTv3FqmXJalRPQHnEqnW/GBJtZk7Mcajy/l/bSUEdWcCqP7pczejItXr+lwSr+lg/7sK5meZIoJ2x5jPhpli+QHTixcvxZd73fcfkGd2Y8hUqu1gbihX0U6vP1NCNqlWFF3vL/v8c7BmMsb/yPXhr+cKJOyVed78VQAi2IYhZRM7eYMflr4MjbQcV0/ue0pqkYln6+o53wwJNkwT5Dl9zR/fTUyXBnk7zuiwnhzXPr9/sUa3vLZA7OZKXxGfbSHJ9kRIqAe3YSB/dS6iIxsZHrG47rFDkW9pb5ukA/ri3xL52+fUPrXlDC7GzZYmI48dTY3eGLG5weyTTLkmluOTs5y3U1k5EQ7vg3I64kc9F5fnwm8/lkGhWJhmHMsmpSvy06DE5iRUwGrEqZ9FgYBF++EayISY91pJ1qu1dnltmkx+ptlev0JCOW2aTH8rvlWvbKPFdmkx5rNSkXjZ1NZGMYL6dJL/kc2kd99VYQtRlOvDTHt0ecys9DW2rKfyO634ubK0J3M9kQzM8TgcPdIZwiYHlMeiwJgNEo+0yjE8mUmF7gD38Y31KTcQWBQdDbSvW20XVex1paHJtmL0ZZzTL3gYht+ktzlWUlqiwrUWVZiX8CAAD//7jyYLmjqPd4AAAAAElFTkSuQmCC)

This is an attempt to port the itertools library from python to zig, in order to introduce a functional
paradigm to the language. Maintains high speed by eliminating temporary allocations, and moving through 
slices using an iterator. The library also includes some constructs such as map, filter and reduce which 
are part of the python builtin library which are essential for functional programming.

And of course, their compile time counterparts!

Suggestions and contributions are welcome.

## Generic Iterator

## Min

## Max

## Reduce

## Map

## Filter

## Accumulate

## Chain
