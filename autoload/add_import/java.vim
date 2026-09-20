vim9script
# add_import/java.vim - insert "import" / "import static" statements
#
# Java imports must be fully qualified. A small built-in map of common
# JDK classes lets short names (e.g. "HashMap") resolve automatically;
# anything else needs a fully-qualified name, or an entry added to
# g:add_import_java_classmap (a Dict merged over the built-in one).

import autoload 'add_import.vim'

var classMap: dict<string> = {
  'ArrayList': 'java.util.ArrayList',
  'ArrayDeque': 'java.util.ArrayDeque',
  'Arrays': 'java.util.Arrays',
  'Collections': 'java.util.Collections',
  'Comparator': 'java.util.Comparator',
  'Deque': 'java.util.Deque',
  'HashMap': 'java.util.HashMap',
  'HashSet': 'java.util.HashSet',
  'Iterator': 'java.util.Iterator',
  'LinkedList': 'java.util.LinkedList',
  'List': 'java.util.List',
  'Map': 'java.util.Map',
  'Objects': 'java.util.Objects',
  'Optional': 'java.util.Optional',
  'PriorityQueue': 'java.util.PriorityQueue',
  'Scanner': 'java.util.Scanner',
  'Set': 'java.util.Set',
  'TreeMap': 'java.util.TreeMap',
  'TreeSet': 'java.util.TreeSet',
  'Collectors': 'java.util.stream.Collectors',
  'Stream': 'java.util.stream.Stream',
  'IOException': 'java.io.IOException',
  'File': 'java.io.File',
  'BufferedReader': 'java.io.BufferedReader',
  'InputStreamReader': 'java.io.InputStreamReader',
  'Path': 'java.nio.file.Path',
  'Paths': 'java.nio.file.Paths',
  'Files': 'java.nio.file.Files',
  'BigDecimal': 'java.math.BigDecimal',
  'BigInteger': 'java.math.BigInteger',
  'LocalDate': 'java.time.LocalDate',
  'LocalDateTime': 'java.time.LocalDateTime',
  'Duration': 'java.time.Duration',
}

def ClassMap(): dict<string>
  return extend(copy(classMap), get(g:, 'add_import_java_classmap', {}))
enddef

def PackageLine(): number
  var last = line('$')
  for i in range(1, min([last, 20]))
    if getline(i) =~# '^\s*package\s\+[[:alnum:]_.]\+\s*;'
      return i
    endif
  endfor
  return 0
enddef

def IsImportLine(theLine: string): bool
  return theLine =~# '^\s*import\s\+\S.*;\s*$'
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

# static imports are kept as a group before regular imports, matching the
# Google Java Style Guide's ordering.
def Insert(text: string, isStatic: bool)
  if search('^\s*' .. escape(text, '\/.*$^~[]') .. '\s*$', 'nw') != 0
    add_import.AlreadyPresent(text)
    return
  endif

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
    var lineStatic = theLine =~# '^\s*import\s\+static\s'
    if !isStatic && lineStatic
      i += 1
      continue
    endif
    if isStatic && !lineStatic
      pos = i - 1
      placed = true
      break
    endif
    if lineStatic == isStatic
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
  var fqcn = spec
  if fqcn !~# '\.'
    var m = ClassMap()
    if has_key(m, fqcn)
      fqcn = m[fqcn]
    else
      echohl ErrorMsg
      echom 'add-import: "' .. spec .. '" is not fully qualified and is not in the known class map; '
        .. 'use e.g. :AddImport java.util.' .. spec .. ' or add it to g:add_import_java_classmap'
      echohl None
      return
    endif
  endif
  Insert('import ' .. fqcn .. ';', false)
enddef

export def AddStatic(className: string, member: string)
  Insert('import static ' .. className .. '.' .. member .. ';', true)
enddef
