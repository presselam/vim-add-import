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

def IsUseLine(theLine: string): bool
  return theLine =~# '^\s*use\s\+\S\+.*;\s*$'
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
  return matchstr(theLine, '^\s*use\s\+\zs[[:alnum:]_:.]\+')
enddef

def Insert(text: string, module: string)
  if search('^\s*' .. escape(text, '\/.*$^~[]') .. '\s*$', 'nw') != 0
    add_import.AlreadyPresent(text)
    return
  endif

  var isPragma = IsPragma(module)
  var pkg = PackageLine()
  var start = pkg > 0 ? pkg + 1 : 1
  var [bstart, bend] = FindBlock(start)

  if bstart == 0
    var anchor = pkg > 0 ? pkg : 0
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
  Insert('use ' .. module .. ' qw(' .. join(names, ' ') .. ');', module)
enddef
