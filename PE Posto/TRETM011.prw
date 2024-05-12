#INCLUDE 'PROTHEUS.CH'
#INCLUDE "topconn.ch"
#INCLUDE "TbiConn.ch"

/*/{Protheus.doc} TRETM011
Ponto de Entrada da Rotina de Cadastro de Concentradora (TRETA011)

@type function
@author Pablo
@since 13/05/2014
@version 1.0
/*/
User Function TRETM011()

	Local aParam 		:= PARAMIXB
	Local oObj			:= aParam[1]
	Local cIdPonto		:= aParam[2]
	//Local cIdModel		:= IIf( oObj<> NIL, oObj:GetId(), aParam[3] )
	//Local cClasse		:= IIf( oObj<> NIL, oObj:ClassName(), '' )
	//Local oModelMHX		:= oObj:GetModel( 'MHXMASTER' )
	Local cPulaLinha	:= chr(13)+chr(10)
	Local lRet 			:= .T.
	Local cMsg			:= ""

	If cIdPonto == "MODELVLDACTIVE" // abertura da tela

		if oObj:GetOperation() == 5 // se for exclusão verifico se algum bico está amarrado a esta concentradora

			MIC->(DbOrderNickName("MIC_001")) //MIC_FILIAL+MIC_XCONCE+MIC_LADO+MIC_NLOGIC
			if MIC->(DbSeek(xFilial("MIC") + MHX->MHX_CODCON ))

				cMsg := "Esta concentradora está vinculada a um bico." + cPulaLinha + " Exclua primeiramente o bico."
				Help(,,'Help',,cMsg,1,0)
				lRet := .F.

			endif

		endif
	
	EndIf

Return(lRet)
