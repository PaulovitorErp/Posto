#include "PROTHEUS.CH"
#include "TOPCONN.CH"

/*/{Protheus.doc} MT103FIM
O ponto de entrada MT103FIM encontra-se no final da fun��o A103NFISCAL.
Ap�s o destravamento de todas as tabelas envolvidas na grava��o do documento de entrada, depois de fechar a opera��o realizada neste.
� utilizado para realizar alguma opera��o ap�s a grava��o da NFE.

@author Totvs
@since 04/11/14
@version 1.0
@return Nulo
@type function
/*/

User Function MT103FIM()

	Local aParam := aClone(PARAMIXB)

	/////////////////////////////////////////////////////////////////////////////////////////
	//             FUNCAO DO PACOTE POSTO INTELIGENTE - FAVOR NAO COMENTAR                 //
	/////////////////////////////////////////////////////////////////////////////////////////
	If ExistBlock("TRETP007")
		Execblock("TRETP007",.F.,.F.,aParam)
	EndIf

Return(Nil)
