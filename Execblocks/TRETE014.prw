#include 'protheus.ch'
#include 'parmtype.ch'

/*/{Protheus.doc} TRETE014
Retorna a Data para Faturamento, a ser gravada no campo E1_XDTFATU

@author thebr
@since 17/12/2018
@version 1.0
@return dDtFat
@type function
/*/
User function TRETE014(cCond,dVencto)

	Local aArea		:= GetArea()
	Local dDtFat 	:= CToD("")

	DbSelectArea("SE4")
	SE4->(DbSetOrder(1)) //E4_FILIAL+E4_CODIGO
	If SE4->(FieldPos("E4_XRETFAT")) > 0 .AND. !Empty(cCond) .And. !Empty(dVencto)
		If SE4->(DbSeek(xFilial("SE4")+cCond))
			dDtFat := dVencto - SE4->E4_XRETFAT
		Endif
	Endif

	RestArea(aArea)

Return dDtFat