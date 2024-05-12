#include 'protheus.ch'


/*/{Protheus.doc} TRETP031 (PE MT103IPC)
Gravar a descrição do produto na tabela SD1
Gravar o CRC 

@author Totvs TBC
@since 25/08/10
@version 1.0
@return logico

@type function
/*/

User Function TRETP031()

	Local _z
    //Local _nItem	:= Paramixb[1]

	Local lMvPosto := SuperGetMv("MV_XPOSTO",.F.,.F.) //Habilita Posto de Combustível (Posto Inteligente).
    //Caso o Posto Inteligente não esteja habilitado não faz nada...
	If !lMvPosto
		Return
	EndIf

	For _z:=1 to Len(acols)
		nPosCrc    := aScan(aHEADER,{|x| Upper(AllTrim(x[2])) == "D1_XCRC"})
		Acols[_z,nPosCrc] := SC7->C7_XCRC

		//marajo
		If SD1->(FieldPos("D1_XDESCRI")) > 0
			nPosDescri := aScan(aHeader,{|x| Upper(AllTrim(x[2])) == "D1_XDESCRI"})
			nPosCodigo := aScan(aHeader,{|x| Upper(AllTrim(x[2])) == "D1_COD"})
			Acols[_z,nPosDescri] := SB1->(POSICIONE("SB1",1,xFilial("SB1")+Acols[_z,nPosCodigo],"B1_DESC"))
		EndIf
	Next

Return (.T.)
