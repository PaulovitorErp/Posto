#include 'protheus.ch'
#include 'parmtype.ch'

/*/{Protheus.doc} TRETP023
O ponto de entrada F070TRAVA permite travar, ou destravar os registros da tabela SA1.
Essa a��o � poss�vel mesmo se os registros estiverem sendo utilizados por uma Thread, como na baixa manual, permitindo que outros usu�rios utilizem a tabela.

@obs Ao escolher a op��o N�o, os dados do cliente n�o s�o atualizados.

@author Totvs GO
@since 24/04/2018
@version 1.0
@return Retorna um valor L�gico, permitindo ou n�o o travamento dos registros.

@type function
/*/
User Function TRETP023()

    Local lRet := .T.

    Local lMvPosto := SuperGetMv("MV_XPOSTO",.F.,.F.) //Habilita Posto de Combust�vel (Posto Inteligente).
    //Caso o Posto Inteligente n�o esteja habilitado n�o faz nada...
    If !lMvPosto
        Return lRet
    EndIf

    //Conout(">> F070TRAVA - INICIO - Permite travar ou destravar os registros da SA1. - Data / Hora: "+DTOC(Date())+" / "+Time()+"")
    //Conout(">> F070TRAVA - ProcName(): "+ProcName()+"")

    If IsInCallStack("LJGRVBATCH")
        lRet := .F. //lRet:= MsgYesNo("Deseja travar os registros da tabela SA1 ?")
        //Conout(">> F070TRAVA - Nao ira travar CLIENTE: "+SA1->A1_COD+"/"+SA1->A1_LOJA+" - "+AllTrim(SA1->A1_NOME)+"") 
    EndIf

    //Conout(">> F070TRAVA - FIM - Permite travar ou destravar os registros da SA1. - Data / Hora: "+DTOC(Date())+" / "+Time()+"")
	
Return lRet
