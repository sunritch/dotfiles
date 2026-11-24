source $VIMRUNTIME/defaults.vim
set t_Co=256
set hidden
set autoindent
set smarttab
set autoread
set hlsearch
set ignorecase
set smartcase
set expandtab
set shiftround
set nomodeline
set encoding=utf-8
set wildmode=longest:full,full
set completeopt=menuone,noinsert,noselect
set clipboard^=unnamed,unnamedplus

command W execute 'w !sudo tee -- ' . shellescape(expand('%:p')) . ' >/dev/null' | if !v:shell_error | setlocal nomodified | endif

runtime! macros/matchit.vim
