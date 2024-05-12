#INCLUDE 'PROTHEUS.CH'
#INCLUDE "topconn.ch"
#INCLUDE "TbiConn.ch"

/*/{Protheus.doc} TRETM051
Ponto de entrada do cadastro bomba x bicos x lacres

@type function
@author Pablo
@since 26/06/2014
@version 1.0
/*/
User Function TRETM051()

	Local aParam 		:= PARAMIXB
	Local oObj			:= aParam[1]
	Local cIdPonto		:= aParam[2]
	Local oModelMHY	    := oObj:GetModel( 'MHYMASTER' )
	//Local oModelMIC	    := oObj:GetModel( 'MICDETAIL' )
	//Local oModelMIB	    := oObj:GetModel( 'MIBDETAIL' )
	Local lRet 			:= .T.

	If cIdPonto == 'MODELCOMMITNTTS'

		if oObj:GetOperation() == 3 .OR. oObj:GetOperation() == 4 // inclusão
			MIC->(DbSetOrder(2)) //MIC_FILIAL+MIC_CODBOM+MIC_CODBIC
			MIC->(DbSeek(xFilial("MIC") + oModelMHY:GetValue("MHY_CODBOM") ))
			while MIC->(!Eof()) .AND. MIC->MIC_FILIAL + MIC->MIC_CODBOM == xFilial("MIC") + oModelMHY:GetValue("MHY_CODBOM")
				RecLock('MIC',.F.)
                    MIC->MIC_XCONCE := oModelMHY:GetValue("MHY_CODCON")
                MIC->(MsUnlock())

				MIC->(DbSkip())
			enddo
		endif

	EndIf

Return(lRet)
