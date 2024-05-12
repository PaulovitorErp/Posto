#include 'protheus.ch'
#include 'parmtype.ch'

/*/{Protheus.doc} FA070TIT
O ponto de entrada FA070TIT sera executado apos a confirmacao da baixa do contas a receber.

@author Totvs TBC
@since 25/10/2015
@version 1.0
@return ${return}, ${return_description}

@type function
/*/
User Function FA070TIT() 

    Local aArea := GetArea()
    Local lRet 	:= .T.
    Local aParx := aClone(PARAMIXB)

    ///////////////////////////////////////////////////////////////////////////////////////////
    //             FUNCAO DO PACOTE POSTO INTELIGENTE - FAVOR NAO COMENTAR                  //
    /////////////////////////////////////////////////////////////////////////////////////////
    If ExistBlock("TRETP020")
        lRet := ExecBlock("TRETP020",.F.,.F.,aParx)
    EndIf
        
    RestArea(aArea)

Return lRet
