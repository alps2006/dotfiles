" Description:	Omni completion utils script
" Maintainer:   fanhe <fanhed@163.com>
" Create:       2011 May 11
" License:      GPLv2


" Expression used to ignore comments
" Note: this expression drop drastically the performance
"let omnicpp#utils#sCommentSkipExpr = 
            "\"synIDattr(synID(line('.'), col('.'), 0), 'name') "
            "\"=~? 'comment\\|string\\|character'"
" This one is faster but not really good for C comments
" 匹配了以下字符串后则认为在注释中, 近似测试
" //, /*, */
" BUG: 不知道为什么, 下面的表达式无法工作
let omnicpp#utils#sCommentSkipExpr = "getline('.') =~# '\\V//\\|/*\\|*/'"
let omnicpp#utils#sCommentSkipExpr = ''

let s:dCppBuiltinTypes = {
            \'bool': 1, 
            \'char': 1, 
            \'double': 1, 
            \'float': 1, 
            \'int': 1, 
            \'long': 1, 
            \'short': 1, 
            \'signed': 1, 
            \'unsigned': 1, 
            \'void': 1, 
            \'wchar_t': 1, 
            \'short int': 1, 
            \'long long': 1, 
            \'long double': 1, 
            \'long long int': 1, 
            \}

" 比较两个光标位置 
function! omnicpp#utils#CmpPos(pos1, pos2) "{{{2
	let pos1 = a:pos1
	let pos2 = a:pos2
	if pos1[0] > pos2[0]
		return 1
	elseif pos1[0] < pos2[0]
		return -1
	else
		if pos1[1] > pos2[1]
			return 1
		elseif pos1[1] < pos2[1]
			return -1
		else
			return 0
		endif
	endif
endfunc
"}}}
" 获取当前语句的开始位置, 若当前语句为空, 返回 [0, 0]
" Note: 
"   1. 当前语句的开始位置可能是预处理的行或者字符串或者注释
"      若想剔除预处理的行, 可在获取代码的时候过滤掉
"   2. 返回的位置可能在原始位置的后面, 需要调用者检查
function! omnicpp#utils#GetCurStatementStartPos(...) "{{{2
    let origCursor = getpos('.')
    let origPos = origCursor[1:2]

    let result = [0, 0]

    while searchpos('[;{}]\|\%^', 'bW') != [0, 0]
        if omnicpp#utils#IsCursorInCommentOrString()
            continue
        else
            break
        endif
    endwhile

    if getpos('.')[1:2] == [1, 1] " 到达文件头的话, 接受光标所在位置的匹配
        let result = searchpos('[^ \t]', 'Wc')
    else
        let result = searchpos('[^ \t]', 'W')
    endif

    if a:0 > 0 && a:1
        " 如果传入参数且非零, 移动光标
    else
        call setpos('.', origCursor)
    endif

    return result
endfunc
"}}}
" Get code without comments and with empty strings
" szSingleLine must not have carriage return
" 获取行字符串中的有效 C/C++ 代码, 双引号中的字符串会被清空
" 要求字符串中不能有换行符, 亦即只能处理单行的字符串
" TODO: 清理 # 预处理
function! omnicpp#utils#GetCodeFromLine(szSingleLine) "{{{2

    " 清理预处理
    if match(a:szSingleLine, '^\s*#') >= 0
        return ''
    endif

    " We set all strings to empty strings, it's safer for 
    " the next of the process
	" TODO: '"\"", foo, "foo"'
	" 方法是替换不匹配 \" 的 " 的最小长度的匹配
    let szResult = substitute(a:szSingleLine, '".*"', '""', 'g')

    " Removing C++ comments, we can use the pattern ".*" because
    " we are modifying a line
    let szResult = substitute(szResult, '\/\/.*', '', 'g')

    " Now we have the entire code in one line and we can remove C comments
    return s:RemoveCComments(szResult)
endfunc
"}}}
" Remove C comments on a line
function! s:RemoveCComments(szLine) "{{{2
    let result = a:szLine

    " We have to match the first '/*' and first '*/'
    let startCmt = match(result, '\/\*')
    let endCmt = match(result, '\*\/')
    while startCmt != -1 && endCmt != -1 && startCmt < endCmt
        if startCmt > 0
            let result = result[ : startCmt-1 ] . result[ endCmt+2 : ]
        else
            " Case where '/*' is at the start of the line
            let result = result[ endCmt+2 : ]
        endif
        let startCmt = match(result, '\/\*')
        let endCmt = match(result, '\*\/')
    endwhile
    return result
