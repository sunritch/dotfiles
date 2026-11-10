filetype plugin indent on
syntax enable
set t_Co=256
set ruler
set autoindent
set backspace=indent,eol,start
set smarttab
set nrformats-=octal
set showcmd
set wildmenu
set wildmode=longest:full,full
set encoding=utf-8
set autoread
set nomodeline
set history=10000
set tabpagemax=50
set sessionoptions-=options
set hlsearch
set ignorecase
set incsearch
set smartcase
set expandtab
set smartindent
set shiftround
set showmatch
set diffopt+=iwhite,algorithm:histogram,indent-heuristic
set completeopt=menuone,noinsert,noselect
set listchars=tab:>\ ,trail:-,extends:>,precedes:<,nbsp:+
set mouse=a
set formatoptions=tcqrow
set clipboard^=unnamed,unnamedplus
set spellcapcheck=

command W execute 'w !sudo tee -- ' . shellescape(expand('%:p')) . ' >/dev/null' | if !v:shell_error | setlocal nomodified | endif

runtime! macros/matchit.vim
