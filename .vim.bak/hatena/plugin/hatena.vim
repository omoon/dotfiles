scriptencoding utf-8
" hatena.vim
" Author:       motemen <motemen@gmail.com>
" Version:      20070830
" vim: set ts=4 sw=4:

" ===========================
"   インストール {{{

"  - hatena/plugin/hatena.vim
"  - hatena/syntax/hatena.vim
"  - hatena/cookies (空ディレクトリ)
"
" 以上のファイル/ディレクトリを適当な場所に置いて、パスを通して下さい。
"
" 例 (.vimrc):
" > set runtimepath+=$VIM/hatena

" }}}
" ===========================

" ===========================
"   使用方法 {{{

" > :HatenaUser [グループ名:]ユーザ名
" もしくは
" > :let g:hatena_user = '[グループ名:]ユーザ名'
" としてユーザ名を設定し、
" > :HatenaEdit [[[YYYY]MM]DD]
" で編集バッファが開きます。日記を書いたら :w で送信します。

" }}}
" ===========================

" ===========================
"   コマンド {{{

" はてなにログインし、日記を編集する
" Usage:
"   :HatenaEdit [[[YYYY]MM]DD]
" 日付の形式は YYYYMMDD, YYYY/MM/DD, YYYY-MM-DD
command! -nargs=? HatenaEdit            call <SID>HatenaEdit(<args>)

" :HatenaEdit で開いたバッファの内容をはてなに送信し、日記を更新する
" Usage:
"   :HatenaUpdate [title_of_the_day]
" title_of_the_day を指定しない場合は既に設定されているタイトルが使われる
"command! -nargs=? HatenaUpdate         call <SID>HatenaUpdate(<args>)

" :HatenaUpdate と一緒だけど、`ちょっとした更新' にする
"command! -nargs=? HatenaUpdateTrivial  let b:trivial=1 | call <SID>HatenaUpdate(<args>)

" はてなのユーザを切り換える
" 指定しなかった場合は表示する
" Usage:
"   :HatenaUser [username]
command! -nargs=? -complete=customlist,HatenaEnumUsers HatenaUser   if strlen('<args>') | let g:hatena_user='<args>' | else | echo g:hatena_user | endif

nnoremap <Leader>he :HatenaEdit<CR>
" }}}
" ===========================

" ===========================
"   スクリプト設定 {{{

" はてなのユーザID
if !exists('g:hatena_user')
    let g:hatena_user = ''
endif

" サブアカなども含めたIDのリスト
if !exists('g:hatena_users')
    if g:hatena_user != ''
        let g:hatena_users = [g:hatena_user]
    else
        let g:hatena_users = []
    endif
endif

" クッキーを保存しておくか？ (1: 保存しておく 0: Vim終了時に削除)
if !exists('g:hatena_hold_cookie')
    let g:hatena_hold_cookie = 1
endif

" スクリプトのベースディレクトリ (クッキーの保存に使われるだけ)
if !exists('g:hatena_base_dir')
    let g:hatena_base_dir = substitute(expand('<sfile>:p:h'), '[/\\]plugin$', '', '')
endif

" 常に `ちょっとした更新' にする？ (1: 常にちょっとした更新)
if !exists('g:hatena_always_trivial')
    let g:hatena_always_trivial = 0
endif

let g:hatena_syntax_html = 1

if !g:hatena_hold_cookie
    autocmd VimLeave * call delete(b:hatena_login_info[2])
endif

" :HatenaEdit で編集バッファを開くコマンド
let g:hatena_edit_command = 'edit!'

let s:curl_cmd = 'curl -k'
if exists('g:chalice_curl_options') " http://d.hatena.ne.jp/smeghead/20070709/hatenavim
  let s:curl_cmd = s:curl_cmd . ' ' . g:chalice_curl_options
endif
let s:hatena_login_url      = 'https://www.hatena.ne.jp/login'
let s:hatena_base_url       = 'http://d.hatena.ne.jp/'
let s:hatena_group_base_url = 'http://%s.g.hatena.ne.jp/'

" }}}
" ===========================

" ===========================
"   スクリプト本体 {{{

