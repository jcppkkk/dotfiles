
" Protect large files from sourcing and other overhead.
" Files become read only
if !exists("my_auto_commands_loaded")
    let my_auto_commands_loaded = 1
    " Large files are > 10M
    " Set options:
    " eventignore+=FileType (no syntax highlighting etc
    " assumes FileType always on)
    " noswapfile (save copy of file)
    " bufhidden=unload (save memory when other file is viewed)
    " buftype=nowritefile (is read-only)
    " undolevels=-1 (no undo possible)
    let g:LargeFile = 1024 * 1024 * 10
    augroup LargeFile
        autocmd BufReadPre * let f=expand("<afile>") | if getfsize(f) > g:LargeFile | set eventignore+=FileType | setlocal noswapfile bufhidden=unload undolevels=-1 | else | set eventignore-=FileType | endif
    augroup END
endif

set nocompatible		" be iMproved, required
filetype off			" required!
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()

" let Vundle manage Vundle
" required!
Plugin 'VundleVim/Vundle.vim'

" Testing
Plugin 'mfukar/robotframework-vim'

" Themes
Plugin 'altercation/vim-colors-solarized'

" language support
Plugin 'vim-ruby/vim-ruby'
Plugin 'kchmck/vim-coffee-script'
Plugin 'Super-Shell-Indent'
Plugin 'roryokane/detectindent'
autocmd BufReadPost *.jade DetectIndent
autocmd BufReadPost *.coffee DetectIndent
let g:detectindent_preferred_expandtab = 1
let g:detectindent_preferred_indent = 4
Plugin 'pangloss/vim-javascript'
Plugin 'digitaltoad/vim-jade'
Plugin 'othree/javascript-libraries-syntax.vim'
Plugin 'ekalinin/Dockerfile.vim'

" Editing Tools
Plugin 'L9'		" required by FuzzyFinder
Plugin 'FuzzyFinder'
Plugin 'cuteErrorMarker'
Plugin 'OmniCppComplete'
Plugin 'renamer.vim'
Plugin 'AutoTag'
Plugin 'bling/vim-airline'
let g:airline_theme='solarized'
let g:airline_powerline_fonts = 1

call vundle#end()            " required
filetype plugin indent on    " required

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" first the disabled features due to security concerns
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
set modelines=0         " no modelines [http://www.guninski.com/vim1.html]
"let g:secure_modelines_verbose=1 " securemodelines vimscript

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" configure other scripts
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

let c_no_curly_error = 1

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" operational settings
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
set hidden                      " allow editing multiple unsaved buffers
set more                        " the 'more' prompt
filetype on                     " automatic file type detection
set autoread                    " watch for file changes by other programs
"set visualbell                 " visual beep
set backup                      " produce *~ backup files
set backupext=~                 " add ~ to the end of backup files
":set patchmode=~               " only produce *~ if not there
set noautowrite                 " don't automatically write on :next, etc
let maplocalleader=','          " all my macros start with ,
"set lazyredraw                  " don't redraw when running macros
set ttyfast                     " Speedup for tty
set wildmenu                    " : menu has tab completion, etc
set scrolloff=5                " keep at least 10 lines above/below cursor
set sidescrolloff=5             " keep at least 5 columns left/right of cursor
set history=200                 " remember the last 200 commands
set showcmd		                " display incomplete commands
set tags=./tags;

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" meta
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
map <LocalLeader>ce :edit ~/.vimrc<cr>          " quickly edit this file
map <LocalLeader>cs :source ~/.vimrc<cr>        " quickly source this file

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" window spacing
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
set cmdheight=1                 " make command line two lines high
set ruler                       " show the line number on bar
set number                      " show

map <LocalLeader>w+ 100<C-w>+  " grow by 100
map <LocalLeader>w- 100<C-w>-  " shrink by 100

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" mouse settings
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
set mouse=                      " disable mouse support in all modes
set mousehide                   " hide the mouse when typing text

