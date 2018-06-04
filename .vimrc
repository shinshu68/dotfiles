set nocompatible
filetype off

set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()

Plugin 'VundleVim/Vundle.vim'

" 導入したいプラグインを以下に列挙
" Plugin '[Github Author]/[Github repo]' の形式で記入
Plugin 'tomasiser/vim-code-dark'
Plugin 'flazz/vim-colorschemes'

call vundle#end()
filetype plugin indent on

"　その他のカスタム設定を以下に書く

syntax on

set t_Co=256
set t_ut=
colorscheme codedark

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

set clipboard=unnamed,autoselect
"copy (write) highlighted text to .vimbuffer
vmap <C-a> y:new ~/.vimbuffer<CR>VGp:x<CR> \| :!cat ~/.vimbuffer \| clip.exe <CR><CR>
" paste from buffer
map <C-s> :r ~/.vimbuffer<CR>")"

inoremap <silent> jj <ESC>
inoremap <silent> ｊｊ <ESC>
inoremap { {}<LEFT>
inoremap [ []<LEFT>
inoremap ( ()<LEFT>
inoremap " ""<LEFT>
inoremap ' ''<LEFT>

function! s:isWsl()
	return filereadable('/proc/sys/fs/binfmt_misc/WSLInterop')
endfunction

if s:isWsl() && executable('AutoHotkeyU64.exe')
	augroup insertLeave
		autocmd!
		autocmd InsertLeave * :call system('AutoHotkeyU64.exe "D:\ImDisable.ahk"')
	augroup END
endif
