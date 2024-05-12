#include 'protheus.ch'
#include 'parmtype.ch'

/*/{Protheus.doc} TRETP021
LJ7095 - Trava/Destrava bloqueio de processamento GravaBatch quando registro do cliente da venda com Lock

Obs.:
Valida��o � realizada no GravaBatch para evitar erro de Lock, na atualiza��o do cliente pela rotina MatxAtu(A040DupRec),
para tratamento deve ser utilizado tamb�m o Ponto de Entrada F040TRVSA1.

Quando o Ponto de Entrada F040TRVSA1 retorna .F.,
os campos (A1_PRICOM, A1_ULTCOM, A1_NROCOM, A1_VACUM) n�o ser�o atualizados.

Nesse Ponto o registro do SA1 est� posicionado no cliente da Venda 
O ponto de entrada ser� acionado antes de gravar a venda como ER,
respeitando assim configura��es do Job LJGRVBATCH para reprocessar venda quando lock

@author Totvs GO
@since 20/04/2018
@version 1.0

@return L�gico (Se .T., permite continuar a grava��o com registro Lock)

@type function
/*/
User Function TRETP021() 

    Local lRet := .F.

    Local lMvPosto := SuperGetMv("MV_XPOSTO",.F.,.F.) //Habilita Posto de Combust�vel (Posto Inteligente).
    //Caso o Posto Inteligente n�o esteja habilitado n�o faz nada...
    If !lMvPosto
        Return lRet
    EndIf

    //Conout(">> LJ7095 - INICIO - Trava/Destrava bloqueio de processamento GravaBatch quando registro do cliente da venda com Lock. - Data / Hora: "+DTOC(Date())+" / "+Time()+"")
    //Conout(">> LJ7095 - ProcName(): "+ProcName()+"")

    If IsInCallStack("LJGRVBATCH")
        lRet := .T. //SA1 posicionada no cliente da venda com Lock, permite validar dados da SA1 para continar, se retorno .T. continua a grava��o da venda 
        //Conout(">> LJ7095 - Continua a grava��o da venda para o CLIENTE: "+SA1->A1_COD+"/"+SA1->A1_LOJA+" - "+AllTrim(SA1->A1_NOME)+"") 
    EndIf

    //Conout(">> LJ7095 - FIM - Trava/Destrava bloqueio de processamento GravaBatch quando registro do cliente da venda com Lock. - Data / Hora: "+DTOC(Date())+" / "+Time()+"") 

Return lRet
