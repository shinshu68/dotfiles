set nocompatible
filetype off

set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()

Plugin 'VundleVim/Vundle.vim'

" 導入したいプラグインを以下に列挙
" Plugin '[Github Author]/[Github repo]' の形式で記入
Plugin 'tomasiser/vim-code-dark'
Plugin 'flazz/vim-colorschemes'
Plugin 'nathanaelkane/vim-indent-guides'

call vundle#end()
filetype plugin indent on

"　その他のカスタム設定を以下に書く

syntax on

set t_Co=256
set t_ut=
colorscheme codedark

let g:indent_guides_enable_on_vim_startup = 1
let g:indent_guides_auto_colors = 0
autocmd VimEnter,Colorscheme * :hi IndentGuidesOdd  guibg=#262626   ctermbg=235
autocmd VimEnter,Colorscheme * :hi IndentGuidesEven guibg=#303030   ctermbg=236

set modeline

" エディタウィンドウの末尾から2行目にステータスラインを常時表示させる
set laststatus=2
" ステータス行に表示させる情報の指定(どこからかコピペしたので細かい意味はわかっていない)
set statusline=%<%f\%m%r%h%w%{'['.(&fenc!=''?&fenc:&enc).']['.&ff.']'}%=%l,%c%V%8P

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

set clipboard=unnamed,autoselect
"copy (write) highlighted text to .vimbuffer
vmap <C-a> y:new ~/.vimbuffer<CR>VGp:x<CR> \| :!cat ~/.vimbuffer \| clip.exe <CR><CR>
" paste from buffer
map <C-s> :r ~/.vimbuffer<CR>")"

inoremap <silent> jj <ESC>
inoremap <silent> ｊｊ <ESC>
"inoremap { {}<LEFT>
"inoremap [ []<LEFT>
"inoremap ( ()<LEFT>
"inoremap " ""<LEFT>
"inoremap ' ''<LEFT>

function! s:isWsl()
    return filereadable('/proc/sys/fs/binfmt_misc/WSLInterop')
endfunction

if s:isWsl() && executable('AutoHotkeyU64.exe')
    augroup insertLeave
        autocmd!
        autocmd InsertLeave * :call system('AutoHotkeyU64.exe "D:\ImDisable.ahk"')
    augroup END
endif

let g:hi_insert = 'highlight StatusLine guifg=darkblue guibg=darkyellow gui=none ctermfg=blue ctermbg=LightCyan cterm=none'
if has('syntax')
    augroup InsertHook
        autocmd!
        autocmd InsertEnter * call s:StatusLine('Enter')
        autocmd InsertLeave * call s:StatusLine('Leave')
    augroup END
endif

let s:slhlcmd = ''
function! s:StatusLine(mode)
    if a:mode == 'Enter'
        silent! let s:slhlcmd = 'highlight ' . s:GetHighlight('StatusLine')
        silent exec g:hi_insert
    else
        highlight clear StatusLine
        silent exec s:slhlcmd
    endif
endfunction

function! s:GetHighlight(hi)
    redir => hl
    exec 'highlight '.a:hi
    redir END
    let hl = substitute(hl, '[\r\n]', '', 'g')
    let hl = substitute(hl, 'xxx', '', '')
    return hl
endfunction
