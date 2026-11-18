source $VIMRUNTIME/defaults.vim
set t_Co=256
set autoindent
set smarttab
set wildmode=longest:full,full
set encoding=utf-8
set autoread
set history=10000
set tabpagemax=50
set sessionoptions-=options
set hlsearch
set ignorecase
set smartcase
set expandtab
set shiftround
set completeopt=menuone,noinsert,noselect
set formatoptions=tcqrow
set clipboard^=unnamed,unnamedplus
set spellcapcheck=

command W execute 'w !sudo tee -- ' . shellescape(expand('%:p')) . ' >/dev/null' | if !v:shell_error | setlocal nomodified | endif

runtime! macros/matchit.vim
