#INCLUDE "PROTHEUS.CH"
#INCLUDE "TBICONN.CH"
#INCLUDE "TOPCONN.CH"

//--------------------------------------------------------------
/*/{Protheus.doc} TPDVE010
Rotina de Cancelamento de Cupom Fiscal
- NF-e/NFC-e

@param xParam Parameter Description
@return xRet Return Description
@author Pablo Cavalcante - pablo.nunes@totvs.com.br
@since 29/08/2014
/*/
//--------------------------------------------------------------

//***********************************************************************
// Rotina que exclui os vale haver
//***********************************************************************
User Function TPDVE010(cL1_DOC,cL1_SERIE)
Local aArea		:= GetArea()
Local aAreaSE1  := SE1->(GetArea())
Local aFin040 	:= {}
Local lRet 		:= .T.
Local cE1_PREFIXO	:= cL1_SERIE //"VLH" //alterado por Rafael
Local cE1_NUM		:= cL1_DOC
Local cE1_NUMNOTA	:= cL1_DOC
Local cE1_SERIE		:= cL1_SERIE
Local cE1_PARCELA	:= SubStr("VLH",1,TamSX3("E1_PARCELA")[1]) // Alterado por rafael
Local cE1_TIPO		:= "NCC"

//conout(" *** TPDVE010 - INICIO *** ")

DbSelectArea("SE1")
SE1->(DbSetOrder(1)) //E1_FILIAL+E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO
//conout(" *** TPDVE010 - Procurando VLH com a chave: (E1_FILIAL+E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO) => "+xFilial("SE1")+cE1_PREFIXO+cE1_NUM+cE1_PARCELA+cE1_TIPO+" *** ")
If SE1->(DbSeek(xFilial("SE1")+cE1_PREFIXO+cE1_NUM+cE1_PARCELA+cE1_TIPO))
	While SE1->(!EOF()) .and. (xFilial("SE1")+cE1_PREFIXO+cE1_NUM+cE1_PARCELA+cE1_TIPO) == (SE1->(E1_FILIAL+E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO))
		If SE1->E1_NUMNOTA == cE1_NUMNOTA .and. SE1->E1_SERIE == cE1_SERIE
			//conout(" *** TPDVE010 - VLH encontrado: (E1_FILIAL+E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO) => "+SE1->(E1_FILIAL+E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO)+" *** ")
			/*�������������������������������������������������������������������������������*/
			//Assinatura de vari�vel que conter� os campos/valores do titulo a ser excluido	;
			/*�������������������������������������������������������������������������������*/
			aFin040 := {}

			AADD( aFin040, {"E1_FILIAL"  , SE1->E1_FILIAL , Nil})
			AADD( aFin040, {"E1_PREFIXO" , SE1->E1_PREFIXO, Nil})
			AADD( aFin040, {"E1_NUM"     , SE1->E1_NUM,     Nil})
			AADD( aFin040, {"E1_PARCELA" , SE1->E1_PARCELA, Nil})
			AADD( aFin040, {"E1_TIPO"    , SE1->E1_TIPO,    Nil})

			/*�������������������������������������������������������������������������������*/
			//Assinatura de vari�veis que controlar�o a exclus�o autom�tica do t�tulo		;
			/*�������������������������������������������������������������������������������*/
			lMsErroAuto := .F.
			lMsHelpAuto := .T.

			/*�������������������������������������������������������������������������������*/
			//Invocando rotina autom�tica para exclus�o do t�tulo							;
			/*�������������������������������������������������������������������������������*/
			//conout(" *** TPDVE010 - Invocando rotina autom�tica para exclus�o do t�tulo. *** ")
			MSExecAuto({|x,y| Fina040(x,y)}, aFin040, 5)

			/*�������������������������������������������������������������������������������*/
			//Quando houver erros, exib�-los em tela										;
			/*�������������������������������������������������������������������������������*/
			If lMsErroAuto
				cErroExec := MostraErro("\temp")
	 			//conout(" *** TPDVE010 - Erro na exclus�o. *** ")
				//conout(cErroExec)
				cErroExec := ""
				lRet := .F.
				exit
			Else
				//conout(" *** TPDVE010 - Exclus�o realizada com sucesso. *** ")
				//DbCommitAll()
			EndIf
		EndIf
		SE1->(dbskip())
	EndDo
EndIf

//conout(" *** TPDVE010 - FIM *** ")

RestArea( aAreaSE1 )
RestArea( aArea )

Return lRet