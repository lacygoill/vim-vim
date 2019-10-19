fu vim#refactor#break_bar#main(_) abort
    let indent = matchstr(getline('.'), '^\s*')
    sil s/\s*|\s*/\="\r"..indent..'\ | '/ge
    let range = line("'[")..','..line("']")
    exe range..'norm! =='
    update
endfu

