filetype plugin indent on
syntax enable
set autoindent
set backspace=indent,eol,start
set smarttab
set nrformats-=octal
set wildmenu
set wildmode=longest:full,full
set encoding=utf-8
set autoread
set history=1000
set tabpagemax=50
set sessionoptions-=options
set expandtab
set smartindent
set shiftround
set showmatch
set ignorecase
set incsearch
set smartcase
set diffopt+=iwhite,algorithm:histogram,indent-heuristic
set completeopt=menuone,noinsert,noselect
set listchars=tab:>\ ,trail:-,extends:>,precedes:<,nbsp:+
set mouse=a

runtime! macros/matchit.vim

inoremap <C-U> <C-G>u<C-U>
" ## added by OPAM user-setup for vim / base ##
let s:opam_share_dir = system("opam var share")
let s:opam_share_dir = substitute(s:opam_share_dir, '[\r\n]*$', '', '')

let s:opam_configuration = {}

function! OpamConfOcpIndent()
  execute "set rtp^=" . s:opam_share_dir . "/ocp-indent/vim"
endfunction
let s:opam_configuration['ocp-indent'] = function('OpamConfOcpIndent')

function! OpamConfOcpIndex()
  execute "set rtp+=" . s:opam_share_dir . "/ocp-index/vim"
endfunction
let s:opam_configuration['ocp-index'] = function('OpamConfOcpIndex')

function! OpamConfMerlin()
  let l:dir = s:opam_share_dir . "/merlin/vim"
  execute "set rtp+=" . l:dir
endfunction
let s:opam_configuration['merlin'] = function('OpamConfMerlin')

let s:opam_packages = ["ocp-indent", "ocp-index", "merlin"]
let s:opam_available_tools = []
for tool in s:opam_packages
  " Respect package order (merlin should be after ocp-index)
  if isdirectory(s:opam_share_dir . "/" . tool)
    call add(s:opam_available_tools, tool)
    call s:opam_configuration[tool]()
  endif
endfor
" ## end of OPAM user-setup addition for vim / base ##
" ## added by OPAM user-setup for vim / ocp-indent ##
if count(s:opam_available_tools,"ocp-indent") == 0
  source "~/.opam/default/share/ocp-indent/vim/indent/ocaml.vim"
endif
" ## end of OPAM user-setup addition for vim / ocp-indent ##
