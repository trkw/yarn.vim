if exists("g:loaded_yarn")
	finish
endif

let g:loaded_yarn = 1

" Settings

function! s:defsetting(name, default)
  if !exists(a:name)
    exec 'let ' . a:name . ' = ' . string(a:default)
  endif
endfunction

" If set to non-zero, runs all commands in background (so you lose their
" output).
call s:defsetting('g:yarn_background', 0)

" If some NPM commands aren't being picked up, add them with this list.
call s:defsetting('g:yarn_custom_commands', [])

function! Yarn(...)
  if len(a:000)
    call s:yarn_command(a:000[0], a:000[1:])
  else
    call s:yarn_command('install', [])
  endif
endfunction

function! s:yarn_command(cmd, args)
  let cmd = join(['yarn', a:cmd] + map(a:args, 'shellescape(v:val)'), ' ')
  let out = system(cmd)
  if !g:yarn_background
    echo out
  endif
endfunction

function! YarnComplete(arg_lead, cmd_lead, cursor_pos)
  if !exists('g:yarn_commands')
    let g:yarn_commands = s:load_yarn_commands()
  endif
  let commands = copy(g:yarn_commands + g:yarn_custom_commands)
  return filter(commands, 'v:val =~ "^' . a:arg_lead . '"')
endfunction

function! s:load_yarn_commands()
  let yarn_help = system('yarn help')
  if v:shell_error != 0
    " Report an error here?
    return []
  else
    " This is so much simpler with sed :^(
    let lines = []
    let in_commands = 0
    for line in split(yarn_help, '\n')
      if line =~ '^where <command>'
        let in_commands = 1
      elseif in_commands
        if line =~ '^$'
          break
        endif
        call add(lines, line)
      endif
    endfor
    let joined = join(map(lines, 'substitute(v:val, ",", "\n", "g")'), "\n")
    return filter(
          \map(split(joined, "\n"),
            \'substitute('
              \.'substitute(v:val, "^\\s\\+", "", "g"),'
              \.'"\\s\\+$", "", "g")'),
          \'v:val != ""')
  endif
endfunction

" Usage: :Yarn <command> [args...]
command! -complete=customlist,YarnComplete -nargs=* Yarn :call Yarn(<f-args>)