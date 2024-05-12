#include 'protheus.ch'
#include 'parmtype.ch'


/*/{Protheus.doc} STMenEdt
Este ponto de entrada � executado na inicializa��o da rotina TotvsPDV para edi��o dos itens no menu.
Possui como par�metro de entrada, o array referente ao menu do TotvsPDV e retorna os itens de menu que ser�o exibidos na janela do TotvsPDV.

@author pablo
@since 16/10/2018
@version 1.0
@return aMenu
@type function
/*/
User Function STMenEdt()

	Local aParam  := aClone(ParamIxb)
	Local aPEMenu := {} //Array que recebe os itens do ponto de entrada

	///////////////////////////////////////////////////////////////////////////////////////////
	//             FUNCAO DO PACOTE POSTO INTELIGENTE - FAVOR NAO COMENTAR                  //
	/////////////////////////////////////////////////////////////////////////////////////////
	If ExistBlock("TPDVP002")
		aPEMenu := ExecBlock("TPDVP002",.F.,.F.,aParam)
	Endif

Return aPEMenu