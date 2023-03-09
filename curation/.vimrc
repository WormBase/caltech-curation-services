:set nocompatible
set ruler
" set tw=80
set showmatch
map f 0i# +
map z 0i// +
:syntax off
:filetype plugin off		" turn off indenting by ignoring all file types 
let loaded_matchparen = 1	" tells vim job already done :help pi_paren.txt
au FileType * setl fo-=cro	" disable auto comment
:set pastetoggle=<F3>		" indent off in paste mode
:  silent! %s/=\n//g 
function! Meep()
  silent! %s/=\n> //g 
  silent! %s/=0A/> /g 
  silent! %s/=E2=80=9C/"/g 
  silent! %s/=E2=80=9D/"/g 
  silent! %s/=E2=80=99/'/g 
  silent! %s/=E2=80=98/'/g 
  silent! %s/=C3=AD/í/g 
  silent! %s/=C3=B3/ó/g 
  silent! %s/=C3=A9/á/g 
  silent! %s/=F0=9F=92=95=20/<3<3/g 
  silent! %s/=A0//g 
  silent! %s/=20/ /g 
  silent! %s/=2C/,/g 
  silent! %s/=C2//g 
  silent! %s/=3D/=/g 
  silent! %s/=3B/:/g 
  silent! %s/=85/.../g 
  silent! %s/=E2=80=A6/.../g 
  silent! %s/=F0=9F=98=84/=)/g 
  silent! %s/=92/'/g 
  silent! %s/=93/"/g 
  silent! %s/=94/"/g 
  silent! %s/=97/--/g 
endfunction
map t :call Meep()1G
" :map <F5> :!wc -w %; sleep 1 <Enter><Enter>	" output word count of current file to screen for 1 second
