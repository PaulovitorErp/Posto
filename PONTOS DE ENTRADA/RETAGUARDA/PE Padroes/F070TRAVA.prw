#include 'protheus.ch'
#include 'parmtype.ch'

/*/{Protheus.doc} F070TRAVA
O ponto de entrada F070TRAVA permite travar, ou destravar os registros da tabela SA1.
Essa a��o � poss�vel mesmo se os registros estiverem sendo utilizados por uma Thread, como na baixa manual, permitindo que outros usu�rios utilizem a tabela.

@obs Ao escolher a op��o N�o, os dados do cliente n�o s�o atualizados.

@author Totvs GO
@since 24/04/2018
@version 1.0
@return Retorna um valor L�gico, permitindo ou n�o o travamento dos registros.

@type function
/*/
User Function F070TRAVA()

	Local lRet := .T.

	///////////////////////////////////////////////////////////////////////////////////////////
	//             FUNCAO DO PACOTE POSTO INTELIGENTE - FAVOR NAO COMENTAR                  //
	/////////////////////////////////////////////////////////////////////////////////////////
	If ExistBlock("TRETP023")
		lRet := ExecBlock("TRETP023",.F.,.F.)
	EndIf

Return lRet
