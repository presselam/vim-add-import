vim9script
# add_import.vim - dispatcher shared by all filetype handlers

import autoload 'add_import/python.vim'
import autoload 'add_import/java.vim'
import autoload 'add_import/perl.vim'

export def DefaultSpec(): string
  var w = expand('<cWORD>')
  return matchstr(w, '^[A-Za-z_][A-Za-z0-9_.:]*')
enddef

export def Add(spec: string)
  var ft = &filetype
  var theSpec: string
  if spec != ''
    theSpec = spec
  elseif ft ==# 'python'
    # Python dots are ambiguous between a package path and attribute
    # access (e.g. "json.dumps(...)"), so when guessing from the cursor
    # only the leading segment is safe to use as a module name.
    theSpec = matchstr(DefaultSpec(), '^[^.]*')
  else
    theSpec = DefaultSpec()
  endif

  if theSpec == ''
    echohl ErrorMsg
    echom 'add-import: nothing to import (cursor is not on an identifier, and no argument was given)'
    echohl None
    return
  endif

  if ft ==# 'python'
    python.Add(theSpec)
  elseif ft ==# 'java'
    java.Add(theSpec)
  elseif ft ==# 'perl'
    perl.Add(theSpec)
  else
    echohl ErrorMsg
    echom 'add-import: unsupported filetype "' .. ft .. '" (supported: python, java, perl)'
    echohl None
  endif
enddef

export def AddFrom(module: string, ...names: list<string>)
  if len(names) == 0
    echohl ErrorMsg
    echom 'add-import: usage :AddImportFrom {module} {name} [name2 ...]'
    echohl None
    return
  endif
  var ft = &filetype
  if ft ==# 'python'
    python.AddFrom(module, names)
  elseif ft ==# 'perl'
    perl.AddFrom(module, names)
  else
    echohl ErrorMsg
    echom 'add-import: :AddImportFrom is not supported for filetype "' .. ft .. '"'
    echohl None
  endif
enddef

export def AddStatic(className: string, ...rest: list<string>)
  if len(rest) == 0
    echohl ErrorMsg
    echom 'add-import: usage :AddImportStatic {class} {member}'
    echohl None
    return
  endif
  var ft = &filetype
  if ft ==# 'java'
    java.AddStatic(className, rest[0])
  else
    echohl ErrorMsg
    echom 'add-import: :AddImportStatic is only supported for filetype "java"'
    echohl None
  endif
enddef

# Shared helper: case-insensitive line comparison, used to keep each
# filetype's import block sorted.
export def CmpCi(a: string, b: string): number
  var la = tolower(a)
  var lb = tolower(b)
  if la ==# lb
    return 0
  endif
  return la > lb ? 1 : -1
enddef

export def AlreadyPresent(text: string)
  echom 'add-import: "' .. text .. '" is already present'
enddef
