#include 'protheus.ch'
#include 'parmtype.ch'

/*/{Protheus.doc} LJ7095
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
User Function LJ7095()

	Local lRet	 := .F.

	///////////////////////////////////////////////////////////////////////////////////////////
	//             FUNCAO DO PACOTE POSTO INTELIGENTE - FAVOR NAO COMENTAR                  //
	/////////////////////////////////////////////////////////////////////////////////////////
	If ExistBlock("TRETP021")
		lRet := ExecBlock("TRETP021",.F.,.F.)
	EndIf

Return lRet