endfunc
"}}}
" Get a c++ code from current buffer from [lineStart, colStart] to 
" [lineEnd, colEnd] without c++ and c comments, without end of line
" and with empty strings if any
" @return a string
function! omnicpp#utils#GetCode(posStart, posEnd) "{{{2
	"TODO: 处理反斜杠续行
    let posStart = a:posStart
    let posEnd = a:posEnd
    if a:posStart[0] > a:posEnd[0]
        let posStart = a:posEnd
        let posEnd = a:posStart
    elseif a:posStart[0] == a:posEnd[0] && a:posStart[1] > a:posEnd[1]
        let posStart = a:posEnd
        let posEnd = a:posStart
    endif

    " Getting the lines
    let lines = getline(posStart[0], posEnd[0])
    let lenLines = len(lines)

    " Formatting the result
    let result = ''
    if lenLines == 1
        let sStart = posStart[1] - 1
        let sEnd = posEnd[1] - 1
        let line = lines[0]
        let lenLastLine = strlen(line)
        let sEnd = (sEnd > lenLastLine) ? lenLastLine : sEnd
        if sStart >= 0
            let result = omnicpp#utils#GetCodeFromLine(line[ sStart : sEnd ])
        endif
    elseif lenLines > 1
        let sStart = posStart[1] - 1
        let sEnd = posEnd[1] - 1
        let lenLastLine = strlen(lines[-1])
        let sEnd = (sEnd > lenLastLine)?lenLastLine : sEnd
        if sStart >= 0
            let lines[0] = lines[0][ sStart : ]
            let lines[-1] = lines[-1][ : sEnd ]
            for aLine in lines
                let result = result . omnicpp#utils#GetCodeFromLine(aLine)." "
            endfor
            let result = result[:-2]
        endif
    endif

    " Now we have the entire code in one line and we can remove C comments
    return s:RemoveCComments(result)
endfunc
"}}}
" Check if the cursor is in comment or string
" 根据语法检测光标是否在注释或字符串中或 include 预处理中
function! omnicpp#utils#IsCursorInCommentOrString() "{{{2
    " FIXME: case. |"abc" . 判定为在字符串中
    for nID in synstack(line('.'), col('.'))
        if synIDattr(nID, 'name') =~? 'comment\|string\|character'
            return 1
        endif
    endfor
    return 0
endfunc
"}}}
" Tokenize the current instruction until the cursor position.
" Param:    可选参数为附加字符串, 或控制是否简化代码为 omni 分析用 tokens
" Return:   list of tokens
function! omnicpp#utils#TokenizeStatementBeforeCursor(...) "{{{2
    let szAppendText = ''
    let bSimplify = 0
    if a:0 > 0 && type(a:1) == type('')
        let szAppendText = a:1
    elseif a:0 > 0 && type(a:1) == type(0)
        let bSimplify = a:1
    endif

    " TODO: 排除注释和字符串中的匹配
    let startPos = searchpos('[;{}]\|\%^', 'bWn')
    let curPos = getpos('.')[1:2]
    " We don't want the character under the cursor
    let column = curPos[1] - 1
    let curPos[1] = column
    " Note: [1:] 剔除了上一条语句的结束符
    if curPos[1] < 1
        let curPos[1] = 1
        " 当光标在第一列的时候, 会包含第一列的字符. 剔除之.
        let szCode = omnicpp#utils#GetCode(startPos, curPos)[1:-2] . szAppendText
    else
        let szCode = omnicpp#utils#GetCode(startPos, curPos)[1:] . szAppendText
    endif
    if bSimplify
        let szCode = omnicpp#utils#SimplifyCodeForOmni(szCode)
    endif
    return omnicpp#tokenizer#Tokenize(szCode)
endfunc
"}}}
function! omnicpp#utils#GetCurStatementBeforeCursor(...) "{{{
    let bSimplify = 0
    if a:0 > 0
        let bSimplify = a:1
    endif

    let curPos = getpos('.')[1:2]
    let startPos = omnicpp#utils#GetCurStatementStartPos()
    " 不包括光标下的字符
    let szCode = omnicpp#utils#GetCode(startPos, curPos)[:-2]
    if bSimplify
        let szCode = omnicpp#utils#SimplifyCodeForOmni(szCode)
    endif

    return szCode
