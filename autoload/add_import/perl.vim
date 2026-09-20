vim9script
# add_import/perl.vim - insert "use Module;" statements
#
# Pragmas (strict, warnings, ...) are kept as a group before other module
# "use" statements, matching common Perl style.

import autoload 'add_import.vim'

const pragmas: list<string> = ['strict', 'warnings', 'feature', 'utf8', 'lib', 'vars',
  'constant', 'base', 'parent', 'integer', 'bytes', 'diagnostics']

def IsPragma(module: string): bool
  return index(pragmas, module) >= 0 || module =~# '^v\?5\.'
enddef

def PackageLine(): number
  var last = line('$')
  for i in range(1, min([last, 20]))
    if getline(i) =~# '^\s*package\s\+[[:alnum:]_:]\+\s*;'
      return i
    endif
  endfor
  return 0
enddef

# Line to start looking for the use block from, and to anchor a brand new
# one after, when there is no package statement: right after a shebang
# line if present, otherwise the top of the file.
def HeaderEnd(): number
  if getline(1) =~# '^#!'
    return 2
  endif
  return 1
enddef

# "no Module;" (e.g. "no warnings 'uninitialized';") is treated the same
# as "use Module;" for block detection: it commonly appears interspersed
# with use statements, and leaving it unrecognized would fragment the
# block and misplace anything inserted after it.
def IsUseLine(theLine: string): bool
  return theLine =~# '^\s*\%(use\|no\)\s\+\S\+.*;\s*$'
enddef

def FindBlock(start: number): list<number>
  var last = line('$')
  var i = start
  var first = 0
  while i <= last
    var theLine = getline(i)
    if IsUseLine(theLine)
      first = i
      break
    elseif theLine =~# '^\s*$'
      i += 1
    else
      break
    endif
  endwhile
  if first == 0
    return [0, 0]
  endif

  var j = first
  var lastUse = first
  while j <= last
    var theLine = getline(j)
    if IsUseLine(theLine)
      lastUse = j
      j += 1
    elseif theLine =~# '^\s*$'
      j += 1
    else
      break
    endif
  endwhile
  return [first, lastUse]
enddef

def LineModule(theLine: string): string
  return matchstr(theLine, '^\s*\%(use\|no\)\s\+\zs[[:alnum:]_:.]\+')
enddef

# Finds an existing "use {module};" or "use {module} qw(...);" line for
# the exact module, regardless of what it currently imports.
def FindModuleLine(module: string): number
  var esc = escape(module, '\/.*$^~[]')
  return search('^\s*use\s\+' .. esc .. '\%(\s\+qw(.*)\)\?\s*;\s*$', 'nw')
enddef

# Adds names to an existing use line's import list instead of adding a
# second line for the same module.
def MergeNames(lnum: number, module: string, names: list<string>)
  var theLine = getline(lnum)
  var existing: list<string> = []
  var qwMatch = matchlist(theLine, 'qw(\(.\{-}\))')
  if len(qwMatch) > 1
    existing = split(qwMatch[1])
  endif

  var merged = copy(existing)
  var addedAny = false
  for n in names
    if index(merged, n) < 0
      add(merged, n)
      addedAny = true
    endif
  endfor

  if !addedAny
    add_import.AlreadyPresent('use ' .. module .. ' qw(' .. join(names, ' ') .. ');')
    return
  endif

  setline(lnum, 'use ' .. module .. ' qw(' .. join(merged, ' ') .. ');')
  echom 'add-import: updated "' .. module .. '" import list'
enddef

def Insert(text: string, module: string)
  if search('^\s*' .. escape(text, '\/.*$^~[]') .. '\s*$', 'nw') != 0
    add_import.AlreadyPresent(text)
    return
  endif

  var isPragma = IsPragma(module)
  var pkg = PackageLine()
  var start = pkg > 0 ? pkg + 1 : HeaderEnd()
  var [bstart, bend] = FindBlock(start)

  if bstart == 0
    var anchor = pkg > 0 ? pkg : HeaderEnd() - 1
    var lines = pkg > 0 ? ['', text] : [text, '']
    append(anchor, lines)
    echom 'add-import: added "' .. text .. '"'
    return
  endif

  var pos = bend
  var i = bstart
  var placed = false
  while i <= bend
    var theLine = getline(i)
    var lineIsPragma = IsPragma(LineModule(theLine))
    if isPragma && !lineIsPragma
      pos = i - 1
      placed = true
      break
    endif
    if !isPragma && lineIsPragma
      i += 1
      continue
    endif
    if lineIsPragma == isPragma
      if add_import.CmpCi(theLine, text) > 0
        pos = i - 1
        placed = true
        break
      endif
    endif
    i += 1
  endwhile
  if !placed
    pos = bend
  endif

  append(pos, text)
  echom 'add-import: added "' .. text .. '"'
enddef

export def Add(spec: string)
  var module = matchstr(spec, '^\S\+')
  Insert('use ' .. spec .. ';', module)
enddef

export def AddFrom(module: string, names: list<string>)
  var lnum = FindModuleLine(module)
  if lnum != 0
    MergeNames(lnum, module, names)
    return
  endif
  Insert('use ' .. module .. ' qw(' .. join(names, ' ') .. ');', module)
enddef
