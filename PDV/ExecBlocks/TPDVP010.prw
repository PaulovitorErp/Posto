#include 'protheus.ch'
#include 'parmtype.ch'

/*/{Protheus.doc} TPDVP010 (StSelField)
Ponto de entrada chamado para retornar os campos adicionais
a serem incluídos no processo de importação de cliente.

@author Danilo
@since 02/10/2018
@version 1.0
@return aRet
@type function
/*/
User function TPDVP010()

	Local aRet := {}
	Local cTabela := PARAMIXB[1]

	Local lMvPosto := SuperGetMv("MV_XPOSTO",.F.,.F.) //Habilita Posto de Combustível (Posto Inteligente).
	//Caso o Posto Inteligente não esteja habilitado não faz nada...
	If !lMvPosto
		Return aRet
	EndIf

	if cTabela == "SA1"
		if SA1->(ColumnPos("A1_XFROTA")) > 0
			aadd(aRet, "A1_XFROTA")
		endif
		If SA1->(ColumnPos("A1_XMOTOR")) > 0
			aadd(aRet, "A1_XMOTOR")
		endif
		if SA1->(ColumnPos("A1_XRESTRI")) > 0
			aadd(aRet, "A1_XRESTRI")
		endif
		If SA1->(ColumnPos("A1_XRESTGP")) > 0
			aadd(aRet, "A1_XRESTGP")
		Endif
		If SA1->(ColumnPos("A1_XRESTPR")) > 0
			aadd(aRet, "A1_XRESTPR")
		Endif
		If SA1->(ColumnPos("A1_XTIPONF")) > 0
			aadd(aRet, "A1_XTIPONF")
		Endif
		If SA1->(ColumnPos("A1_XEMCHQ")) > 0
			aadd(aRet, "A1_XEMCHQ")
		Endif
	endif

Return aRet
