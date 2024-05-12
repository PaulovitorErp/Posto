#include 'protheus.ch'
#include 'parmtype.ch'

/*/{Protheus.doc} STIPAYCST
Ponto de Entrada para Incluir a forma de pagamento Especifica.

@author pablo
@since 20/11/2018
@version 1.0
@return nil
@type function
/*/
User Function TPDVP004()

	Local cTpForm := ParamIxb[2]
	Local lMvPswVend := SuperGetMv("TP_PSWVEND",,.F.)
	Local cFPConv := SuperGetMv("TP_FPGCONV",,"")
	Local lRet := .F. // Nao abre o painel de pagamento padrao

	Local lMvPosto := SuperGetMv("MV_XPOSTO",.F.,.F.) //Habilita Posto de Combustível (Posto Inteligente).
	//Caso o Posto Inteligente não esteja habilitado não faz nada...
	If !lMvPosto
		Return .T. //abre o painel de pagamento padrao
	EndIf

	//SETA VENDEDOR LOGADO
	If lMvPswVend
		U_TpAtuVend()
	endif

	//Opções de pagamento que terão a TELA CUSTOMIZADA
	If Alltrim(cTpForm) $ 'R$|CC|CD|CH|NB|NP|CF|PX|CT|'+cFPConv
		U_TPDVE004(cTpForm, ParamIxb[1])
	Else
		lRet := .T. //abre o painel de pagamento padrao
	Endif

Return lRet
