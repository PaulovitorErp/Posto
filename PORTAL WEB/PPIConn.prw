#include 'protheus.ch'

User Function PPIConn()

Local cReturn := "<html><body><center><b>"+;
               "Página AdvPL ASP não encontrada."+;
               "</b></body></html>"
Local cAspPage 
Local nTimer

HttpCache("no-store, no-cache, must-revalidate, post-check=0, pre-check=0, max-age=0")

cAspPage := HTTPHEADIN->MAIN

If !empty(cAspPage)

  nTimer := seconds()
  cAspPage := LOWER(cAspPage)
  //conout("PPICONN - Thread Advpl ASP ["+cValToChar(ThreadID())+"] "+;
  //       "Processando ["+cAspPage+"]")

  //Controlador de paginas
  cReturn := U_PPIContr(cAspPage)

  nTimer := seconds() - nTimer
  //conout("PPICONN - Thread Advpl ASP ["+cValToChar(ThreadID())+"] "+;
  //       "Processamento realizado em "+ alltrim(str(nTimer,8,3))+ "s.")
Endif

Return cReturn