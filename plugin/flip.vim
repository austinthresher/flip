"Copyright (c) 2020 Austin Thresher
"
" MIT License
"
" Permission is hereby granted, free of charge, to any person obtaining
" a copy of this software and associated documentation files (the
" "Software"), to deal in the Software without restriction, including
" without limitation the rights to use, copy, modify, merge, publish,
" distribute, sublicense, and/or sell copies of the Software, and to
" permit persons to whom the Software is furnished to do so, subject to
" the following conditions:
"
" The above copyright notice and this permission notice shall be
" included in all copies or substantial portions of the Software.
"
" THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
" EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
" MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
" NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
" LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
" OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
" WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

if exists('g:flip_loaded') | finish | endif
let g:flip_loaded = v:true

if !exists('g:flip_default_width')
    let g:flip_default_width = 66
endif

if !exists('g:flip_min_name_chars')
    let g:flip_min_name_chars = 8
endif

if !exists('g:flip_map_keys')
    let g:flip_map_keys = v:true
endif

if !exists('g:flip_left_char')
    let g:flip_left_char = '['
endif

if !exists('g:flip_right_char')
    let g:flip_right_char = ']'
endif

function! s:EchoSpace()
    if has('patch1913') || has('nvim')
        return v:echospace
    endif
    return g:flip_default_width
endfunction

" Easy buffer switching and display
function! g:Flip_ShowInfo()
    if bufname() =~ '^term://'
        " Fixes a bug with nvim terminal cursor display
        return
    endif
    let l:names = []
    let l:bufs = getbufinfo({'buflisted':1})
    " Without this, we get the Press Enter prompt
    let l:chars = s:EchoSpace() / len(l:bufs)
    if l:chars < g:flip_min_name_chars
        let l:chars = g:flip_min_name_chars
    endif
    let l:found_current = v:false
    for buf in l:bufs
        let l:name = l:buf['name']
        " This used to check using has('win32'), but the slash used is
        " inconsistent depending on the shell being used. This isn't
        " perfect but seems to give decent results
        let l:bslash = count(l:name, '\')
        let l:fslash = count(l:name, '/')
        if l:bslash > l:fslash 
            let l:items = split(l:name, '\')
        else
            let l:items = split(l:name, '/')
        endif
        if len(l:items) > 0
            let l:name = l:items[len(l:items) - 1]
        endif
        if empty(l:name)
            let l:name = 'No Name'
        elseif getbufvar(l:buf['name'], '&readonly')
            let l:name = l:name . ' [RO]'
        endif
        if buf['changed']
            let l:name = '+' . l:name
        endif
        if len(l:name) > l:chars
            let l:name = l:name[:(l:chars-2)].'..'
        endif
        if buf['bufnr'] == bufnr('%')
            let l:name = g:flip_left_char.l:name.g:flip_right_char
            let l:found_current = v:true
        else
            let l:name = ' '.l:name.' '
        endif
        let l:name = printf('%-'.string(l:chars).'s', l:name)
        let l:names = l:names + [l:name]
        if l:found_current && len(join(l:names, '')) >= s:EchoSpace() | break | endif
    endfor
    let l:done = v:false
    while done == v:false
        let l:count = 0
        for val in l:names
            if l:val[0] == '[' | break | endif
            let l:count = l:count + len(l:val)
        endfor
        if l:count > s:EchoSpace()
            let l:names = l:names[1:]
        else
            let l:done = v:true
        endif
    endwhile
    redraw
    echo join(l:names, '')[:s:EchoSpace()-1]
endfunction

" Prevent flip from hiding terminal windows
function! g:Flip_Prev()
    if &buftype !=# 'terminal'
        silent exec 'bprev'
        if &buftype !=# 'terminal'
            call Flip_ShowInfo()
        endif
    endif
endfunc

function! g:Flip_Next()
    if &buftype !=# 'terminal'
        silent exec 'bnext'
        call Flip_ShowInfo()
    endif
endfunc

if g:flip_map_keys
    nmap <silent> <c-k> :call Flip_Prev()<cr>
    nmap <silent> <c-j> :call Flip_Next()<cr>
    augroup BufSwitch
        autocmd!
        autocmd BufEnter * call Flip_ShowInfo()
    augroup END
endif
