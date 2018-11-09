"set nocompatible
"filetype off
"
"set rtp+=~/.vim/bundle/Vundle.vim
"call vundle#begin()
"
"Plugin 'VundleVim/Vundle.vim'
"
"" 導入したいプラグインを以下に列挙
"" Plugin '[Github Author]/[Github repo]' の形式で記入
"Plugin 'tomasiser/vim-code-dark'
"
"call vundle#end()
"filetype plugin indent on
"
""　その他のカスタム設定を以下に書く
"
syntax off
"
"set t_Co=256
"set t_ut=
"colorscheme codedark

"let g:indent_guides_enable_on_vim_startup = 1
"let g:indent_guides_auto_colors = 0
"autocmd VimEnter,Colorscheme * :hi IndentGuidesOdd  guibg=#262626   ctermbg=235
"autocmd VimEnter,Colorscheme * :hi IndentGuidesEven guibg=#303030   ctermbg=236

set modeline

" エディタウィンドウの末尾から2行目にステータスラインを常時表示させる
set laststatus=2
" ステータス行に表示させる情報の指定(どこからかコピペしたので細かい意味はわかっていない)
set statusline=%<%f\%m%r%h%w%{'['.(&fenc!=''?&fenc:&enc).']['.&ff.']'}%=%l,%c%V%8P

set expandtab

set tabstop=4

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

"set clipboard=unnamed,autoselect
"copy (write) highlighted text to .vimbuffer
"vmap <C-a> y:new ~/.vimbuffer<CR>VGp:x<CR> \| :!cat ~/.vimbuffer \| clip.exe <CR><CR>
" paste from buffer
"map <C-s> :r ~/.vimbuffer<CR>")"

inoremap <silent> jj <ESC>
inoremap <silent> ｊｊ <ESC>
"inoremap { {}<LEFT>
"inoremap [ []<LEFT>
"inoremap ( ()<LEFT>
"inoremap " ""<LEFT>
"inoremap ' ''<LEFT>

let mapleader = "\<Space>"
nnoremap <Leader>w :w<CR>
nnoremap <Leader>h ^
nnoremap <Leader>l $
nnoremap <Leader>/ *
nnoremap <Leader>m %

function! s:isWsl()
    return filereadable('/proc/sys/fs/binfmt_misc/WSLInterop')
endfunction

if s:isWsl() && executable('AutoHotkeyU64.exe')
    augroup insertLeave
        autocmd!
        autocmd InsertLeave * :call system('AutoHotkeyU64.exe "D:\ImDisable.ahk"')
    augroup END
endif

function! s:InputPrefix(prefix)
    execute "normal i" . a:prefix . ' '
endfunction
command! -nargs=1 InputPrefix call s:InputPrefix(<f-args>)

