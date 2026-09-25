vim9script
# add_import.vim - Insert import/use statements for Perl, Python and Java
# Maintainer: ufotofu@whistlinglemons.com

if exists('g:loaded_add_import')
  finish
endif
g:loaded_add_import = true

import autoload 'add_import.vim'

# :AddImport {spec}
#   python: {spec} is a module path       -> import {spec}
#   java:   {spec} is a fully-qualified class name, or a short class name
#           found in the class map        -> import {spec};
#   perl:   {spec} is a package name      -> use {spec};
#   With no argument, the WORD under the cursor is used.
#
# :AddImport {module} {name} [{name2} ...]
#   python: from {module} import {name}[, {name2} ...]
#   perl:   use {module} qw({name} [{name2} ...]);
#   (not supported for java; see :AddImportStatic)
command -nargs=* AddImport add_import.Add(<f-args>)

# :AddImportStatic {class} {member}
#   java: import static {class}.{member};
command -nargs=+ AddImportStatic add_import.AddStatic(<f-args>)

nnoremap <silent> <Plug>(add-import) <ScriptCmd>add_import.Add()<CR>

if !hasmapto('<Plug>(add-import)') && !get(g:, 'add_import_no_mappings', false)
  nmap <unique> <Leader>ai <Plug>(add-import)
  nmap <unique> ;i :AddImport<SPACE>
endif