endfunc
"}}}
" 简化 omni 补全请求代码, 效率不是太高
" eg1. A::B("\"")->C(" a(\")z ", ')'). -> A::B()->C().
" eg2. ((A*)(B))->C. -> ((A*)B)->C.
" cg3. static_cast<A*>(B)->C. -> (A*)B->C.
" egx. A::B(C.D(), ((E*)F->G)). -> A::B().
function! omnicpp#utils#SimplifyCodeForOmni(sOmniCode) "{{{2
	let s = a:sOmniCode
	
    " 1. 把 C++ 的 cast 转为 标准 C 的 cast
    "    %s/\%(static_cast\|dynamic_cast\)\s*<\(.\+\)>(\(\w\+\))/((\1)\2)/gc
    let s = substitute(
                \s, 
                \'\C\%(static_cast\|dynamic_cast\|reinterpret_cast' 
                \    .'\|const_cast\)\s*<\(.\+\)>(\(\w\+\))', 
                \'((\1)\2)', 
                \'g')
	" 2. 清理函数函数
	let s = s:StripFuncArgs(s)
	" 3. 清理多余的括号, 不会检查匹配的情况. eg. ((A*)((B))) -> ((A*)B)
	" TODO: 需要更准确
	"let s = substitute(s, '\W\zs(\+\(\w\+\))\+\ze', '\1', 'g')

	return s
endfunc
"}}}
" 剔除所有函数参数, 仅保留一个括号
function! s:StripFuncArgs(szOmniCode) "{{{2
	let s = a:szOmniCode

	" 1. 清理引号内的 \" , 因为正则貌似是不能直接匹配 ("\"")
	let s = substitute(s, '\\"', '', 'g')
	" 2. 清理双引号的内容, 否则双引号内的括号会干扰括号替换
	let s = substitute(s, '".\{-}"', '', 'g')
	" 3. 清理 '(' 和 ')', 避免干扰
	let s = substitute(s, "'('\\|')'", '', 'g')

	let szResult = ''
	let nStart = 0
	while nStart < len(s) && nStart != -1
		let nEnd = matchend(s, '\w\s*(', nStart)
		if nEnd != -1
			let szResult .= s[nStart : nEnd - 1]

			let nStart = nEnd
			let nCount = 1
			" 开始寻找匹配的 ) 的位置
			for i in range(nStart, len(s) - 1)

				let c = s[i]

				if c == '('
					let nCount += 1
				elseif c == ')'
					let nCount -= 1
				endif

				if nCount == 0
					let nStart = i + 1
					let szResult .= ')'
					break
				endif
			endfor

		else
			let szResult .= s[nStart :]
			break
		endif
	endwhile

	return szResult
