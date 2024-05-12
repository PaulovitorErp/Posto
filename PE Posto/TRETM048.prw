#INCLUDE "Protheus.ch"
#INCLUDE "Topconn.ch"
#INCLUDE "FWMVCDEF.CH"
#include "tbiconn.ch"

/*/{Protheus.doc} TRETM048
Ponto de Entrada do Cadastro de amostra de combust�vel - CRC
@author Totvs TBC
@since 27/05/2014
@version 1.0
@return Nulo

@type function
/*/

User Function TRETM048()

Local aParam 	:= PARAMIXB
Local xRet 		:= .T.
Local oObj		:= aParam[1]
Local cIdPonto 	:= aParam[2]
//Local cIdModel	:= IIf( oObj<> NIL, oObj:GetId(), aParam[3] )
//Local cClasse 	:= IIf( oObj<> NIL, oObj:ClassName(), '' ) 
//Local oModelZE5	:= oObj:GetModel('ZE5MASTER')
//Local oView		:= FWViewActive() 
//Local lAprova	:= .F.  
//Local aRateio	:= {}  

// ponto de entrada na abertura do Browse
if cIdPonto ==  "MODELVLDACTIVE"
	
	if oObj:GetOperation() == 4 .OR. oObj:GetOperation() == 5 // altera��o ou exclus�o	    
	   
		if !Empty(ZE5->ZE5_CRC) // pode excluir apenas se n�o gerou nota
			Help(,,'Help',,"N�o � poss�vel alterar/excluir uma amostra que j� tenha CRC!",1,0)
			xRet := .F. 
		endif  
	
	endif

endif 

Return (xRet)