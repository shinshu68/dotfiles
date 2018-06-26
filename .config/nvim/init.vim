" " プラグインが実際にインストールされるディレクトリ
let s:dein_dir = expand('~/.cache/dein')
" dein.vim 本体
let s:dein_repo_dir = s:dein_dir . '/repos/github.com/Shougo/dein.vim'

" dein.vim がなければ github から落としてくる
if &runtimepath !~# '/dein.vim'
    if !isdirectory(s:dein_repo_dir)
        execute '!git clone https://github.com/Shougo/dein.vim' s:dein_repo_dir
    endif
    execute 'set runtimepath^=' . fnamemodify(s:dein_repo_dir, ':p')
endif

" 設定開始
if dein#load_state(s:dein_dir)
    call dein#begin(s:dein_dir)

    " プラグインリストを収めた TOML ファイル
    " 予め TOML ファイル（後述）を用意しておく
    let g:rc_dir    = expand('~/.config/nvim')
    let s:toml      = g:rc_dir . '/dein.toml'
    let s:lazy_toml = g:rc_dir . '/dein_lazy.toml'

    " TOML を読み込み、キャッシュしておく
    call dein#load_toml(s:toml,      {'lazy': 0})
    call dein#load_toml(s:lazy_toml, {'lazy': 1})

    " 設定終了
    call dein#end()
    call dein#save_state()
endif

"もし、未インストールものものがあったらインストール
if dein#check_install()
    call dein#install()
endif

syntax on

set t_Co=256
set t_ut=
colorscheme codedark

" エディタウィンドウの末尾から2行目にステータスラインを常時表示させる
set laststatus=2
" ステータス行に表示させる情報の指定(どこからかコピペしたので細かい意味はわかっていない)
set statusline=%<%f\%m%r%h%w%{'['.(&fenc!=''?&fenc:&enc).']['.&ff.']'}%=%l,%c%V%8P

function! s:gethighlight(hi)
    let l:hl = ''
    redir => l:hl
    exec 'highlight '.a:hi
    redir end
    let l:hl = substitute(l:hl, '[\r\n]', '', 'g')
    let l:hl = substitute(l:hl, 'xxx', '', '')
    return l:hl
endfunction

let g:hi_insert = 'highlight StatusLine guifg=darkblue guibg=darkyellow gui=none ctermfg=blue ctermbg=LightCyan cterm=none'

silent! let g:hi_normal = 'highlight ' . s:gethighlight('StatusLine')

if has('syntax')
    augroup InsertHook
        autocmd!
        autocmd insertenter * call s:statusline('enter')
        autocmd insertleave * call s:statusline('leave')
    augroup END
endif

function! s:statusline(mode)
    if a:mode == 'enter'
        exec g:hi_insert
    else
        highlight clear StatusLine
        silent exec g:hi_normal
    endif
endfunction

let g:indent_guides_enable_on_vim_startup = 1
let g:indent_guides_auto_colors = 0
autocmd VimEnter,Colorscheme * :hi IndentGuidesOdd  guibg=#262626   ctermbg=235
autocmd VimEnter,Colorscheme * :hi IndentGuidesEven guibg=#303030   ctermbg=236

set modeline

set expandtab

set tabstop=8

set softtabstop=4

set shiftwidth=4

set shiftround

set autoindent

set number

set ruler

set visualbell t_vb=
set noerrorbells

set matchpairs& matchpairs+=<:>

set showmatch

set matchtime=3

set wrap

set noswapfile

set showbreak=↪

"set title

set infercase

set ignorecase

set smartcase

set incsearch

set hlsearch

nnoremap <silent><Esc><Esc> :<C-u>set nohlsearch!<CR>

"set mouse=a

set wildmenu

set history=10000

set showmode

set showcmd

set scrolloff=5

set list
set listchars=tab:⊳-,trail:‗

inoremap <silent> jj <ESC>
inoremap <silent> ｊｊ <ESC>

nnoremap <Space>w :w<CR>
nnoremap <Space>h ^
nnoremap <Space>l $
nnoremap <Space>/ *
nnoremap <Space>m %

" 不可視ファイルを表示する
let NERDTreeShowHidden = 1
let NERDTreeShowBookmarks=1
" ツリーと編集領域を移動する
nmap <Leader><Tab> <C-w>w

function! s:isWsl()
    return filereadable('/proc/sys/fs/binfmt_misc/WSLInterop')
endfunction

if s:isWsl() && executable('AutoHotkeyU64.exe')
    augroup insertLeave
        autocmd!
        autocmd InsertLeave * :call system('AutoHotkeyU64.exe "D:\ImDisable.ahk"')
    augroup END
endif

function! s:get_syn_id(transparent)
    let synid = synID(line("."), col("."), 1)
    if a:transparent
        return synIDtrans(synid)
    else
        return synid
    endif
endfunction
function! s:get_syn_attr(synid)
    let name = synIDattr(a:synid, "name")
    let ctermfg = synIDattr(a:synid, "fg", "cterm")
    let ctermbg = synIDattr(a:synid, "bg", "cterm")
    let guifg = synIDattr(a:synid, "fg", "gui")
    let guibg = synIDattr(a:synid, "bg", "gui")
    return {
        \ "name": name,
        \ "ctermfg": ctermfg,
        \ "ctermbg": ctermbg,
        \ "guifg": guifg,
        \ "guibg": guibg}
endfunction
function! s:get_syn_info()
    let baseSyn = s:get_syn_attr(s:get_syn_id(0))
    echo "name: " . baseSyn.name .
        \ " ctermfg: " . baseSyn.ctermfg .
        \ " ctermbg: " . baseSyn.ctermbg .
        \ " guifg: " . baseSyn.guifg .
        \ " guibg: " . baseSyn.guibg
    let linkedSyn = s:get_syn_attr(s:get_syn_id(1))
    echo "link to"
    echo "name: " . linkedSyn.name .
        \ " ctermfg: " . linkedSyn.ctermfg .
        \ " ctermbg: " . linkedSyn.ctermbg .
        \ " guifg: " . linkedSyn.guifg .
        \ " guibg: " . linkedSyn.guibg
endfunction
command! SyntaxInfo call s:get_syn_info()