" ,p and shift-insert will paste the X buffer, even on the command line
nmap <LocalLeader>p i<S-MiddleMouse><ESC>
imap <S-Insert> <S-MiddleMouse>
cmap <S-Insert> <S-MiddleMouse>

" this makes the mouse paste a block of text without formatting it
" (good for code)
map <MouseMiddle> <esc>"*p

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" global editing settings
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
set autoindent smartindent      " turn on auto/smart indenting
set backspace=eol,start,indent  " allow backspacing over indent, eol, & start
set undolevels=1000             " number of forgivable mistakes
set updatecount=100             " write swap file to disk every 100 chars
set complete=.,w,b,u,U,t,i,d    " do lots of scanning on tab completion
set viminfo=%100,'100,/100,h,\"500,:100,n~/.viminfo

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" tab indent
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
nmap <tab> v>
nmap <s-tab> v<<esc>
vmap <tab> >gv
vmap <s-tab> <gv
map <F10> mz:set softtabstop=0 shiftwidth=8 tabstop=8 noexpandtab<CR>'z
map <F11> mz:set softtabstop=0 shiftwidth=4 tabstop=4 noexpandtab<CR>'z
map <F12> mz:set softtabstop=0 shiftwidth=4 tabstop=4 expandtab<CR>'z

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" searching...
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
set ignorecase
set hlsearch                   " enable search highlight globally
set incsearch                  " show matches as soon as possible
set showmatch                  " show matching brackets when typing
" disable last one highlight
nmap <LocalLeader>nh :nohlsearch<cr>

set diffopt=filler,iwhite       " ignore all whitespace and sync

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" spelling...
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
if v:version >= 700
    let b:lastspelllang='en'
    function! ToggleSpell()
        if &spell == 1
            let b:lastspelllang=&spelllang
            setlocal spell!
        elseif b:lastspelllang
            setlocal spell spelllang=b:lastspelllang
        else
            setlocal spell spelllang=en
        endif
    endfunction

    nmap <LocalLeader>ss :call ToggleSpell()<CR>

    setlocal spell spelllang=en
    setlocal nospell
endif

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" some useful mappings
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" disable search complete
let loaded_search_complete = 1

" Y yanks from cursor to $
map Y y$
" change directory to that of current file
nmap <LocalLeader>cd :cd%:p:h<cr>
" change local directory to that of current file
nmap <LocalLeader>lcd :lcd%:p:h<cr>

" word swapping
nmap <silent> gw "_yiw:s/\(\%#\w\+\)\(\W\+\)\(\w\+\)/\3\2\1/<cr><c-o><c-l>
" char swapping
nmap <silent> gc xph

" save and build
nmap <LocalLeader>w  :wa<cr>:make<cr>

" this is for the find function plugin
nmap <LocalLeader>ff :let name = FunctionName()<CR> :echo name<CR>

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"  buffer management, note 'set hidden' above
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" Move to next buffer
map <LocalLeader>bn :bn<cr>
" Move to previous buffer
map <LocalLeader>bp :bp<cr>
" List open buffers
map <LocalLeader>bb :ls<cr>

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" dealing with merge conflicts
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" find merge conflict markers
:map <LocalLeader>fc /\v^[<=>]{7}( .*\|$)<CR>

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" setup for the visual environment
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
syntax enable                       " syntax on
try
    colorscheme solarized
catch /^Vim\%((\a\+)\)\=:E185/
    " deal with it
endtry

let g:solarized_termcolors=256

"set background=light
set background=dark

set cursorline

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Folding for unified diffs
" http://pastey.net/1483, mgedmin on #vim
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

