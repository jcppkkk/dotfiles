
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
		autocmd BufReadPre * let f=expand("<afile>") |
					\ if getfsize(f) > g:LargeFile |
					\ set eventignore+=FileType |
					\ setlocal noswapfile |
					\ setlocal bufhidden=unload |
					\ setlocal undolevels=-1 |
					\ else |
					\ set eventignore-=FileType |
					\ endif
	augroup END
endif

call plug#begin()

" Testing
	Plug 'mfukar/robotframework-vim'
" General programming
	Plug 'vim-scripts/AutoTag'
" format / indent
	Plug 'roryokane/detectindent'
	autocmd BufReadPost *.jade DetectIndent
	autocmd BufReadPost *.coffee DetectIndent
	let g:detectindent_preferred_expandtab = 1
	let g:detectindent_preferred_indent = 4
" syntax checker
	Plug 'scrooloose/syntastic'
	set statusline+=%#warningmsg#
	set statusline+=%{SyntasticStatuslineFlag()}
	set statusline+=%*
	let g:syntastic_reuse_loc_lists = 0
	let g:syntastic_always_populate_loc_list = 1
	let g:syntastic_auto_loc_list = 1
	let g:syntastic_check_on_open = 1
	let g:syntastic_check_on_wq = 1
	let g:syntastic_cpp_checkers = ['make', 'cpplint']
	let g:syntastic_c_checkers = ['make', 'checkpatch', 'cpplint']
	let g:syntastic_c_checkpatch_exec = $HOME."/bin/checkpatch.pl"
	let g:syntastic_c_cpplint_exec =  $HOME."/bin/hb_clint.py"
	let g:syntastic_cpp_cpplint_exec =  $HOME."/bin/hb_clint.py"
	let g:syntastic_aggregate_errors = 1
	let g:syntastic_mode_map = { 'mode': 'passive', 'active_filetypes': [] ,'passive_filetypes': [] }
	let g:syntastic_python_checkers=['flake8']
	let g:syntastic_python_flake8_args='--ignore=E501,F405,F408,F403,E241'
	let g:syntastic_sh_checkers = ['shellcheck']

" language support - others
	Plug 'chase/vim-ansible-yaml'
	Plug 'vim-ruby/vim-ruby'
	Plug 'kchmck/vim-coffee-script'
	Plug 'PProvost/vim-ps1'
	Plug 'vim-scripts/Improved-AnsiEsc'
" language support - Shell
	Plug 'chrisbra/vim-sh-indent'
" language support - Docker
	Plug 'ekalinin/Dockerfile.vim'
" language support - Python
	"Plug 'klen/python-mode'
	"let g:pymode_folding=0
	"let g:pymode_rope = 0
	"let g:pymode_lint_checkers = ['pyflakes', 'pep8']
	"let g:pymode_lint_ignore = "E501,E221"
	"let g:pymode_lint = 1
	"let g:pymode_folding=0
	" Track the engine.
	Plug 'SirVer/ultisnips'
	" Snippets are separated from the engine. Add this if you want them:
	Plug 'honza/vim-snippets'
		" Trigger configuration. Do not use <tab> if you use https://github.com/Valloric/YouCompleteMe.
		let g:UltiSnipsExpandTrigger="<c-tab>"
		let g:UltiSnipsJumpForwardTrigger="<c-b>"
		let g:UltiSnipsJumpBackwardTrigger="<c-x>"
		" If you want :UltiSnipsEdit to split your window.
		let g:UltiSnipsEditSplit="vertical"