" はてなにログインする
"   ユーザ名は g:hatena_user から取得。存在しなければユーザに尋ねる。
"   クッキーでログインを試み、ダメならパスワードでログインする。
"
"   ログインに成功: [ベースURL, ユーザID, クッキーファイル] を返す。
"   ログインに失敗: 空リストを返す。
function! s:HatenaLogin()
    if !strlen(g:hatena_user)
        let hatena_user = input('はてなユーザID(user/group:user): ', '', 'customlist,HatenaEnumUsers')
    else
        let hatena_user = g:hatena_user
    endif

    let [base_url, user] = s:GetBaseURLAndUser(hatena_user)

    let tmpfile = tempname()

    " クッキーを保存するファイル
    if has('win32')
        let cookie_file = g:hatena_base_dir . '\cookies\' . user
    else
        let cookie_file = g:hatena_base_dir . '/cookies/' . user
    endif

    " クッキーがある場合はクッキーでログインを試みる
    if filereadable(cookie_file)
        let reply_header = system(s:curl_cmd . ' ' . base_url . user . '/edit -b "' . cookie_file . '" -D - -o ' . tmpfile)
		if reply_header =~? 'Location: https:'
			" httpsなグループへ
			let base_url = substitute(base_url, '^http', 'https', '')
			let reply_header = system(s:curl_cmd . ' ' . base_url . user . '/edit -b "' . cookie_file . '" -D - -o ' . tmpfile)
		endif
		if reply_header !~? 'Location:'
			echo 'ログインしてます'
			return [base_url, user, cookie_file]
		else
			call delete(cookie_file)
		endif
    endif

    " パスワードでログイン
    let password = inputsecret('Password: ')

    if !len(password)
        echo 'キャンセルしました'
        return []
    endif

    let content = system(s:curl_cmd . ' ' . s:hatena_login_url . ' -d name=' . user . ' -d password=' . password . ' -d mode=enter -c "' . cookie_file . '"')

    call delete(tmpfile)

    if content !~ '<div [^>]*class="error-message"'
        echo 'ログインしました'
        return [base_url, user, cookie_file]
    else
        echoerr 'ログインに失敗しました'
        return []
    endif
endfunction

function! s:HatenaEdit(...) " 編集する
    " ログイン
    if !exists('b:hatena_login_info')
        let hatena_login_info = s:HatenaLogin()
        if !len(hatena_login_info)
            return
        endif
    else
        let hatena_login_info = b:hatena_login_info
    endif

    let [base_url, user, cookie_file] = hatena_login_info

    " 編集する日付を取得
    if a:0 > 0
        let date = a:1
    else
        let date = input('Date: ', strftime('%Y%m%d'))
    endif

    " 20051124, 2005-11-24, 11/24, 24 といった日付を認識
    let pat = '\%(\%(\(\d\d\d\d\)[/-]\=\)\=\(\d\d\)[/-]\=\)\=\(\d\d\)'
    let matches = matchlist(date, pat)
    if !len(matches)
        echoerr '日時のフォーマットが正しくありません！(YYYYMMDD)'
        return
    endif

    let [year, month, day] = matches[1:3]

    if !strlen(day)
        echoerr '日時のフォーマットが正しくありません！(YYYYMMDD)'
        return
    endif

    if !strlen(year)  | let year  = strftime('%Y') | endif
    if !strlen(month) | let month = strftime('%m') | endif

    " 編集ページを取得
    let content = system(s:curl_cmd . ' "' . base_url . user . '/edit?date=' . year . month . day . '" -b "' . cookie_file . '"')
    if base_url =~ 'g.hatena'
        let content = iconv(content, 'utf-8', &enc)
        let fenc = 'utf-8'
    else
        let content = iconv(content, 'euc-jp', &enc)
        let fenc = 'euc-jp'
    endif

    " セッション(編集バッファ)を作成
    let tmpfile = tempname()
    execute g:hatena_edit_command tmpfile
    set filetype=hatena
    setlocal noswapfile
    let &fileencoding = fenc
    let b:rkm = matchstr(content, 'name="rkm"\s*value="\zs[^"]*\ze"')

    if !strlen(b:rkm)
        echoerr 'ログインできませんでした'
        if exists('s:user')
            unlet s:user
        endif
        return
    endif

    let b:hatena_login_info = hatena_login_info
    let b:year  = year
    let b:month = month
    let b:day   = day
    let diary_title = matchstr(content, '<title>\zs.\{-}\ze</title>')
    let day_title   = matchstr(content, '<input .\{-}name="title" .\{-}value="\zs.\{-}\ze"')
    let timestamp   = matchstr(content, 'name="timestamp"\s*value="\zs[^"]*\ze"')
    let body        = s:HtmlUnescape(matchstr(content, '<textarea.\{-}name="body"[^>]*>\zs.\{-}\ze</textarea>'))
    let b:trivial   = g:hatena_always_trivial
    let b:diary_title   = diary_title
    let b:day_title     = day_title
    let b:timestamp     = timestamp
    let b:prev_titlestring = &titlestring

    autocmd BufWritePost <buffer> call s:HatenaUpdate() | autocmd! BufWritePost <buffer>
    autocmd WinLeave <buffer> let &titlestring = b:prev_titlestring
    autocmd WinEnter <buffer> let &titlestring = b:diary_title . ' ' . b:year . '-' . b:month . '-' . b:day . ' [' . b:hatena_login_info[1] . ']'
    let &titlestring = b:diary_title . ' ' . b:year . '-' . b:month . '-' . b:day . ' [' . user . ']'

    let nopaste = !&paste   
    set paste
    execute 'normal i' . body
    if nopaste
        set nopaste
    endif

