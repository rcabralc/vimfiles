setlocal syntax=rst

syntax region rstDoctestExample start="^\s\+\(>>>\|\.\.\.\)" end="^$" contains=rstDoctestTest,rstDoctestOutput
syntax match rstDoctestOutput "^\s\+\([^>.]\{3\}.*\|.\{1,2\}\)$" contained
syntax match rstDoctestTest "^\s\+\(>>>\|\.\.\.\).*$" contained


hi link rstDoctestTest Statement
hi link rstDoctestOutput Special