endfunc
"}}}
" 从一条语句中获取变量信息, 无法判断是否非法声明
" eg1. const MyClass&
" eg2. const map < int, int >&
" eg3. MyNs::MyClass
" eg4. ::MyClass**
" eg5. MyClass a, *b = NULL, c[1] = {};
" eg6. A<B>::C::D<E, F>::G g;
" eg7. hello(MyClass1 a, MyClass2* b
" eg8. Label: A a;
function! omnicpp#utils#GetVariableType(sDecl, ...) "{{{2
    if type(a:sDecl) == type('')
        let lTokens = omnicpp#tokenizer#Tokenize(a:sDecl)
    else
        let lTokens = a:sDecl
    endif

    let sVarName = ''
    if a:0 > 0
        let sVarName = a:1
    endif

    let dTypeInfo = {'name': '', 'til': [], 'types': []}

    let idx = 0
    let nState = 0
    " 0 -> 期望 '::' 和 单词, 作为解析的起点. eg1. |::A eg2. |A::B
    " 1 -> 期望 单词. eg. A::|B
    " 2 -> 期望 '::'. eg. A|::B 也可能是 A|<B>::C
    while idx < len(lTokens)
        let dCurToken = lTokens[idx]
        if nState == 0
            if dCurToken.value ==# '::'
                " eg. ::A a
                let dTypeInfo.name .= dCurToken.value
                let dSingleType = {'name': '', 'til': []}
                let dSingleType.name = '<global>'
                call add(dTypeInfo.types, dSingleType)

                let nState = 1
            elseif dCurToken.kind == 'cppWord'
                if dCurToken.value ==# sVarName
                    " 居然遇到同名的, 肯定在之前已经定义了, 结束
                    break
                endif

                let dTypeInfo.name .= dCurToken.value
                let dSingleType = {'name': '', 'til': []}
                let dSingleType.name = dCurToken.value
                call add(dTypeInfo.types, dSingleType)

                let nState = 2
            elseif dCurToken.kind == 'cppKeyword'
                if has_key(s:dCppBuiltinTypes, dCurToken.value)
                    let dTypeInfo.name .= dCurToken.value

                    " short int
                    " long long
                    " long long int
                    " long double
                    if dCurToken.value ==# 'long'
                        let idx = idx + 1
                        while idx < len(lTokens)
                            if lTokens[idx].value =~# 'long\|int\|double'
                                let dTypeInfo.name .= 
                                            \' ' . lTokens[idx].value
                            else
                                let idx -= 1
                                break
                            endif
                            let idx += 1
                        endwhile
                    elseif dCurToken.value ==# 'short'
                        if idx + 1 < len(lTokens) 
                                    \&& lTokens[idx+1].value ==# 'int'
                            let dTypeInfo.name .= 
                                        \' ' . lTokens[idx+1].value
                            let idx = idx + 1
                        endif
                    endif

                    let dSingleType = {'name': '', 'til': []}
                    let dSingleType.name = dTypeInfo.name
                    call add(dTypeInfo.types, dSingleType)

                    " 内置类型, 可能结束, 需要检查此语法是否有函数
                    let nState = 2
                endif
            endif
        elseif nState == 1
            if dCurToken.kind == 'cppWord'
                let dTypeInfo.name .= dCurToken.value
                let dSingleType = {'name': '', 'til': []}
                let dSingleType.name = dCurToken.value
                call add(dTypeInfo.types, dSingleType)

                let nState = 2
            else
                " 有语法错误?
                " eg. A::| *
                break
            endif
        elseif nState == 2
            if dCurToken.value ==# '::'
                let dTypeInfo.name .= dCurToken.value
                let nState = 1
            elseif dCurToken.value ==# '<'
                " 上一个解析完毕的标识符是模版类
                let nTmpIdx = idx
                let nTmpCount = 0
                let sUnitType = ''
                while nTmpIdx < len(lTokens)
                    let dTmpToken = lTokens[nTmpIdx]
                    if dTmpToken.value ==# '<'
                        let nTmpCount += 1
                        if nTmpCount == 1
                            let sUnitType = ''
                        else
                            let sUnitType .= ' ' . dTmpToken.value
                        endif
                    elseif dTmpToken.value ==# '>'
                        let nTmpCount -= 1
                        if nTmpCount == 0
                            call add(dTypeInfo.types[-1].til, sUnitType)
                            break
                        else
                            let sUnitType .= ' ' . dTmpToken.value
                        endif
                    elseif dTmpToken.value ==# ','
                        if nTmpCount == 1
                            call add(dTypeInfo.types[-1].til, sUnitType)
                            let sUnitType = ''
                        else
                            let sUnitType .= ' ' . dTmpToken.value
                        endif
                    else
                        " 会有比较多多余的空格
                        let sUnitType .= ' ' . dTmpToken.value
                    endif
                    let nTmpIdx += 1
                endwhile

                let idx = nTmpIdx
            elseif dCurToken.value ==# '('
                " 处理函数形参中的变量声明
                " 之前分析的是函数, 重新再来
                let dTypeInfo = {'name': '', 'til': [], 'types': []}
                let nState = 0

                let nRestartIdx = idx + 1
                let nTmpIdx = nRestartIdx
                let nTmpCount = 0 " 记录 '<' 的数量
                while sVarName !=# '' && nTmpIdx < len(lTokens)
                    let dTmpToken = lTokens[nTmpIdx]
                    if dTmpToken.value ==# '<'
                        let nTmpCount += 1
                    elseif dTmpToken.value ==# '>'
                        let nTmpCount -= 1
                    " Tokenize 函数有 bug, '"",' 和 "''," 作为单个 token
                    elseif dTmpToken.value ==# ','
                                \|| dTmpToken.value ==# '"",' 
                                \|| dTmpToken.value ==# "'',"
                        if nTmpCount == 0
                            let nRestartIdx = nTmpIdx + 1
                        endif
                    elseif dTmpToken.kind == 'cppWord' 
                                \&& dTmpToken.value ==# sVarName
                        break
                    endif
                    let nTmpIdx += 1
                endwhile

                let idx = nRestartIdx
                continue
            else
                " 期望 '::', 遇到了其他东东
                if dCurToken.value ==# ':'
                    " 遇到标签, 重新开始
                    " eg. Label: A a;
                    let dTypeInfo = {'name': '', 'til': [], 'types': []}
                else
                    " 检查是否有函数
                    " eg. int |A(B b, C c)
                    let nTmpIdx = idx + 1
                    let nHasFunc = 0
                    while nTmpIdx < len(lTokens)
                        let dTmpToken = lTokens[nTmpIdx]
                        if dTmpToken.value ==# '(' 
                            " 有函数, 进入函数处理入口
                            let idx = nTmpIdx
                            let nHasFunc = 1
                            break
                        endif
                        let nTmpIdx += 1
                    endwhile

                    if nHasFunc
                        continue
                    else
                        break
                    endif
                endif
            endif
        endif

        let idx += 1
    endwhile

    if len(dTypeInfo.types)
        let dTypeInfo.til = dTypeInfo.types[-1].til
    endif

    return dTypeInfo
endfunction
"}}}
" vim:fdm=marker:fen:expandtab:smarttab:fdl=1: