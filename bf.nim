import os
import math
import strutils

var logmode = false

proc log(args:varargs[string,`$`]) =
  if logmode==true: echo join args," "

type
  Token = ref object of RootObj
    ttype:string
  Loop = ref object of Token
    code:seq[Token]
    raw:string

proc parsebf(src:string):seq[Token] =
  var
    res:seq[Token] = @[]
    i=0
    loopStart=0
    looplev=0
  while i<src.len:
    if looplev==0:
      case src[i]
      of '>':
        res.add Token(ttype:"next")
      of '<':
        res.add Token(ttype:"prev")
      of '+':
        res.add Token(ttype:"inc")
      of '-':
        res.add Token(ttype:"dec")
      of '.':
        res.add Token(ttype:"out")
      of ',':
        res.add Token(ttype:"inp")
      of '[':
        looplev+=1
        i+=1
        loopStart=i
        while looplev>0:
          case src[i]
          of '[':
            looplev+=1
          of ']':
            looplev-=1
          else:
            discard
          i+=1
        i-=1
        log "parse: ",src[loopStart..<i]," ",i," ",loopStart
        res.add Loop(code:parsebf(src[loopStart..<i]),ttype:"loop",raw:src[loopStart..<i])
      else: 
        discard
    i+=1
  return res

proc runbf(l:seq[Token],mem:var seq[uint8],i:var int):uint8 =
  for x in l:
    log "running: ", x.ttype ," m=", mem
    case x.ttype
    of "next":
      i+=1
      while (mem.len-1)<i:
        mem.add 0
      log "next: ", i ," ", mem.len
    of "prev":
      i-=1
    of "inc":
      log "inc: ",i
      mem[i]+=1
    of "dec":
      mem[i]-=1
    of "out":
      stdout.write mem[i].chr
    of "inp":
      mem[i]=stdin.readChar.uint8
    of "loop":
      let code = Loop(x).code
      while mem[i]!=0:
        discard code.runbf(mem,i)
    else:
      log "invalid token: "&x.ttype
      break
  return mem[0]
if paramCount()==0:
  var
    mem:seq[uint8] = @[0.uint8]
  while true:
    stdout.write ": "
    var r:string = stdin.readLine()
    case r
    of ".exit":
      break
    else:
      let tkns = parsebf(r)
      var i = 0
      log runbf(
        tkns,
        mem,
        i
      )
else:
  var
    path = paramStr(1)
    f = open(path,FileMode.fmRead)
    mem:seq[uint8] = @[0.uint8]
    i = 0
    rawcode = f.readAll
  close(f)
  discard rawcode.parsebf.runbf(mem,i)