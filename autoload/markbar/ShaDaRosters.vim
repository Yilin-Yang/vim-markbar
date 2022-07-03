""
" @dict ShaDaRosters
" Store for mark names that are read from/stored in viminfo/ShaDa.
"
" Stores mark name 'rosters': dicts between mark chars and names for those
" marks. Has two main member variables: a roster for global marks (file marks
" and numbered marks), and a dict between absolute filepaths and local mark
" rosters for those files.
"
" Class users will use all-caps global variables to store the global mark
" roster and local mark rosters in viminfo/ShaDa. Those variables will persist
" between vim editor sessions.
"
" Because ShaDa/viminfo is read after plugin initialization (see
" |initialization|, ShaDaRosters's contents must be lazy-loaded from those
" global variables.
"
" ShaDaRosters indexes by absolute filepaths while @dict(MarkbarModel) indexes
" by |bufnr()|. Those filepaths may not be open on startup, so they won't have a
" |bufnr()|. Rather than having @dict(MarkbarModel) associate filepaths and
" bufnrs, we keep it and ShaDaRosters separate.
"
" On VimLeave, the 'new' set of |v:oldfiles| for which vim will store marks
" can be updated by invoking :rshada! or r:viminfo!. Local mark rosters will
" only be stored for files in the 'new' v:oldfiles, to ensure that we don't
" store names for marks that vim will 'forget' on next startup. This also
" helps to ensure that the mark rosters are small enough to fit in
" |shada-s|/|viminfo-s|.

let s:ShaDaRosters = {
    \ 'TYPE': 'ShaDaRosters',
    \ '_global_marks_to_names': {},
    \ '_filepaths_to_rosters': {},
\ }

""
" Construct a ShaDaRosters object.
function! markbar#ShaDaRosters#New() abort
    let l:new = deepcopy(s:ShaDaRosters)
    return l:new
endfunction

""
" Populate ShaDaRosters object with mark names from viminfo/ShaDa.
" {global_roster} keys are mark chars and values are mark names.
" {local_rosters} keys are absolute filepaths, and values are rosters (mark
" chars as keys, mark names as values).
function! markbar#ShaDaRosters#populate(global_roster, local_rosters) abort dict
    call markbar#ensure#IsDictionary(a:global_roster)
    call markbar#ensure#IsDictionary(a:local_rosters)
    call extend(l:self._global_marks_to_names, a:global_roster, 'force')
    call extend(l:self._filepaths_to_rosters, a:local_rosters, 'force')
endfunction
let s:ShaDaRosters.populate = function('markbar#ShaDaRosters#populate')

""
" Write global roster into {new_global_roster}. Write local rosters for files
" in {new_oldfiles_list} into {new_local_rosters}.
function! markbar#ShaDaRosters#writeRosters(new_oldfiles, new_global_roster,
                                          \ new_local_rosters) abort dict
    call markbar#ensure#IsList(a:new_oldfiles)
    call markbar#ensure#IsDictionary(a:new_global_roster)
    call markbar#ensure#IsDictionary(a:new_local_rosters)

    " empty output dicts
    call filter(a:new_global_roster, 0)
    call filter(a:new_local_rosters, 0)

    call extend(a:new_global_roster, l:self._global_marks_to_names)

    for l:filepath in a:new_oldfiles
        let l:filepath = fnamemodify(l:filepath, ':p')
        let l:local_rosters = get(l:self._filepaths_to_rosters, l:filepath,
                                \ v:null)
        if empty(l:local_rosters)
            continue
        endif
        let a:new_local_rosters[l:filepath] = l:local_rosters
    endfor
endfunction
let s:ShaDaRosters.writeRosters = function('markbar#ShaDaRosters#writeRosters')

""
" Type-check {mark_char} and {filepath}.
"
" Throw an exception if {filepath} is 0 (denoting the global roster) and
" {mark_char} is a local mark, or if {filepath} is non-null (denoting a local
" mark roster) and {mark_char} is a global mark.
function! s:ValidateMarkCharForFilepath(mark_char, filepath) abort
    call markbar#ensure#IsMarkChar(a:mark_char)
    if a:filepath is 0
        if markbar#helpers#IsGlobalMark(a:mark_char)
            return
        endif
        throw printf('Gave non-global mark %s when accessing global roster.',
                   \ a:mark_char)
    else
        call markbar#ensure#IsString(a:filepath)
        if !markbar#helpers#IsGlobalMark(a:mark_char)
            return
        endif
        throw printf('Gave global mark %s when accessing local roster for %s',
                   \ a:mark_char, a:filepath)
    endif
endfunction

""
" Return a local roster for the {filepath}, or the global roster if {filepath}
" is 0. Default-initialize a roster if none exists.
function! markbar#ShaDaRosters#rosterFor(filepath) abort dict
    if a:filepath isnot 0
        call markbar#ensure#IsString(a:filepath)
    endif
    let l:roster = a:filepath is 0 ?
            \ l:self._global_marks_to_names :
                \ get(l:self._filepaths_to_rosters, a:filepath, v:null)
    if l:roster is v:null
        " no existing local roster for filepath
        let l:roster = {}
        let l:self._filepaths_to_rosters[a:filepath] = l:roster
    endif
    return l:roster
endfunction
let s:ShaDaRosters.rosterFor = function('markbar#ShaDaRosters#rosterFor')

""
" Set {new_name} for {mark_char} in the file {filepath}.
"
" A {filepath} of 0 corresponds to the global mark roster.
" If {new_name} is the empty string, then {mark_char} is removed from the
" roster.
function! markbar#ShaDaRosters#setName(filepath, mark_char, new_name) abort dict
    call s:ValidateMarkCharForFilepath(a:mark_char, a:filepath)
    call markbar#ensure#IsString(a:new_name)
    let l:roster = l:self.rosterFor(a:filepath)
    if !empty(a:new_name)
        let l:roster[a:mark_char] = a:new_name
    else
        if has_key(l:roster, a:mark_char)
            call remove(l:roster, a:mark_char)
        endif
    endif
endfunction
let s:ShaDaRosters.setName = function('markbar#ShaDaRosters#setName')

""
" Returns the name for {mark_char} in the file {filepath}.
"
" A {filepath} of 0 corresponds to the global mark roster.
" Returns an empty string if an entry isn't found.
function! markbar#ShaDaRosters#getName(filepath, mark_char) abort dict
    call s:ValidateMarkCharForFilepath(a:mark_char, a:filepath)
    let l:roster = l:self.rosterFor(a:filepath)
    if l:roster is v:null
        return ''
    endif
    return get(l:roster, a:mark_char, '')
endfunction
let s:ShaDaRosters.getName = function('markbar#ShaDaRosters#getName')

""
" Clone a given local roster to a new filename.
"
" The global roster cannot be modified in this way. {old_filepath} and
" {new_filepath} must be strings.
function! markbar#ShaDaRosters#cloneRosterToNewName(old_filepath,
                                                  \ new_filepath) abort dict
    call markbar#ensure#IsString(a:old_filepath)
    call markbar#ensure#IsString(a:new_filepath)
    let l:roster = deepcopy(l:self.rosterFor(a:old_filepath))
    let l:self._filepaths_to_rosters[a:new_filepath] = l:roster
endfunction
let s:ShaDaRosters.cloneRosterToNewName = function('markbar#ShaDaRosters#cloneRosterToNewName')