function! DiffFoldLevel(lineno)
    let line = getline(a:lineno)
    if line =~ '^Index:'
        return '>1'
    elseif line =~ '^===' || line =~ '^RCS file: ' || line =~ '^retrieving revision '
        let lvl = foldlevel(a:lineno - 1)
        return lvl >= 0 ? lvl : '='
    elseif line =~ '^diff'
        return getline(a:lineno - 1) =~ '^retrieving revision ' ? '=' : '>1'
    elseif line =~ '^--- ' && getline(a:lineno - 1) !~ '^diff\|^==='
        return '>1'
    elseif line =~ '^@'
        return '>2'
    elseif line =~ '^[- +\\]'
        let lvl = foldlevel(a:lineno - 1)
        return lvl >= 0 ? lvl : '='
    else
        return '0'
    endif
endf

function! FT_Diff()
    if v:version >= 600
        setlocal foldmethod=expr
        setlocal foldexpr=DiffFoldLevel(v:lnum)
    else
    endif
endf

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" no folds in vimdiff
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

function! NoFoldsInDiffMode()
    if &diff
        :silent! :%foldopen!
    endif
endf

augroup Diffs
    autocmd!
    autocmd BufRead,BufNewFile *.patch :setf diff
    autocmd BufEnter           *       :call NoFoldsInDiffMode()
    autocmd FileType           diff    :call FT_Diff()
augroup END

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" force making paths relative to `pwd`
" this is useful if tag files have absolute paths
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

augroup force-cd-dot
    autocmd!
    autocmd BufEnter * :cd .
augroup END
set path=**;/

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" notmuch config
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

let g:notmuch_debug = 0

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" termcaps
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"set notimeout      " don't timeout on mappings
set ttimeout       " do timeout on terminal key codes
set timeoutlen=100 " timeout after 100 msec
map <M-left> :tabprevious<CR>
map <M-right> :tabnext<CR>

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" import other files...
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

let $kernel_version=system('uname -r | tr -d "\n"')
set dictionary=/usr/share/dict/words            " used with CTRL-X CTRL-K

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" file encode
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
set fileencodings=utf-8-bom,ucs-bom,utf-8,cp936,big5,gb18030,ucs
set fileformats=unix,dos
set showtabline=1                       " auto hide tab title if only 1 tab
set binary


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Tagkist setting
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
let Tlist_Show_One_File = 0 " Displaying tags for only one file~
let Tlist_Exist_OnlyWindow = 1 " if you are the last, kill yourself
let Tlist_Use_Right_Window = 0 " split to the right side of the screen
let Tlist_Sort_Type = "order" " sort by order or name
let Tlist_Display_Prototype = 0 " do not show prototypes and not tags in the taglist window.
let Tlist_Compart_Format = 1 " Remove extra information and blank lines from the taglist window.
let Tlist_GainFocus_On_ToggleOpen = 0 " Jump to taglist window on open.
let Tlist_Display_Tag_Scope = 1 " Show tag scope next to the tag name.
let Tlist_Close_On_Select = 0 " Close the taglist window when a file or tag is selected.
let Tlist_Enable_Fold_Column = 0 " Don't Show the fold indicator column in the taglist window.
let Tlist_WinWidth = 40
if has("vms")
    set nobackup	" do not keep a backup file, use versions instead
else
    set backup		" keep a backup file
endif

