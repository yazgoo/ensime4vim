highlight EnError ctermbg=red
ruby <<EOF
    $en_matches = []
EOF
fun EnSend(what)
    ruby <<EOF
    require 'socket'
    s = TCPSocket.new 'localhost', File.read(".ensime_cache/bridge").to_i
    what = VIM::evaluate("a:what")
    s.puts what
    s.close
EOF
endfun
fun EnUnqueue()
ruby <<EOF
    require 'socket'
    require 'json'
    def handle_palyoad payload
        typehint = payload["typehint"]
        if typehint == "NewScalaNotesEvent"
            notes = payload["notes"]
            notes.each do |note|
                l = note["line"]
                c = note["col"] - 1
                e = note["col"] + (note["end"] - note["beg"])
                $en_matches << VIM.evaluate("matchadd('EnError', '\\%#{l}l\\%>#{c}c\\%<#{e}c')")
            end
        elsif typehint == "StringResponse"
            VIM.message(payload["text"])
        elsif typehint == "ArrowTypeInfo"
            VIM.message(payload["name"])
        elsif typehint == "BasicTypeInfo"
            VIM.message(payload["fullName"])
        elsif typehint == "CompletionInfoList"
            array = payload["completions"].collect do |completion|
                completion["name"]
            end.to_json
            File.open("/tmp/ensime_suggests", "w") { |f| f.write array }
            VIM.command("let g:suggests = #{array}")
        end
    end
    s = TCPSocket.new 'localhost', File.read(".ensime_cache/bridge").to_i
    s.puts "unqueue"
    while true
        result = s.readline
        if result.nil? or result.chomp == "nil"
            break
        end
        #VIM::message result
        json = JSON.parse result
        handle_palyoad json["payload"] if json["payload"]

    end
    s.close
EOF
endfun
fun EnTypeCheck()
    call EnSend("typecheck \"".expand('%:p') ."\"")
    ruby <<EOF
    $en_matches.each { |i| VIM.evaluate("matchdelete(#{i})") }
    $en_matches.clear
EOF
endfun
fun EnPathStartSize(what)
    ruby VIM.command("normal e")
    let e = col('.')
    ruby VIM.command("normal b")
    let b = col('.')
    let s = e - b
    call EnSend(a:what." \"".expand('%:p')."\", ".line('.').", ".b.", ".s)
endfun
fun EnComplete()
    call EnSend("complete \"".expand('%:p')."\", ".line('.').", ".col('.'))
endfun
fun EnDocUri()
    call EnPathStartSize("doc_uri")
endfun
fun EnType()
    call EnPathStartSize("type")
endfun
augroup Poi
    autocmd!
    autocmd BufWritePost * call EnTypeCheck()
    autocmd CursorMoved * call EnUnqueue()
augroup END
fun! EnCompleteFunc(findstart, base) 
    if a:findstart 
        call EnComplete()
        " locate the start of the word 
        let line = getline('.') 
        let start = col('.') - 1 
        while start > 0 && line[start - 1] =~ '\a' 
            let start -= 1 
        endwhile 
        return start 
    else 
        while !exists("g:suggests")
            call EnUnqueue()
        endwhile
        " find months matching with "a:base" 
        let res = [] 
        for m in g:suggests
            if m =~ '^' . a:base 
                call add(res, m) 
            endif 
        endfor 
        unlet g:suggests
        return res 
    endif 
endfun 
" via ctrl+X ctrl+U
set completefunc=EnCompleteFunc
command! -nargs=0 EnComplete call EnComplete()
command! -nargs=0 EnType call EnType()
command! -nargs=0 EnTypeCheck call EnTypeCheck()
command! -nargs=0 EnDocUri call EnDocUri()
command! -nargs=0 EnUnqueue call EnUnqueue()