" language support - C/C++
	Plug 'scrooloose/nerdcommenter'
		let g:NERDSpaceDelims = 1
		let g:NERDTrimTrailingWhitespace = 1
		nmap <leader>cr :call Reformat_comment()<CR>
		function! Reformat_comment()
			normal k$]/
			silent! s#^\s*\*/#&#
			normal [/v]/\c gv=gvJgv\cs[/v]/
			pyf /usr/share/vim/addons/syntax/clang-format-4.0.py
			normal gv]/gq
		endfunction
	Plug 'vim-scripts/valgrind.vim'
		let g:valgrind_arguments=''
	Plug 'xolox/vim-misc'
	Plug 'xolox/vim-easytags'
		let g:easytags_auto_highlight = 0
		let g:easytags_async = 1
		"let g:easytags_dynamic_files = 2
	Plug 'vim-scripts/cuteErrorMarker'
	Plug 'majutsushi/tagbar'
	autocmd VimEnter *.c,*.py,*.js nested :silent! call tagbar#autoopen(1)
	autocmd FileType qf wincmd J
	"let g:tagbar_width = 60
	Plug 'vim-scripts/gcov.vim'
" language support - csv
	Plug 'chrisbra/csv.vim'

" Tools - Git
	Plug 'airblade/vim-gitgutter'
	let g:gitgutter_escape_grep = 1
	nmap <M-Down> <Plug>GitGutterNextHunk
	nmap <M-Up> <Plug>GitGutterPrevHunk
	nmap <esc>[1;3B <Plug>GitGutterNextHunk
	nmap <esc>[1;3A <Plug>GitGutterPrevHunk
	let g:gitgutter_max_signs = 5000
	Plug 'tpope/vim-fugitive'

" Editing Tools
	Plug 'vim-scripts/renamer.vim'
	Plug 'nathanaelkane/vim-indent-guides'
	let g:indent_guides_enable_on_vim_startup = 1
	let g:indent_guides_auto_colors = 0
	let g:indent_guides_start_level=2
	let g:indent_guides_guide_size=1
	Plug 'guns/xterm-color-table.vim'
	Plug 'terryma/vim-multiple-cursors'
	Plug 'junegunn/vim-easy-align'
	" Start interactive EasyAlign in visual mode (e.g. vipga)
	xmap ga <Plug>(EasyAlign)
	" Start interactive EasyAlign for a motion/text object (e.g. gaip)
	nmap ga <Plug>(EasyAlign)
	let g:easy_align_delimiters = { ';': {
				\	'pattern': ';;\|;',
				\	'left_margin': 0
				\	}
				\ }
	let g:easy_align_ignore_groups = ['String']
	Plug 'Valloric/ListToggle'
	let g:lt_location_list_toggle_map = '<leader>l'
	let g:lt_quickfix_list_toggle_map = '<leader>q'

" Themes
	Plug 'altercation/vim-colors-solarized'
	syntax enable
	set background=dark
	let g:solarized_diffmode="low"

	Plug 'bling/vim-airline'
	Plug 'vim-airline/vim-airline-themes'
	let g:airline_powerline_fonts = 1
	let g:airline_theme='solarized'
	" spaces are allowed after tabs, but not in between
	" this algorithm works well with programming styles that use tabs for
	" indentation and spaces for alignment
	let g:airline#extensions#whitespace#mixed_indent_algo = 2
	let g:airline#extensions#tabline#enabled = 1
	let g:airline#extensions#tabline#fnamemod = ':t'
	let g:airline#extensions#tabline#excludes = []
	let g:airline#extensions#tabline#exclude_preview = 1
	let g:airline#extensions#tabline#fnametruncate = 8
call plug#end()
set wildmode=longest,list
set wildmenu
" load colorscheme out of plug section 
colorscheme solarized

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" first the disabled features due to security concerns
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
set modelines=5         " no modelines [http://www.guninski.com/vim1.html]
set modeline
let g:secure_modelines_verbose=1 " securemodelines vimscript

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" operational settings
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
set hidden                      " allow editing multiple unsaved buffers
set more                        " the 'more' prompt
filetype plugin indent on       " automatic file type detection
set autoread                    " watch for file changes by other programs
"set visualbell                 " visual beep
set backupdir=~/.backup,.
set directory=.,~/.backup
set backup                      " produce *~ backup files
set backupext=~                 " add ~ to the end of backup files
":set patchmode=~               " only produce *~ if not there
set noautowrite                 " don't automatically write on :next, etc
let maplocalleader=','          " all my macros start with ,
set lazyredraw                  " don't redraw when running macros
set ttyfast                     " Speedup for tty
set updatetime=750		" screen update speed
set wildmenu                    " : menu has tab completion, etc
set scrolloff=5                 " keep at least 10 lines above/below cursor
set sidescrolloff=5             " keep at least 5 columns left/right of cursoraaaaa
set history=200                 " remember the last 200 commands
set showcmd		        " display incomplete commands
set tags=./.tags;,~/.vimtags

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" meta
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
map <LocalLeader>ce :edit ~/.vimrc<CR>          " quickly edit this file
map <LocalLeader>cs :source ~/.vimrc<CR>        " quickly source this file

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

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" tab indent
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
nnoremap <Tab> >>_
nnoremap <S-Tab> <<_
inoremap <S-Tab> <C-D>
vnoremap <Tab> >gv_
vnoremap <S-Tab> <gv_

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" searching...
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
set hlsearch                   " enable search highlight globally
set incsearch                  " show matches as soon as possible
set showmatch                  " show matching brackets when typing
" disable last one highlight
nmap <LocalLeader>nh :nohlsearch<CR>

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
nmap <LocalLeader>cd :cd%:p:h<CR>
" change local directory to that of current file
nmap <LocalLeader>lcd :lcd%:p:h<CR>

" word swapping
nmap <silent> gw "_yiw:s/\(\%#\w\+\)\(\W\+\)\(\w\+\)/\3\2\1/<CR><c-o><c-l>
" char swapping
nmap <silent> gc xph

" save and build
nmap <LocalLeader>w  :wa<CR>:make<CR>

" this is for the find function plugin
nmap <LocalLeader>ff :let name = FunctionName()<CR> :echo name<CR>

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"  buffer management, note 'set hidden' above
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" Move to next buffer
map <LocalLeader>bn :bn<CR>
" Move to previous buffer
map <LocalLeader>bp :bp<CR>
" List open buffers
map <LocalLeader>bb :ls<CR>

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" dealing with merge conflicts
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" find merge conflict markers
:map <LocalLeader>fc /\v^[<=>]{7}( .*\|$)<CR>

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" setup for the visual environment
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
if &term =~ "putty-256color" | set term=xterm-256color | endif
highlight OverLength ctermbg=darkred ctermfg=white guibg=#FFD9D9
"match OverLength /.\%82v.*/
set cursorline
set foldlevelstart=1

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
set notitle
"set notimeout      " don't timeout on mappings
set ttimeout       " do timeout on terminal key codes
set timeoutlen=1000 " timeout after 100 msec
map <C-S-left> :bp<CR>
map <C-S-right> :bn<CR>
" For metas keys in tmux
map <esc>[1;3D :bp<CR>
map <esc>[1;3C :bn<CR>
nnoremap <C-left> <C-W><C-H>
nnoremap <C-right> <C-W><C-L>

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" import other files...
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
set dictionary=/usr/share/dict/words            " used with CTRL-X CTRL-K

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" file encode
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
set fileencodings=utf-8-bom,ucs-bom,utf-8,cp936,big5,gb18030,ucs
set fileformats=unix,dos
set showtabline=1                       " auto hide tab title if only 1 tab
set nobinary

if has("vms")
	set nobackup	" do not keep a backup file, use versions instead
else
	set backup		" keep a backup file
endif

map Q gq

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" box comments tool
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
vmap <silent>c<right>   !boxes -t 4 -d c-cmt2 <CR>
vmap <silent>c<left>    !boxes -t 4 -d c-cmt2 -r<CR>
vmap <silent>c<up>      !boxes -t 4 <CR>
vmap <silent>c<down>    !boxes -t 4 -r<CR>

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Function Keys F1~F12, B, C,
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

nnoremap <silent> <F2> :TagbarToggle<CR>

map <F3> :pyf /usr/share/vim/addons/syntax/clang-format-4.0.py<CR>
imap <F3> <C-o>:pyf /usr/share/vim/addons/syntax/clang-format-4.0.py<CR>

map <F4> :SyntasticToggleMode\|:silent w<CR>
map! <F4> <Esc><F4>a
map <F5>  :w<CR>
map! <F5>  <Esc>:w<CR>i
function! SaveAllExit()
	try
		wqa!
	catch
		write !sudo tee % >/dev/null
		edit!
		wqa!
	endtry
endfun
map ZZ :silent call SaveAllExit()<CR>

nnoremap <F6> :%s/\V\<<c-r>=expand("<cword>")<CR>\>//g<left><left>
vnoremap <F6> "hy:silent %s/\V<C-r>=substitute(substitute(escape(@h, '\/'),"\n",'\\n','g'),"\t",'\\t','g')<CR>//g<left><left>
nnoremap <F7> :silent gr "<c-r>=expand("<cword>")<CR>" .<CR>
vnoremap <F7> "hy:silent gr <c-r>=escape(shellescape(substitute(substitute(escape(@h, '\'),"\n",'\\n','g'),"\t",'\\t','g')),'()')<CR> .<CR>

" <F8> 會在 searching highlight 及非 highlight 間切換
map <F8> :set hls!<BAR>set hls?<CR>

" <F9> Toggle on/off paste mode
map <F9> :set paste!<BAr>set paste?<CR>
set pastetoggle=<F9>

map <F10> :set spell spelllang=en_us<CR>
map <F12> :call Switch_indent()<CR>

let g:indent_mod = 2
function! Switch_indent()
	let g:indent_mod = (g:indent_mod + 1 ) % 3
	if g:indent_mod == 0
		set softtabstop=0 sw=8 tabstop=8 noexpandtab
	endif
	if g:indent_mod == 1
		set softtabstop=0 sw=4 tabstop=4 noexpandtab
	endif
	if g:indent_mod == 2
		set softtabstop=0 sw=4 tabstop=4 expandtab
	endif
	echom "softtabstop"&softtabstop "sw"&sw "tabstop"&tabstop "expandtab"&expandtab
endfunction

map <silent> <S-Down> :call Next_err()<CR>
function! Next_err()
	try
		cnext!
	catch /:E553:/
		clast!
	catch /:E42:/
	endtry
endfunction

map <silent> <S-Up> :call Pre_err()<CR>
function! Pre_err()
	try
		cprevious!
	catch /:E553:/
		cfirst!
	catch /:E42:/
	endtry
endfunction

" Bind for terminator
map [1;5A <C-Up>
map [1;5B <C-Down>
map <silent> <C-Up> :call <SID>LocationPrevious()<CR>
map <silent> <C-Down> :call <SID>LocationNext()<CR>
map! <silent> <C-Up> <Esc><C-Up>i
map! <silent> <C-Down> <Esc><C-Down>i
function! <SID>LocationPrevious()
	try
		lprev!
	catch /:E42:/  " E42: No Errors
	catch /:E776:/ " No location list
	catch /:E553:/ " End/Start of location list
		call <SID>LocationLast()
	catch /:E926:/ " Location list changed
		ll!
	endtry
endfunction
function! <SID>LocationNext()
	try
		lnext!
	catch /:E42:/  " E42: No Errors
	catch /:E776:/ " No location list
	catch /:E553:/ " End/Start of location list
		call <SID>LocationFirst()
	catch /:E926:/ " Location list changed
		call <SID>LocationNext()
	endtry
endfunction
function! <SID>LocationFirst()
	try
		lfirst!
	catch /:E926:/ " Location list changed
		call <SID>LocationFirst()
	endtry
endfunction
function! <SID>LocationLast()
	try
		llast!
	catch /:E926:/ " Location list changed
		call <SID>LocationLast()
	endtry
endfunction

" <B> <C> this script use to excute make in vim and open quickfix window
"let &errorformat="%f:%l:%c: %t%*[^:]:%m,%f:%l: %t%*[^:]:%m," . &errorformat
nmap <silent> B :call Do_make__()<CR>
nmap <silent> C :cclose<CR>
set autowrite
function! Do_make__()
	execute "silent make!|cwindow|cc!|redraw!"
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
	set nostartofline
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

autocmd BufNewFile,BufReadPost *.coffee   setl shiftwidth=2 softtabstop=2 expandtab
autocmd BufNewFile,BufReadPost *.erb      setl shiftwidth=4 softtabstop=4 expandtab
autocmd BufNewFile,BufReadPost *.gcov     setl filetype=gcov
autocmd BufNewFile,BufReadPost Rockerfile setl filetype=Dockerfile
autocmd BufNewFile,BufReadPost *.go       setl shiftwidth=4 noexpandtab   tabstop=4
autocmd BufNewFile,BufReadPost *.hbs      setl shiftwidth=4 softtabstop=4 expandtab
autocmd BufNewFile,BufReadPost *.js       setl shiftwidth=4 softtabstop=4 expandtab
autocmd BufNewFile,BufReadPost *.json     setl shiftwidth=2 softtabstop=2 expandtab
autocmd BufNewFile,BufReadPost *.liquid   setl shiftwidth=4 softtabstop=4 expandtab
autocmd BufNewFile,BufReadPost *.xsd      setl shiftwidth=2 softtabstop=2 expandtab
autocmd BufNewFile,BufReadPost log        AnsiEsc
autocmd FileType               Dockerfile setl shiftwidth=2 softtabstop=2 tabstop=8
autocmd FileType               Podfile    setl shiftwidth=2 softtabstop=2 expandtab
autocmd FileType               Rakefile   setl shiftwidth=2 softtabstop=2 expandtab
autocmd FileType               c          setl fo=cq        wm=0          formatoptions+=r
autocmd FileType               css        setl shiftwidth=2 softtabstop=2 expandtab
autocmd FileType               html       setl shiftwidth=4 softtabstop=4 expandtab
autocmd FileType               jade       setl shiftwidth=2 softtabstop=2 expandtab
autocmd FileType               make       setl shiftwidth=2 softtabstop=2 tabstop=8
autocmd FileType               markdown   setl shiftwidth=2 softtabstop=2 expandtab
autocmd FileType               php        setl shiftwidth=4 softtabstop=4 expandtab
autocmd FileType               python     setl shiftwidth=4 softtabstop=4 expandtab cindent
autocmd FileType               ruby       setl shiftwidth=2 softtabstop=2 expandtab
autocmd FileType               scss       setl shiftwidth=2 softtabstop=2 expandtab
autocmd FileType               xml        setl shiftwidth=2 softtabstop=2 expandtab
autocmd FileType               yaml       setl shiftwidth=2 softtabstop=2 expandtab
autocmd FileType               sh,bash    setl shiftwidth=4 softtabstop=4 tabstop=4
autocmd FileType               gitcommit  call setpos('.', [0, 1, 1, 0])
autocmd FileType               gitcommit  set spell spelllang=en_us

" The Silver Searcher
if executable('ag')
	" Use ag over grep
	set grepprg=ag\ --vimgrep\ --ignore=*~\ $*
	set grepformat=%f:%l:%c:%m

	" Use ag in CtrlP for listing files. Lightning fast and respects .gitignore
	let g:ctrlp_user_command = 'ag %s -l --nocolor -g ""'

	" ag is fast enough that CtrlP doesn't need to cache
	let g:ctrlp_use_caching = 0
endif

" Exclude quickfix buffer from `:bnext` `:bprevious`
augroup qf
	autocmd!
	autocmd FileType qf set nobuflisted
augroup END

set clipboard="unnamedplus\|linux"
imap [1~ <esc>^i
nmap [1~ ^
imap OH <esc>^i
nmap OH ^

