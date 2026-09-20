# vim-add-import

Insert `import`/`use` statements for Python, Java and Perl, sorted into
the right place and grouped the way each language's tooling conventionally
expects.

Written in Vim9 script; requires **Vim 9.0+**. Does not run under Neovim
(no Vim9 script support there).

## Install

With [vim-plug](https://github.com/junegunn/vim-plug):

```vim
Plug 'ufotofu/vim-add-import'
```

With a native Vim 8 / Neovim package manager, clone into
`~/.vim/pack/plugins/start/vim-add-import` (or the Neovim equivalent).

## Usage

```vim
:AddImport os.path                    " python: import os.path
:AddImport java.util.HashMap          " java:   import java.util.HashMap;
:AddImport HashMap                    " java:   resolved via a built-in class map
:AddImport POSIX                      " perl:   use POSIX;
:AddImport Scalar::Util qw(blessed)   " perl:   use Scalar::Util qw(blessed);

:AddImportFrom os.path join           " python: from os.path import join
:AddImportFrom collections OrderedDict  " python: from collections import OrderedDict
:AddImportFrom Scalar::Util blessed reftype  " perl: use Scalar::Util qw(blessed reftype);

:AddImportStatic java.util.Collections emptyList
                                       " java: import static java.util.Collections.emptyList;
```

Run `:AddImport` with no argument to import whatever is under the cursor.
Normal-mode mappings are provided for that:

```vim
nmap <Leader>ai <Plug>(add-import)
nmap ;i         <Plug>(add-import)
```

(set automatically on `<Leader>ai` and `;i` unless you already mapped
`<Plug>(add-import)` yourself, or set `g:add_import_no_mappings = 1`).

Each command finds the file's existing import block, skips exact
duplicates, and inserts the new line in sorted position — `import` before
`from` in Python, static imports before regular ones in Java, pragmas
before other modules in Perl. If no import block exists yet, one is
created in the conventional spot (after the module docstring in Python,
after the `package` statement in Java/Perl).

See `:help add-import` for the full command reference, placement rules,
configuration (`g:add_import_java_classmap` to teach it more Java short
names), and known limitations.

## License

Same terms as Vim itself.