endfunction

function! s:HatenaUpdate(...) " 更新する
    " 日時を取得
    if !exists('b:hatena_login_info') || !exists('b:year') || !exists('b:month') || !exists('b:day') || !exists('b:day_title') || !exists('b:rkm')
        echoerr ':HatanaEdit してから :HatenaUpdate して下さい'
        return
    endif

    " ログイン
    if !exists('b:hatena_login_info')
        let b:hatena_login_info = s:HatenaLogin()
        if !len(b:hatena_login_info)
            return
        endif
    endif

    let [base_url, user, cookie_file] = b:hatena_login_info

    " まずは全消去
    let post_data = ' -F mode=enter'
                    \ . ' -F year=' . b:year . ' -F month=' . b:month . ' -F day=' . b:day
                    \ . ' -F rkm=' . b:rkm
                    \ . ' -F body= -F title='
    call system(s:curl_cmd . ' ' . base_url . user . '/edit -b "' . cookie_file . '"' . post_data)

    if a:0 > 0
        let b:day_title = a:1
    "else
    "   let b:day_title = input('タイトル: ', b:day_title)
    endif

    if &modified
        write
    endif
    let body_file = expand('%')

    let post_data = ' -F mode=enter'
                    \ . ' -F timestamp=' . b:timestamp . ' -F rkm=' . b:rkm
                    \ . ' -F year=' . b:year . ' -F month=' . b:month . ' -F day=' . b:day
                    \ . ' -F date=' . b:year . b:month . b:day
                    \ . ' -F "body=<' . body_file . '"'
                    \ . ' -F image= -F title=' . b:day_title

    " ポスト
    let result = system(s:curl_cmd . ' ' . base_url . user . '/edit -b "' . cookie_file . '"' . post_data . ' -D -')

    echo '更新しました'
endfunction

function! HatenaEnumUsers(...) " ユーザ名を列挙
    if !exists('g:hatena_users')
        let g:hatena_users = []
    endif
    return g:hatena_users
endfunction

function! s:HtmlUnescape(string) " HTMLエスケープを解除
    let string = a:string
    while match(string, '&#\d\+;') != -1
        let num = matchstr(string, '&#\zs\d\+\ze;')
        let string = substitute(string, '&#\d\+;', nr2char(num), '')
    endwhile
    let string = substitute(string, '&gt;',   '>', 'g')
    let string = substitute(string, '&lt;',   '<', 'g')
    let string = substitute(string, '&quot;', '"', 'g')
    let string = substitute(string, '&amp;',  '\&', 'g')
    return string
endfunction

function! s:GetBaseURLAndUser(hatena_user) " a:hatena_user からグループ/ユーザを取得
    let pair = split(a:hatena_user, ':')
    if len(pair) > 1
        let base_url = printf(s:hatena_group_base_url, pair[0])
        let user = pair[1]
    else
        let base_url = s:hatena_base_url
        let user = a:hatena_user
    endif

    return [base_url, user]
endfunction

" }}}
" ===========================
