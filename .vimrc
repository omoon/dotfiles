"Neobundle set up
set nocompatible
filetype off 

if has('vim_starting')
    set runtimepath+=~/dotfiles/.vim/neobundle.vim.git/
    call neobundle#rc(expand('~/dotfiles/.vim/neobundle'))
endif

NeoBundleFetch 'Shougo/neobundle.vim'

" originalrepos on github
NeoBundle 'Shougo/vimproc'
NeoBundle 'The-NERD-tree'
NeoBundle 'The-NERD-Commenter'
NeoBundle 'neocomplcache'
NeoBundle 'unite.vim'
NeoBundle 'surround.vim'
NeoBundle 'taglist.vim'
NeoBundle 'ZenCoding.vim'
NeoBundle 'ref.vim'

NeoBundle 'w0ng/vim-hybrid'
NeoBundle 'altercation/vim-colors-solarized'

filetype plugin indent on

sy on

set hidden
set nu
set cursorline

set tabstop=4
set shiftwidth=4
set shiftround "always indent/outdent to the nearest tabstop.
set showmatch
set showcmd
set expandtab
set autoindent
set guioptions-=T
set nobackup
set noswapfile

if has('gui_macvim')
    let g:hybrid_use_Xresources = 1
    colorscheme hybrid
endif

"syntax enable
"set background=dark
"colorscheme solarized

set gfn=Consolas:h15
set gfw=HiraMaruPro-W4:h14

"表示行単位で行移動する
nmap j gj
nmap k gk
vmap j gj
vmap k gk

"ウインドウの横移動
map <C-h> <C-w>h
map <C-l> <C-w>l

" ステイタス行に文字コードと改行コードを表示。
set statusline=%<%f\ %m%r%h%w%{'['.(&fenc!=''?&fenc:&enc).']['.&ff.']'}%=%l,%c%V%8P

" バッファリスト
nmap <Space>b :ls<CR>:buffer 
nnoremap ,c <ESC><Space>:!ctags -R<CR><CR>
nnoremap ,ca <ESC><Space>:!ctags -R --append<CR><CR>

if has('gui_macvim')
    set transparency=10	" 透明度を指定
    set antialias
    set guioptions-=t	" ツールバー非表示
    set guioptions-=r	" 右スクロールバー非表示
    set guioptions-=R
    set guioptions-=l	" 左スクロールバー非表示
    set guioptions-=L

    set imdisable		" IMを無効化

    "フルスクリーンモード	
    set fuoptions=maxvert,maxhorz
    autocmd GUIEnter * set fullscreen 

endif

"taglist
let Tlist_Show_One_File = 1     "現在表示中のファイルのみのタグしか表示しない
let Tlist_Use_Right_Window = 1  "右側にtag listのウインドうを表示する
let Tlist_Exit_OnlyWindow = 1   " taglistのウインドウだけならVimを閉じる
map <silent> <Space>l :TlistToggle<CR>

" Dash.app連携
function! s:dash(...)
    if len(a:000) == 1 && len(a:1) == 0
        echomsg 'No keyword'
    else
        let ft = &filetype
        if &filetype == 'python'
            let ft = ft.'2'
        endif
        if &filetype == 'ruby'
            let ft = ''
        else
            let ft = ft.':'
        endif
        let word = len(a:000) == 0 ? input('Keyword: ', ft.expand('<cword>')) : ft.join(a:000, ' ')
        call system(printf("open dash://'%s'", word))
    endif
endfunction

command! -nargs=* Dash call <SID>dash(<f-args>)

nnoremap <Space>d :call <SID>dash(expand('<cword>'))<CR>
