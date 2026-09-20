vim9script
# add_import/python.vim - insert "import X" / "from X import Y" statements
#
# Known simplification: only a single, flat, contiguous import block is
# tracked (comments inside the block end it). Pre-existing multi-line
# "from x import (\n    a,\n    b,\n)" statements (import list spread
# across several lines) are not parsed or merged into. This covers the
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

# Finds an existing single-line "from {module} import ...;" line for the
# exact module, whatever it currently imports.
def FindModuleLine(module: string): number
  var esc = escape(module, '\/.*$^~[]')
  return search('^\s*from\s\+' .. esc .. '\s\+import\s\+\S.*$', 'nw')
enddef

# Adds names to an existing from-import's name list instead of adding a
# second line for the same module. Handles a single-line parenthesized
# list, e.g. "from x import (a, b)", preserving the parens; a list split
# across multiple lines is left alone (see the module-level comment).
def MergeNames(lnum: number, module: string, names: list<string>)
  var importsPart = matchstr(getline(lnum), '^\s*from\s\+\S\+\s\+import\s\+\zs.*$')
  var hasParens = importsPart =~# '^(.*)$'
  var inner = hasParens ? substitute(importsPart, '^(\(.*\))$', '\1', '') : importsPart

  var existing: list<string> = []
  for part in split(inner, ',')
    var trimmed = trim(part)
    if trimmed != ''
      add(existing, trimmed)
    endif
  endfor

  var merged = copy(existing)
  var addedAny = false
  for n in names
    if index(merged, n) < 0
      add(merged, n)
      addedAny = true
    endif
  endfor

  if !addedAny
    add_import.AlreadyPresent('from ' .. module .. ' import ' .. join(names, ', '))
    return
  endif

  var newImports = join(merged, ', ')
  if hasParens
    newImports = '(' .. newImports .. ')'
  endif
  setline(lnum, 'from ' .. module .. ' import ' .. newImports)
  echom 'add-import: updated "' .. module .. '" import list'
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
  var lnum = FindModuleLine(module)
  if lnum != 0
    MergeNames(lnum, module, names)
    return
  endif
  Insert('from ' .. module .. ' import ' .. join(names, ', '), true)
enddef