map Q gq
imap [1~ <esc>^i
nmap [1~ ^
imap OH <esc>^i
nmap OH ^

map ZZ :wqa<CR>
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" box comments tool
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
vmap <silent>c<right>   !boxes -t 4 -d c-cmt <CR>
vmap <silent>c<left>    !boxes -t 4 -d c-cmt -r<CR>
vmap <silent>c<up>      !boxes -t 4 <CR>
vmap <silent>c<down>    !boxes -t 4 -r<CR>

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Function Keys F1~F12, B, C,
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

if &term =~ "putty-256color"
    :set term=xterm-256color
endif

map <F4> :set expandtab!<BAR>set expandtab?<CR>
map <F5> :wa<CR>
map <F6> :%s/\<<c-r>=expand("<cword>")<cr>\>//g<left><left>

" <F8> 會在 searching highlight 及非 highlight 間切換
map <F8> :set hls!<BAR>set hls?<CR>

" <F9> Toggle on/off paste mode
map <F9> :set paste!<BAr>set paste?<CR>
set pastetoggle=<F9>

" <B> <C> this script use to excute make in vim and open quickfix window
"let &errorformat="%f:%l:%c: %t%*[^:]:%m,%f:%l: %t%*[^:]:%m," . &errorformat
nmap <silent> B :call Do_make__()<cr><cr><cr>
nmap <silent> C :cclose<cr>
function! Do_make__()
    up
    execute "make"
    execute "cwindow"
endfunction



"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" status line
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" Hide the default mode text (e.g. -- INSERT -- below the statusline)
set noshowmode

" Always show statusline
set laststatus=2

" Use 256 colours (Use this setting only if your terminal supports 256 colours)
set t_Co=256


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" auto load extensions for different file types
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
if has('autocmd')
    filetype plugin indent on
    " jump to last line edited in a given file (based on .viminfo)
    autocmd BufReadPost *
                \ if line("'\"") > 0|
                \       if line("'\"") <= line("$")|
                \               exe("norm '\"")|
                \       else|
                \               exe("norm $")|
                \       endif|
                \ endif

    " improve legibility
    "au BufRead quickfix setlocal nobuflisted wrap number
    au BufReadPost quickfix  setlocal modifiable
                \ | silent exe 'g/^/s//\=line(".")." "/'
                \ | setlocal nomodifiable


    " configure various extenssions
    let git_diff_spawn_mode=2

endif


autocmd BufNewFile,BufReadPost *.coffee setl shiftwidth=2 softtabstop=2 expandtab
autocmd BufNewFile,BufReadPost *.rb setl shiftwidth=2 softtabstop=2 expandtab
autocmd BufNewFile,BufReadPost *.liquid setl shiftwidth=4 softtabstop=4 expandtab
autocmd BufNewFile,BufReadPost *.rake setl shiftwidth=2 softtabstop=2 expandtab
autocmd BufNewFile,BufReadPost Rakefile setl shiftwidth=2 softtabstop=2 expandtab
autocmd BufNewFile,BufReadPost *.js setl shiftwidth=4 softtabstop=4 expandtab
autocmd BufNewFile,BufReadPost *.html setl shiftwidth=4 softtabstop=4 expandtab
autocmd BufNewFile,BufReadPost *.php setl shiftwidth=4 softtabstop=4 expandtab
autocmd BufNewFile,BufReadPost *.hbs setl shiftwidth=4 softtabstop=4 expandtab
autocmd BufNewFile,BufReadPost *.erb setl shiftwidth=4 softtabstop=4 expandtab
autocmd BufNewFile,BufReadPost *.md setl shiftwidth=2 softtabstop=2 expandtab
autocmd BufNewFile,BufReadPost Podfile setl shiftwidth=2 softtabstop=2 expandtab
autocmd BufNewFile,BufReadPost *.yml setl shiftwidth=2 softtabstop=2 expandtab
autocmd BufNewFile,BufReadPost *.json setl shiftwidth=2 softtabstop=2 expandtab
autocmd BufNewFile,BufReadPost *.xsd setl shiftwidth=2 softtabstop=2 expandtab
autocmd BufNewFile,BufReadPost *.go set noexpandtab tabstop=4 shiftwidth=4
autocmd FileType jade setl shiftwidth=2 softtabstop=2 expandtab
autocmd FileType scss setl shiftwidth=2 softtabstop=2 expandtab
autocmd FileType xml setl shiftwidth=2 softtabstop=2 expandtab
autocmd FileType css setl shiftwidth=2 softtabstop=2 expandtab
autocmd FileType sh setl shiftwidth=4 softtabstop=4 expandtab
