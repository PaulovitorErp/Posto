#include 'protheus.ch'
#include 'parmtype.ch'

/*/{Protheus.doc} TRETP021
LJ7095 - Trava/Destrava bloqueio de processamento GravaBatch quando registro do cliente da venda com Lock

Obs.:
Validação é realizada no GravaBatch para evitar erro de Lock, na atualização do cliente pela rotina MatxAtu(A040DupRec),
para tratamento deve ser utilizado também o Ponto de Entrada F040TRVSA1.

Quando o Ponto de Entrada F040TRVSA1 retorna .F.,
os campos (A1_PRICOM, A1_ULTCOM, A1_NROCOM, A1_VACUM) não serão atualizados.

Nesse Ponto o registro do SA1 está posicionado no cliente da Venda 
O ponto de entrada será acionado antes de gravar a venda como ER,
respeitando assim configurações do Job LJGRVBATCH para reprocessar venda quando lock

@author Totvs GO
@since 20/04/2018
@version 1.0

@return Lógico (Se .T., permite continuar a gravação com registro Lock)

@type function
/*/
User Function TRETP021() 

    Local lRet := .F.

    Local lMvPosto := SuperGetMv("MV_XPOSTO",.F.,.F.) //Habilita Posto de Combustível (Posto Inteligente).
    //Caso o Posto Inteligente não esteja habilitado não faz nada...
    If !lMvPosto
        Return lRet
    EndIf

    //Conout(">> LJ7095 - INICIO - Trava/Destrava bloqueio de processamento GravaBatch quando registro do cliente da venda com Lock. - Data / Hora: "+DTOC(Date())+" / "+Time()+"")
    //Conout(">> LJ7095 - ProcName(): "+ProcName()+"")

    If IsInCallStack("LJGRVBATCH")
        lRet := .T. //SA1 posicionada no cliente da venda com Lock, permite validar dados da SA1 para continar, se retorno .T. continua a gravação da venda 
        //Conout(">> LJ7095 - Continua a gravação da venda para o CLIENTE: "+SA1->A1_COD+"/"+SA1->A1_LOJA+" - "+AllTrim(SA1->A1_NOME)+"") 
    EndIf

    //Conout(">> LJ7095 - FIM - Trava/Destrava bloqueio de processamento GravaBatch quando registro do cliente da venda com Lock. - Data / Hora: "+DTOC(Date())+" / "+Time()+"") 

Return lRet
