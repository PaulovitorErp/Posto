#include 'protheus.ch'
#include 'parmtype.ch'

/*/{Protheus.doc} LJ1144Im
Permite o filtro dos dados importados pela rotina de importação dos dados da carga da Venda Assistida Off-Line.

@author Pablo Cavalcante
@since 05/02/2019
@version 1.0
@return ${return}, ${return_description}

@type function
/*/
User Function LJ1144Im()

  	Local aParam := aClone(ParamIxb)
    Local lSkip  := .F. //Se pula (.T.) ou não (.F.) a importação do registro.
	Local aArea	 := GetArea()

	///////////////////////////////////////////////////////////////////////////////////////////
	//             FUNCAO DO PACOTE POSTO INTELIGENTE - FAVOR NAO COMENTAR                  //
	/////////////////////////////////////////////////////////////////////////////////////////
	If ExistBlock("TPDVP026")
        lSkip := ExecBlock("TPDVP026",.F.,.F.,aParam)
	EndIf

	RestArea(aArea)

Return lSkip
