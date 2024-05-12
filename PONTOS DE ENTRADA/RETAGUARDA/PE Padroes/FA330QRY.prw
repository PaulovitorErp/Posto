#Include "Protheus.ch"
#Include "RwMake.ch"


/*/{Protheus.doc} FA330QRY
O ponto de entrada FA330QRY está na função Fa330Tit() que possibilita criar e manipular a query.

@author Totvs TBC
@since 04/11/2016
@version 1.0
@return ${return}, ${return_description}

@type function
/*/
User Function FA330QRY() 

Local aArea  := getArea()
Local cQuery := ""
Local aParx  := aClone(PARAMIXB)

///////////////////////////////////////////////////////////////////////////////////////////
//             FUNCAO DO PACOTE POSTO INTELIGENTE - FAVOR NAO COMENTAR                  //
/////////////////////////////////////////////////////////////////////////////////////////
If ExistBlock("TRETP036")
	cQuery := ExecBlock("TRETP036",.F.,.F.,aParx)
EndIf
      
RestArea(aArea)

Return cQuery
