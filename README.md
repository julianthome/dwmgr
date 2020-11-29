# dwmgr - a simple configuration manager for suckless tools

dwmgr is configuration manager for various [suckless tools](https://suckless.org/) 
such as [DWM](https://dwm.suckless.org/) and [dmenu](https://tools.suckless.org/dmenu/).

The suckless tools are customized through patches which can be difficult to
handle without version control especially during the initial experimentation
phase in which different features are combined.

dwmgr is supposed to help with this task by importing all the patches in a
personal git repository. Every features gets its own branch; the branches can
then be arbitrarily combined in a personal git branch. This makes it very easy
to merge, store and share personal DWM, dmenu setups, to keep track of changes
and to easily update configurations by just pulling the changes from the
official DWM git repository. 

# Usage

The `h` option will show you all available options.

```
>>  ./dwmgr.sh
       -h : print help
       -d : absolute path to custom dependency file (default deps.csv)
       -s [dwm|dmenu]: set up a private repository. Patches are automatically fetched
            and applied. every patch is applied on its own branch
       -r [dwm|dmenu]: reset private repostirory (CAUTION: this will delete all branches
            and reset the copy of your private repository)
```

## Build basic configuration repository

If you run `./dwmgr.sh -s dwm`, the tool will create a personal `my-dwm` git
repository that contains all the feature branches by applying the patches
listed in `[dwm|dmeny]-deps.csv`, dependency files where the first column is
the main patch (that corresponds to a branch) followed by the patches it
depends on.

After running `./dwmgr.sh -s dwm` (for DWM) and/or `./dwmgr.sh -s dmenu` (for
dmenu), you should be able to see the different features branches by after
running `(cd my-dwm && git branch -l)`.

## Manage your own, personal config

The example below shows how you can combine different branches to build your
own personal DWM configuration. The process for dmenu is identical with the
only difference that the git repository for dmenu is `my-dmenu` instead of
`my-dwm` and the branch names may differ.

```
# switch into my-dwm git repostory
cd my-dwm
# build you own configuration branch
git checkout -b my-dwm
# merge in your configurations and resolve conflicts
git merge dwm-uselessgap-6.2
# ...
git merge dwm-rotatestack-20161021-ab9571b
# Check build
make
```

# License

The MIT License (MIT)

Copyright (c) 2020 Julian Thome <julianthome@pm.me>

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
of the Software, and to permit persons to whom the Software is furnished to do
so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

