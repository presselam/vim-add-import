vim9script
# add_import/python.vim - insert "import X" / "from X import Y" statements
#
# Known simplification: only a single, flat, contiguous import block is
# tracked (comments inside the block end it, and pre-existing multi-line
# "from x import (a, b)" statements are not merged into). This covers the
# common case; anything fancier is left to a dedicated isort-style tool.

import autoload 'add_import.vim'

def HeaderEnd(): number
  var last = line('$')
  var lnum = 1

  if lnum <= last && getline(lnum) =~# '^#!'
    lnum += 1
  endif
  if lnum <= last && getline(lnum) =~# '^\s*#.*coding[:=]\s*[-\w.]\+'
    lnum += 1
  endif

  var scan = lnum
  while scan <= last && getline(scan) =~# '^\s*$'
    scan += 1
  endwhile

  if scan <= last
    var theLine = getline(scan)
    for q in ['"""', "'''"]
      if theLine =~# '^\s*\%(u\|r\|ur\|Ru\|R\)\?' .. q
        var rest = substitute(theLine, '^\s*\%(u\|r\|ur\|Ru\|R\)\?' .. q, '', '')
        if rest =~# q
          return scan + 1
        endif
        var close = scan + 1
        while close <= last && getline(close) !~# q
          close += 1
        endwhile
        return close + 1
      endif
    endfor
  endif

  return lnum
enddef

def IsImportLine(theLine: string): bool
  return theLine =~# '^\s*\%(import\|from\)\s\+\S'
enddef

def FindBlock(start: number): list<number>
  var last = line('$')
  var i = start
  var first = 0
  while i <= last
    var theLine = getline(i)
    if IsImportLine(theLine)
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
  var lastImport = first
  while j <= last
    var theLine = getline(j)
    if IsImportLine(theLine)
      lastImport = j
      j += 1
    elseif theLine =~# '^\s*$'
      j += 1
    else
      break
    endif
  endwhile
  return [first, lastImport]
enddef

# "import X" statements are kept as a group before "from X import Y"
# statements, matching common isort defaults.
def Insert(text: string, isFrom: bool)
  if search('^\s*' .. escape(text, '\/.*$^~[]') .. '\s*$', 'nw') != 0
    add_import.AlreadyPresent(text)
    return
  endif

  var header = HeaderEnd()
  var [bstart, bend] = FindBlock(header)

  if bstart == 0
    append(header - 1, [text, ''])
    echom 'add-import: added "' .. text .. '"'
    return
  endif

  var pos = bend
  var i = bstart
  var placed = false
  while i <= bend
    var theLine = getline(i)
    var lineIsFrom = theLine =~# '^\s*from\s'
    if !isFrom && lineIsFrom
      pos = i - 1
      placed = true
      break
    endif
    if isFrom && !lineIsFrom
      i += 1
      continue
    endif
    if isFrom == lineIsFrom
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

export def Add(module: string)
  Insert('import ' .. module, false)
enddef

export def AddFrom(module: string, names: list<string>)
  Insert('from ' .. module .. ' import ' .. join(names, ', '), true)
enddef
